import 'dart:io';
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

  final start;

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

  Future<void> _writeHeader() async {
    _headerWritten = true;
    file = File(
        "${(await getApplicationDocumentsDirectory()).path}/sense_${DateTime.now().millisecondsSinceEpoch}.csv");
    _sink = file.openWrite(mode: FileMode.append);

    final timestamp = start.toIso8601String();

    _writeMetadata("Timestamp", timestamp);
    _writeMetadata("Sampling Rate (Hz)", _fs);
    _writeMetadata(
      "Channels",
      List<String>.from(
        _channels.map(
          (int i) => LABELS[i - 1],
        ),
      ),
    );
    _writeMetadata("Labels", _labels);
    _writeMetadata(
      "Resolution (bits)",
      List<int>.from(
        _channels.map(
          (int i) => RESOLUTIONS[i - 1],
        ),
      ),
    );

    _sink.write("\n");

    _sink.write("NSeq, I1, I2, O1, O2, ${_labels.join(", ")}\n");
  }

  void _writeMetadata(String title, dynamic value) {
    _sink.write("# $title = $value\n");
  }

  Future<void> write(Frame frame) async {
    if (_writing) {
      if (!_headerWritten) await _writeHeader();
      _sink.write(
          "${frame.seq}, ${frame.digital.join(", ")}, ${frame.a.where((value) => value != null).join(", ")}\n");
    }
  }

  File close() {
    _writing = false;
    _sink.close();
    return file;
  }
}
