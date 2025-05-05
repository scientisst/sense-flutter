import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:isolate";
import "package:flutter/material.dart";
import "package:path_provider/path_provider.dart";
import "package:scientisst_sense/scientisst_sense.dart";

const List<String> LABELS = <String>[
  "AI1", "AI2", "AI3", "AI4", "AI5", "AI6", "AI7", "AI8",
];
const List<int> RESOLUTIONS = <int>[12, 12, 12, 12, 12, 12, 24, 24];

class FileWriter {
  final DateTime start;
  late final List<int> _channels;
  late final List<String> _labels;
  late final int _fs;
  static int _totalFramesWritten = 0;

  late Isolate _isolate;
  late ReceivePort _receivePort;
  SendPort? _sendPort;
  String? path;

  FileWriter({
    required List<int> channels,
    List<String>? labels,
    required int fs,
    required this.start,
  }) {
    assert(channels.isNotEmpty);
    assert(fs > 0);

    _channels = channels;

    _labels = labels ??
        List<String>.generate(
          channels.length,
              (i) => LABELS[i],
          growable: false,
        );

    _fs = fs;
  }

  Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/sense_${start.millisecondsSinceEpoch}.csv";

    final file = File(filePath);

    if (!await file.exists()) {
      print("[INIT] Criando arquivo...");
      await file.create(recursive: true);
    } else {
      print("[INIT] Arquivo já existe, irá sobrescrever.");
      await file.writeAsString(""); // Limpa conteúdo se já existir
    }

    return filePath;
  }

  Future<void> init() async {
    path = await _filePath;
    print("[INIT] Path: $path");

    _receivePort = ReceivePort();

    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        print("[INIT] SendPort recebido!");

        // Enviar arquivo e metadata após configurar o SendPort
        _sendPort!.send(path);
        _sendPort!.send(metadata);
      } else {
        print("[MAIN] Mensagem da isolate: $message");
      }
    });

    _isolate = await Isolate.spawn(_isolateEntry, _receivePort.sendPort);
  }

  Map<String, dynamic> get metadata {
    return <String, Object>{
      "Timestamp": start.toIso8601String(),
      "Sampling Rate (Hz)": _fs,
      "Channels": List<String>.from(_channels.map((i) => LABELS[i - 1])),
      "Channels indexes": _channels,
      "Labels": _labels,
      "Resolution (bits)": <int>[4, 1, 1, 1, 1] +
          List<int>.from(_channels.map((i) => RESOLUTIONS[i - 1])),
    };
  }

  static void _isolateEntry(SendPort mainSendPort) {
    print("[ISOLATE] Iniciada");
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    IOSink? sink;
    List<int>? channels;
    DateTime? startTime;
    int? fs;

    receivePort.listen((data) async {
      print("[ISOLATE] Recebido: ${data.runtimeType}");

      if (data is String) {
        final file = File(data);
        sink = file.openWrite(mode: FileMode.append);
        print("[ISOLATE] Arquivo aberto: $data");
      } else if (data is Map<String, dynamic>) {
        channels = List<int>.from(data["Channels indexes"]);
        startTime = DateTime.parse(data["Timestamp"]);
        fs = data["Sampling Rate (Hz)"];
        await _writeHeader(sink!, data);
        print("[ISOLATE] Header escrito");
      } else if (data is List<Frame>) {
        if (sink != null && channels != null && startTime != null && fs != null) {
          await _writeData(sink!, data, channels!, startTime!, fs!);
          print("[ISOLATE] Dados escritos");
        } else {
          print("[ISOLATE] Erro: sink, channels, startTime ou fs não inicializados!");
        }
      } else if (data == null) {
        await sink?.flush();
        await sink?.close();
        receivePort.close();
        print("[ISOLATE] Fechando isolate...");
      }
    });
  }

  static Future<void> _writeHeader(IOSink sink, Map<String, dynamic> metadata) async {
    sink.writeln("# ${jsonEncode(metadata)}");
    sink.writeln();
    final labels = metadata["Labels"] as List<String>;
    sink.write("Time (ms), I1, I2, O1, O2, ${labels.join(", ")}\n");
  }

  // Method to write frames (with continuous timestamp)
  static Future<void> _writeData(IOSink sink, List<Frame> frames, List<int> channels, DateTime start, int fs) async {
    final buffer = StringBuffer();

    // Calculate the initial timestamp offset for the first frame of this batch
    final startTimestampMs = start.millisecondsSinceEpoch;

    // Iterate over each frame in the batch
    for (int i = 0; i < frames.length; i++) {
      final frame = frames[i];

      // Calculate the elapsed time for this frame (in ms) based on the total frames written so far
      final elapsedTimeMs = (_totalFramesWritten + i + 1) * (1000 ~/ fs);  // Use the total frame count to adjust timestamp

      // Calculate the timestamp as the start time + elapsed time
      final timestampMs = startTimestampMs + elapsedTimeMs;

      // Format digital data as a string (0 or 1)
      final digitalStr = frame.digital.map((v) => v ? 1 : 0).join(", ");

      // Format analog data for the given channels
      final analogStr = channels.map((ch) => frame.a[ch - 1]).join(", ");

      // Write the timestamp, digital, and analog data to the buffer in CSV format
      buffer.writeln("${timestampMs}, ${digitalStr}, ${analogStr}");
    }

    _totalFramesWritten += frames.length;

    // Write all the collected data to the file
    sink.write(buffer.toString());
  }

  void write(List<Frame> frames) {
    if (_sendPort == null) {
      print("[ERROR] SendPort não inicializado! Chame init() primeiro.");
      return;
    }
    _sendPort!.send(frames);
  }

  Future<void> close() async {
    _sendPort?.send(null);
    _receivePort.close();
    _isolate.kill(priority: Isolate.immediate);
    print("[CLOSE] Isolate encerrada");
  }
}
