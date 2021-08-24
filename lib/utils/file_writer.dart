import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:path_provider/path_provider.dart';
import 'package:scientisst_sense/scientisst_sense.dart';

const LABELS = ["AI1", "AI2", "AI3", "AI4", "AI5", "AI6", "AI7", "AI8"];
const RESOLUTIONS = [12, 12, 12, 12, 12, 12, 24, 24];

class FileWriter {
  late List<int> _channels;
  late List<String> _labels;
  late int _fs;

  late File file;
  late IOSink _sink;

  bool _writing = true;
  bool _headerWritten = false;

  final DateTime start;

  late Isolate isolate;

  ReceivePort receivePort = ReceivePort();

  FileWriter({
    required List<int> channels,
    List<String>? labels,
    required int fs,
    required this.start,
  })  : assert(channels.isNotEmpty),
        assert(labels == null ||
            (labels.isNotEmpty && labels.length == channels.length)),
        assert(fs > 0) {
    _channels = channels;
    _fs = fs;

    if (labels != null) {
      _labels = labels;
    } else {
      _labels = List<String>.generate(channels.length, (int i) => LABELS[i]);
    }
  }

  Future<void> spawnNewIsolate() async {
    try {
      isolate = await Isolate.spawn(sayHello, receivePort.sendPort);

      receivePort.listen((dynamic message) {
        print('New message from Isolate: $message');
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  static void myIsolate(SendPort isolateToMainStream) {
    final mainToIsolateStream = ReceivePort();
    isolateToMainStream.send(mainToIsolateStream.sendPort);

    late IOSink sink;
    mainToIsolateStream.listen((data) {
      if (data is Frame) {
        write(sink, data);
      } else if (data is IOSink) {
        sink = data;
      } else {}
    });

    isolateToMainStream.send('This is from myIsolate()');
  }

  static Future<void> _writeHeader(
      IOSink sink, Map<String, dynamic> metadata) async {
    //_headerWritten = true;
    //file = File(
    //"${(await getApplicationDocumentsDirectory()).path}/sense_${DateTime.now().millisecondsSinceEpoch}.csv");
    //_sink = file.openWrite(mode: FileMode.append);

    /*final timestamp = start.toIso8601String();

    final metadata = {
      "Timestamp": timestamp,
      "Sampling Rate (Hz)": _fs,
      "Channels": List<String>.from(
        _channels.map(
          (int i) => LABELS[i - 1],
        ),
      ),
      "Labels": _labels,
      "Resolution (bits)": [4, 1, 1, 1, 1] +
          List<int>.from(
            _channels.map(
              (int i) => RESOLUTIONS[i - 1],
            ),
          ),
    };*/

    sink.write("# ${jsonEncode(metadata)}\n");

    sink.write("\n");

    final labels = metadata["Labels"] as List<String>;

    sink.write("NSeq, I1, I2, O1, O2, ${labels.join(", ")}\n");
  }

  static Future<void> write(IOSink sink, Frame frame) async {
    //if (_writing) {
    //if (!_headerWritten) await _writeHeader();
    sink.write(
        "${frame.seq}, ${frame.digital.map((value) => value ? 1 : 0).join(", ")}, ${frame.a.where((value) => value != null).join(", ")}\n");
    //}
  }

  File close() {
    _writing = false;
    _sink.close();
    return file;
  }
}
