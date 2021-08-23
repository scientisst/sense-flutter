import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:scientisst_sense/scientisst_sense.dart';
import 'package:sense/acquisition/chart.dart';
import 'package:sense/ui/my_button.dart';
import 'package:sense/utils/device_settings.dart';
import 'package:sense/utils/file_writer.dart';
import 'package:slider_button/slider_button.dart';
import 'package:permission_handler/permission_handler.dart';

const REFRESH_RATE = 20;

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
  final List<int?> _data = [];
  final List<DateTime> _time = [];
  int _windowInSeconds = 1;
  Timer? _refresh;
  late DateTime start;
  StreamSubscription? _stream;

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

      if (settings.save && !(await Permission.storage.request().isGranted)) {
        Navigator.of(context).pop();
        // TODO: warn user about permissions
        return;
      }

      await _connect();

      starting = false;

      await _startAcquisition();
    }
  }

  Future<void> _connect() async {
    try {
      await _sense.connect(onDisconnect: () {
        //TODO: handle disconnect during acquisition
        if (mounted) setState(() {});
      });
      _connecting = false;
      if (mounted) setState(() {});
    } on SenseException catch (e) {
      if (e.type != SenseErrorType.DEVICE_NOT_FOUND) rethrow;
    }
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
      print(_time.length);

      if (settings.save) {
        fileWriter = FileWriter(
          channels: settings.channels,
          fs: settings.samplingRate,
          start: start,
        );
      }

      await _sense.start(settings.samplingRate, settings.channels);

      try {
        final numFrames = settings.samplingRate ~/ REFRESH_RATE;
        if (settings.save) {
          _stream = _saveStream(numFrames);
        } else {
          _stream = _doNotSaveStream(numFrames);
        }
      } on SenseErrorType catch (_) {
        debugPrint("catched error");
      }

      _refresh = Timer.periodic(
          const Duration(milliseconds: 1000 ~/ REFRESH_RATE), (Timer timer) {
        if (mounted) {
          setState(() {});
        } else {
          timer.cancel();
        }
      });
    }
  }

  StreamSubscription _doNotSaveStream(int numFrames) => _sense
          .stream(numFrames: numFrames == 0 ? 1 : numFrames)
          .listen((List<Frame> frames) {
        //debugPrint("${frames.first}");
        for (final frame in frames) {
          _data.add(frame.a.first);
          if (_data.length > _time.length) {
            _data.removeAt(0);
            _time.removeAt(0);
            _time.add(_time.last.add(_step));
          }
        }
      });

  StreamSubscription _saveStream(int numFrames) =>
      _sense.stream().listen((List<Frame> frames) async {
        //debugPrint("${frames.first}");
        for (final frame in frames) {
          _data.add(frame.a.first);
          await fileWriter!.write(frame);
          if (_data.length > _time.length) {
            _data.removeAt(0);
            _time.removeAt(0);
            _time.add(_time.last.add(_step));
          }
        }
      });

  Future<void> _stopAcquisition() async {
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
                    'This might lead to loss of data. Do you want to proceed?'),
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
      _sense.disconnect();
      _stream?.cancel();
      fileWriter?.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: _sense.acquiring
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SpinKitPulse(
                      color: Color(0xFFFF0000),
                      size: 20,
                      //duration: Duration(milliseconds: 250),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      DateTime.now().difference(start).toString(),
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
                return FailedConnect(_connect);
              } else {
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(8),
                            height: 300,
                            child: Stack(
                              children: [
                                Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 40,
                                      left: 40,
                                      bottom: 28,
                                      right: 30,
                                    ),
                                    child: Chart(_time, _data),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: MaterialButton(
                                    color: Colors.blue,
                                    shape: const CircleBorder(),
                                    elevation: 3,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onPressed: () {},
                                    child: const Text(
                                      "AI1",
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                          dismissible: false,
                          width: constraints.maxWidth,
                          buttonColor: theme.accentColor,
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