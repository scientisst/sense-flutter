import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:scientisst_sense/scientisst_sense.dart';
import 'package:sense/acquisition/chart.dart';
import 'package:sense/acquisition/chart_item.dart';
import 'package:sense/settings/device.dart';
import 'package:sense/ui/my_button.dart';
import 'package:sense/ui/my_topbar.dart';
import 'package:sense/ui/widget_dialog.dart';
import 'package:sense/utils/device_settings.dart';
import 'package:sense/utils/file_writer.dart';
import 'package:slider_button/slider_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:disk_space/disk_space.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wakelock/wakelock.dart';

const REFRESH_RATE_STATIC = 1;

class Recording extends StatefulWidget {
  const Recording({Key? key}) : super(key: key);

  @override
  _RecordingState createState() => _RecordingState();
}

class _RecordingState extends State<Recording> {
  bool _connecting = true;
  late Sense _sense;
  late DeviceSettings settings;
  bool starting = true;
  FileWriter? fileWriter;
  final List<List<int?>> _data = [];
  final List<DateTime> _time = [];
  int _windowInSeconds = 3;
  Timer? _refresh;
  late DateTime start;
  StreamSubscription? _stream;
  late List<bool> _activeChannels;
  Timer? _refreshSize;
  double _diskSpace = 0;
  double _fileSize = 0;
  bool _stopping = false;

  Duration _duration = Duration.zero;

