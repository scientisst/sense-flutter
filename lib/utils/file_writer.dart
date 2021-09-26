import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scientisst_sense/scientisst_sense.dart';

const LABELS = ["AI1", "AI2", "AI3", "AI4", "AI5", "AI6", "AI7", "AI8"];
const RESOLUTIONS = [12, 12, 12, 12, 12, 12, 24, 24];

class FileWriter {
  late List<int> _channels;
  late List<String> _labels;
  late int _fs;

  final DateTime start;

  late Isolate isolate;
  late ReceivePort receivePort;
  ReceivePort? isolateReceivePort;
  SendPort? sendPort;
  late String path;

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

  Future<void> init() async {
    path = await _path;

    final completer = Completer<SendPort>();
    receivePort = ReceivePort();

    receivePort.listen((data) {
      if (data is SendPort) {
        completer.complete(data);
      } else {
        debugPrint('[isolateToMainStream] $data');
      }
    });

    isolate = await Isolate.spawn(myIsolate, receivePort.sendPort);
    sendPort = await completer.future;
    sendPort!.send(path);
    sendPort!.send(metadata);
  }

  Future<String> get _path async =>
      "${(await getApplicationDocumentsDirectory()).path}/sense_${start.millisecondsSinceEpoch}.csv";

  Map<String, dynamic> get metadata {
    final timestamp = start.toIso8601String();

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
    };
    return metadata;
  }

  static void myIsolate(SendPort isolateToMainStream) {
    final mainToIsolateStream = ReceivePort();
    isolateToMainStream.send(mainToIsolateStream.sendPort);

    late File file;
    late IOSink sink;
    mainToIsolateStream.listen((data) {
      if (data is Frame) {
        _write(sink, data);
      } else if (data is String) {
        file = File(data);
        sink = file.openWrite(mode: FileMode.append);
      } else if (data is Map<String, dynamic>) {
        _writeHeader(sink, data);
      } else {
        sink.close();
        Future.delayed(Duration.zero).then((_) => mainToIsolateStream.close());
      }
    });
  }

  static Future<void> _writeHeader(
      IOSink sink, Map<String, dynamic> metadata) async {
    sink.write("# ${jsonEncode(metadata)}\n");

    sink.write("\n");

    final labels = metadata["Labels"] as List<String>;

    sink.write("NSeq, I1, I2, O1, O2, ${labels.join(", ")}\n");
  }

  static Future<void> _write(IOSink sink, Frame frame) async {
    //if (_writing) {
    //if (!_headerWritten) await _writeHeader();
    sink.write(
        "${frame.seq}, ${frame.digital.map((value) => value ? 1 : 0).join(", ")}, ${frame.a.where((value) => value != null).join(", ")}\n");
    //}
  }

  void write(Frame frame) {
    sendPort?.send(frame);
  }

  void close() {
    sendPort?.send(null);
    receivePort.close();
    isolate.kill();
    //return file;
  }
}
