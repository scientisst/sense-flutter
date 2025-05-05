import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:provider/provider.dart";
import "package:scientisst_sense/scientisst_sense.dart";
import "package:sense/acquisition/chart_item.dart";
import "package:sense/settings/device.dart";
import "package:sense/ui/my_button.dart";
import "package:sense/ui/my_topbar.dart";
import "package:sense/ui/widget_dialog.dart";
import "package:sense/ui/widget_connecting.dart";
import "package:sense/ui/widget_connectFailed.dart";
import "package:sense/utils/device_settings.dart";
import "package:sense/utils/file_writer.dart";
import "package:slider_button/slider_button.dart";
import "package:permission_handler/permission_handler.dart";
import "package:disk_space/disk_space.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:wakelock_plus/wakelock_plus.dart";

const int REFRESH_RATE_STATIC = 1;

class Recording extends StatefulWidget {
  const Recording({super.key});

  @override
  _RecordingState createState() => _RecordingState();
}

class _RecordingState extends State<Recording> {
  bool _connecting = true;
  late Sense _sense;
  late DeviceSettings settings;
  bool starting = true;
  FileWriter? fileWriter;
  final List<List<int?>> _data = <List<int?>>[];
  final List<DateTime> _time = <DateTime>[];
  final int _windowInSeconds = 3;
  Timer? _refresh;
  late DateTime start;
  StreamSubscription? _stream;
  late List<bool> _activeChannels;
  Timer? _refreshSize;
  double _diskSpace = 0;
  double _fileSize = 0;
  bool _stopping = false;
  bool _isDisposed = false;