  late Duration _step;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _init();
  }

  Future<void> _init() async {
    if (starting) {
      settings = Provider.of<DeviceSettings>(context, listen: true);
      assert(settings.address != null);

      _sense = Sense(settings.address!);

      _activeChannels = List.filled(settings.channels.length, true);
      // add empty list to store data of each channel
      settings.channels.forEach((_) {
        _data.add(<int?>[]);
      });

      if (settings.save && !(await Permission.storage.request().isGranted)) {
        Navigator.of(context).pop();
        // TODO: warn user about permissions
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
      await _sense.connect(onDisconnect: () {
        //TODO: handle disconnect during acquisition
        if (!_stopping) {
          Fluttertoast.showToast(
            msg: "Connection Lost",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
        }
        if (mounted) setState(() {});
      });
    } on SenseException catch (e) {
      if (e.type != SenseErrorType.DEVICE_NOT_FOUND) rethrow;
    }
    _connecting = false;
    return _sense.connected;
  }

  Future<void> _startAcquisition() async {
    if (_sense.connected) {
      start = DateTime.now();

      final ds = 1000000 ~/ settings.samplingRate;
      _step = Duration(microseconds: ds);

      _time.clear();
      _data.forEach((list) => list.clear());

      _time.addAll(
        List.generate(
          settings.samplingRate * _windowInSeconds,
          (index) => start.subtract(
            Duration(microseconds: index * ds),
          ),
        ).reversed,
      );
      _data.forEach(
        (list) => list.addAll(
          List.filled(
            settings.samplingRate * _windowInSeconds,
            0,
          ),
        ),
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

      final numFrames = settings.samplingRate ~/ settings.refreshRate;
      if (settings.plot) {
        if (settings.save) {
          _stream = _plotSaveStream(numFrames);
        } else {
          _stream = _plotStream(numFrames);
        }
      } else {
        _stream = _doNotPlotStream();
      }

      _refresh = Timer.periodic(
        Duration(
          microseconds: 1000000 ~/
              (settings.plot ? settings.refreshRate : REFRESH_RATE_STATIC),
        ),
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
        _refreshSize = Timer.periodic(
          const Duration(
            seconds: 1,
          ),
          (Timer timer) async {
            if (mounted) {
              _fileSize = ((await fileWriter?.fileSize()) ?? 0) / 1024;
              _diskSpace = (await DiskSpace.getFreeDiskSpace) ?? 0;
            } else {
              timer.cancel();
            }
          },
        );
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
    for (final frame in frames) {
      for (int i = 0; i < settings.channels.length; i++) {
        _data[i].add(frame.a[settings.channels[i] - 1]);
      }
      _time.add(_time.last.add(_step));
    }

    _data.forEach((list) => list.removeRange(0, frames.length));
    _time.removeRange(0, frames.length);
  }

  StreamSubscription _doNotPlotStream() =>
      _sense.stream().listen((List<Frame> frames) async {
        fileWriter!.write(frames);
      });

  Future<void> _stopAcquisition() async {
    _stopping = true;
    await _sense.stop();
    Navigator.of(context).pop();
  }

  Future<bool> _onWillPop() async {
    if (_sense.acquiring) {
      final result = await showDialog(
        context: context,
        builder: (context) => WidgetDialog(
          icon: const Icon(Icons.warning),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  "Do you want to exit? This might lead to loss of some data."),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      _stopping = true;
                      Navigator.of(context).pop(true);
                    },
                    style: TextButton.styleFrom(
                      primary: Colors.grey,
                    ),
                    child: const Text('Exit'),
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
      _stopping = true;
      _refresh?.cancel();
      _refreshSize?.cancel();
      _stopAcquisition();
      _sense.disconnect();
      _stream?.cancel();
      fileWriter?.close();
    }
    Wakelock.disable();
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

  Widget _buildWithTopBar({required Widget topChild, required Widget child}) =>
      Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: child,
          ),
          SizedBox(
            height: 100,
            child: Align(
              alignment: Alignment.topCenter,
              child: MyTopBar(
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
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
                  children: [
                    const SpinKitPulse(
                      color: Color(0xFFFFFFFF),
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _duration.toString().split('.').first.padLeft(8, "0"),
                    ),
                  ],
                )
              : const Text("Acquisition"),
          child: Builder(
            builder: (context) {
              if (_connecting) {
                return const Connecting();
              } else {
                if (!_sense.connected) {
                  return FailedConnect(_retryConnect);
                } else {
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 10),
                          itemCount: settings.channels.length,
                          itemBuilder: (context, index) {
                            return ChartItem(
                              _time,
                              _data[index],
                              active: _activeChannels[index],
                              onActivePressed: () {
                                setState(() {
                                  _activeChannels[index] =
                                      !_activeChannels[index];
                                });
                              },
                              label: CHANNELS[settings.channels[index] - 1],
                            );
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        constraints: const BoxConstraints(
                          maxWidth: 400,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) => SliderButton(
                            width: constraints.maxWidth,
                            buttonColor: Theme.of(context).accentColor,
                            dismissible: false,
                            backgroundColor: Colors.grey[200]!,
                            action: _stopAcquisition,
                            label: const Text(
                              "Slide to stop Acquisition",
                              style: TextStyle(
                                  color: Color(0xff4a4a4a),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17),
                            ),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
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
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SpinKitPulse(
                      color: Color(0xFFFFFFFF),
                      size: 20,
                    ),
                    SizedBox(width: 16),
                    Text(
                      "Recording",
                    ),
                  ],
                )
              : const Text("Acquisition"),
          child: Builder(
            builder: (context) {
              if (_connecting) {
                return const Connecting();
              } else {
                if (!_sense.connected) {
                  return FailedConnect(() async {
                    await _connect();
                    if (_sense.connected && !_sense.acquiring) {
                      _startAcquisition();
                    }
                  });
                } else {
                  return Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: Text(
                                _duration
                                    .toString()
                                    .split('.')
                                    .first
                                    .padLeft(8, "0"),
                                style: const TextStyle(
                                  fontSize: 28,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 32,
                            ),
                            Center(
                              child: Text(
                                "File Size: ${_fileSize.toStringAsFixed(1)} MB",
                              ),
                            ),
                            Center(
                              child: Text(
                                "Free Space: ${_diskSpace.toStringAsFixed(1)} MB",
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        constraints: const BoxConstraints(
                          maxWidth: 400,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) => SliderButton(
                            width: constraints.maxWidth,
                            buttonColor: Theme.of(context).accentColor,
                            dismissible: false,
                            backgroundColor: Colors.grey[200]!,
                            action: _stopAcquisition,
                            label: const Text(
                              "Slide to stop Acquisition",
                              style: TextStyle(
                                  color: Color(0xff4a4a4a),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17),
                            ),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
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

  Future<void> _retryConnect() async {
    await _connect();
    if (_sense.connected && !_sense.acquiring) {
      _startAcquisition();
    }
  }
}

class Connecting extends StatelessWidget {
  const Connecting({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitRipple(
        color: Theme.of(context).accentColor,
        size: 100,
      ),
    );
  }
}

class FailedConnect extends StatelessWidget {
  const FailedConnect(this.connect, {Key? key}) : super(key: key);
  final void Function() connect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(
                  maxWidth: 250,
                ),
                child: const Image(
                  image: AssetImage('assets/images/undraw_warning_cyit.png'),
                ),
              ),
              const Text(
                "Could not connect to the device.",
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        MyButton(onPressed: connect, text: "Retry"),
      ],
    );
  }
}
