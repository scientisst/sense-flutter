import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:scientisst_sense/scientisst_sense.dart';
import 'package:sense/acquisition/chart.dart';
import 'package:sense/settings/device.dart';
import 'package:sense/ui/my_button.dart';
import 'package:sense/utils/device_settings.dart';
import 'package:sense/utils/file_writer.dart';
import 'package:slider_button/slider_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:disk_space/disk_space.dart';
import 'package:fluttertoast/fluttertoast.dart';

const REFRESH_RATE = 20;
const REFRESH_RATE_STATIC = 10;

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

  late Duration _step;

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
        if (_stopping) {
          Fluttertoast.showToast(
            msg: "Connection Lost",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            //textColor: Colors.white,
            //fontSize: 16.0,
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

      _time.addAll(
        List.generate(
          settings.samplingRate * _windowInSeconds,
          (index) => start.add(
            Duration(microseconds: index * ds),
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

      final numFrames = settings.samplingRate ~/ REFRESH_RATE;
      if (settings.save) {
        _stream = _saveStream(numFrames);
      } else {
        _stream = _doNotSaveStream(numFrames);
      }

      _refresh = Timer.periodic(
        Duration(
          milliseconds:
              1000 ~/ (settings.plot ? REFRESH_RATE : REFRESH_RATE_STATIC),
        ),
        (Timer timer) {
          if (mounted) {
            setState(() {});
          } else {
            timer.cancel();
          }
        },
      );

      _refreshSize = Timer.periodic(
        const Duration(
          seconds: 1,
        ),
        (Timer timer) async {
          if (mounted) {
            _fileSize = (await fileWriter?.fileSize()) ?? 0;
            _diskSpace = (await DiskSpace.getFreeDiskSpace) ?? 0;
          } else {
            timer.cancel();
          }
        },
      );
    }
  }

  StreamSubscription _doNotSaveStream(int numFrames) => _sense
          .stream(numFrames: numFrames == 0 ? 1 : numFrames)
          .listen((List<Frame> frames) {
        for (final frame in frames) {
          for (int i = 0; i < settings.channels.length; i++) {
            _data[i].add(frame.a[settings.channels[i] - 1]);
          }
          if (_data.first.length > _time.length) {
            _data.forEach((list) => list.removeAt(0));
            _time.removeAt(0);
            _time.add(_time.last.add(_step));
          }
        }
      });

  StreamSubscription _saveStream(int numFrames) =>
      _sense.stream().listen((List<Frame> frames) async {
        for (final frame in frames) {
          for (int i = 0; i < settings.channels.length; i++) {
            _data[i].add(frame.a[settings.channels[i] - 1]);
          }
          fileWriter!.write(frame);
          if (_data.first.length > _time.length) {
            _data.forEach((list) => list.removeAt(0));
            _time.removeAt(0);
            _time.add(_time.last.add(_step));
          }
        }
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
        builder: (context) => AlertDialog(
          title: const Text('Exit the acquisition'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    'This might lead to loss of some data. Do you want to proceed?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Exit'),
            ),
          ],
        ),
      ) as bool?;
      return result ?? false;
    } else {
      return true;
    }
  }

  @override
  void dispose() {
    if (!starting) {
      _refresh?.cancel();
      _refreshSize?.cancel();
      _sense.disconnect();
      _stream?.cancel();
      fileWriter?.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = _sense.acquiring ? DateTime.now().difference(start) : null;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: _sense.acquiring
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SpinKitPulse(
                      color: Color(0xFFFF0000),
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      settings.plot ? "${duration ?? ""}" : "Recording",
                    ),
                  ],
                )
              : const Text("Acquisition"),
        ),
        body: Builder(
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
                      child: settings.plot
                          ? ListView.builder(
                              itemCount: settings.channels.length,
                              itemBuilder: (context, index) {
                                final active = _activeChannels[index];
                                return Container(
                                  margin: const EdgeInsets.all(8),
                                  child: Stack(
                                    children: [
                                      if (active)
                                        SizedBox(
                                          height: 300,
                                          child: Card(
                                            elevation: 3,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 40,
                                                left: 40,
                                                bottom: 28,
                                                right: 30,
                                              ),
                                              child: Chart(
                                                _time,
                                                _data[index],
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(),
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: MaterialButton(
                                          color: active
                                              ? theme.accentColor
                                              : theme.disabledColor,
                                          shape: const CircleBorder(),
                                          elevation: 3,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          onPressed: () {
                                            setState(() {
                                              _activeChannels[index] =
                                                  !_activeChannels[index];
                                            });
                                          },
                                          child: Text(
                                            CHANNELS[
                                                settings.channels[index] - 1],
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(
                                  child: Text(
                                    "${duration ?? ""}",
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
                          buttonColor: theme.accentColor,
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