  Duration _duration = Duration.zero;
  late Duration _step;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _init();
  }

  Future<void> _init() async {
    if (starting) {
      settings = Provider.of<DeviceSettings>(context);
      assert(settings.address != null);

      _sense = Sense(settings.address!);
      _activeChannels = List.filled(settings.channels.length, true);

      settings.channels.forEach((_) {
        _data.add(<int?>[]);
      });

      // Check for permission and request if necessary
      if (settings.save && !(await Permission.storage.request().isGranted)) {
        Navigator.of(context).pop();
        Fluttertoast.showToast(msg: "Permission denied for storage");
        return;
      }

      if (await _connect()) {
        _startAcquisition();
      }

      starting = false;

      if (mounted) setState(() {});
    }
  }

  Future<bool> _connect() async {
    try {
      await _sense.connect();
      await Future.delayed(Duration(seconds: 1)); // Espera antes de qualquer comando
      await _sense.version();
    } on SenseException catch (e) {
      if (e.type != SenseErrorType.DEVICE_NOT_FOUND) rethrow;
    }
    _connecting = false;
    return _sense.connected;
  }

  Future<void> _retryConnect() async {
    setState(() {
      _connecting = true; // Indicate that the app is trying to reconnect
    });

    // Try reconnecting
    if (await _connect()) {
      Fluttertoast.showToast(msg: "Reconnected successfully.");
      _startAcquisition(); // Start the acquisition again after a successful connection
    } else {
      Fluttertoast.showToast(msg: "Reconnection failed. Please try again later.");
    }
  }

  Future<void> _startAcquisition() async {
    if (_sense.connected) {
      start = DateTime.now();

      // 100 Hz → 10.000 microseconds entre amostras
      //final int ds = (1000000~/ settings.samplingRate); // microseconds
      //_step = Duration(microseconds: ds);

      final int ds = (1000 ~/ settings.samplingRate); // miliseconds
      _step = Duration(milliseconds: ds);

      _time.clear();
      _data.forEach((list) => list.clear());

      final int bufferLength = settings.samplingRate * _windowInSeconds;

      _time.addAll(
        List.generate(
          bufferLength,
              (index) => start.subtract(Duration(microseconds: (bufferLength - index) * ds)),
        ),
      );

      _data.forEach(
            (list) => list.addAll(List.filled(bufferLength, 0)),
      );

      if (settings.save) {
        fileWriter = FileWriter(
          channels: settings.channels,
          fs: settings.samplingRate,
          start: start,
        );
        await fileWriter!.init();
      }

      await _sense.start(settings.samplingRate, settings.channels);

      final int numFrames = settings.samplingRate ~/ settings.refreshRate;

      _stream = settings.plot
          ? (settings.save ? _plotSaveStream(numFrames) : _plotStream(numFrames))
          : _doNotPlotStream();

      _refresh = Timer.periodic(
        Duration(milliseconds: 500), // Refresh da UI pode ser mais espaçado
            (Timer timer) {
          if (mounted) {
            _duration = DateTime.now().difference(start);
            setState(() {});
          } else {
            timer.cancel();
          }
        },
      );

      if (!settings.plot) {
        _refreshSize = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
          if (mounted) {
            _diskSpace = (await DiskSpace.getFreeDiskSpace) ?? 0;
          } else {
            timer.cancel();
          }
        });
      }
    }
  }

  StreamSubscription _plotSaveStream(int numFrames) => _sense
      .stream(numFrames: numFrames == 0 ? 1 : numFrames)
      .listen((List<Frame> frames) {
    _processPlotFrames(frames);
    fileWriter!.write(frames);
  });

  StreamSubscription _plotStream(int numFrames) => _sense
      .stream(numFrames: numFrames == 0 ? 1 : numFrames)
      .listen((List<Frame> frames) => _processPlotFrames(frames));

  void _processPlotFrames(List<Frame> frames) {
    for (final Frame frame in frames) {
      for (int i = 0; i < settings.channels.length; i++) {
        _data[i].add(frame.a[settings.channels[i] - 1]);
      }
      _time.add(_time.last.add(_step));
    }

    _data.forEach((List<int?> list) => list.removeRange(0, frames.length));
    _time.removeRange(0, frames.length);
  }

  StreamSubscription _doNotPlotStream() => _sense.stream().listen((List<Frame> frames) async {
    fileWriter!.write(frames);
  });

  Future<void> _stopAcquisition() async {
    _stopping = true;
    await _sense.stop();

    if (!_isDisposed && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _onWillPop() async {
    if (_sense.acquiring) {
      final bool? result = await showDialog(
        context: context,
        builder: (BuildContext context) => WidgetDialog(
          icon: const Icon(Icons.warning),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text("Do you want to exit? This might lead to loss of some data."),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      _stopping = true;
                      Navigator.of(context).pop(true);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                    child: const Text("Exit"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ) as bool?;
      return result ?? false;
    } else {
      return true;
    }
  }

  @override
  Future<void> dispose() async {
    if (!starting) {
      _isDisposed = true;
      _stopping = true;
      _refresh?.cancel();
      _refreshSize?.cancel();
      _stopAcquisition();
      _sense.disconnect();
      _stream?.cancel();
      fileWriter?.close();
    }
    await WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: settings.plot ? _buildPlotsScaffold() : _buildScaffold(),
      ),
    );
  }

  Widget _buildWithTopBar({required Widget topChild, required Widget child}) => Stack(
    children: <Widget>[
      Padding(padding: const EdgeInsets.only(top: 60), child: child),
      SizedBox(
        height: 100,
        child: Align(
          alignment: Alignment.topCenter,
          child: MyTopBar(
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.close_rounded),
                iconSize: 28,
                onPressed: () async {
                  if (await _onWillPop()) Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 12),
            ],
            child: topChild,
          ),
        ),
      ),
    ],
  );

  Scaffold _buildPlotsScaffold() => Scaffold(
    body: _buildWithTopBar(
      topChild: _sense.acquiring
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SpinKitPulse(color: Color(0xFFFFFFFF), size: 20),
          const SizedBox(width: 16),
          Text(_duration.toString().split(".").first.padLeft(8, "0")),
        ],
      )
          : const Text("Acquisition"),
      child: Builder(
        builder: (BuildContext context) {
          if (_connecting) {
            return const Connecting();
          } else {
            if (!_sense.connected) {
              return FailedConnect(_retryConnect); // Passing the retryConnect function here
            } else {
              return Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 10),
                      itemCount: settings.channels.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ChartItem(
                          _time,
                          _data[index],
                          active: _activeChannels[index],
                          onActivePressed: () {
                            setState(() {
                              _activeChannels[index] = !_activeChannels[index];
                            });
                          },
                          label: CHANNELS[settings.channels[index] - 1],
                        );
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) => SliderButton(
                        width: constraints.maxWidth,
                        buttonColor: Theme.of(context).colorScheme.primary,
                        dismissible: false,
                        backgroundColor: Colors.grey[200]!,
                        action: _stopAcquisition,
                        label: const Text(
                          "Slide to stop Acquisition",
                          style: TextStyle(
                            color: Color(0xff4a4a4a),
                            fontWeight: FontWeight.w500,
                            fontSize: 17,
                          ),
                        ),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }
          }
        },
      ),
    ),
  );

  Scaffold _buildScaffold() => Scaffold(
    body: _buildWithTopBar(
      topChild: _sense.acquiring
          ? const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SpinKitPulse(color: Color(0xFFFFFFFF), size: 20),
          SizedBox(width: 16),
          Text("Recording"),
        ],
      )
          : const Text("Acquisition"),
      child: Builder(
        builder: (BuildContext context) {
          if (_connecting) {
            return const Connecting();
          } else {
            if (!_sense.connected) {
              return FailedConnect(() async {
                await _retryConnect();
              });
            } else {
              return Column(
                children: <Widget>[
                  const SizedBox(height: 32),
                  if (_stopping) ...[
                    const Spacer(),
                    const Text("Stopping... Please wait."),
                    const Spacer(),
                  ],
                  const SizedBox(height: 32),
                ],
              );
            }
          }
        },
      ),
    ),
  );
}
