import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:watcher/watcher.dart';

Stream<Iterable<FileSystemEntity>> watchFiles() async* {
  final path = await getApplicationDocumentsDirectory();
  final files = path.listSync().where(
        (file) => file.path.endsWith(".csv"),
      );
  yield files;
  await for (final _ in DirectoryWatcher(path.path).events) {
    final files = path.listSync().where(
          (file) => file.path.endsWith(".csv"),
        );
    yield files;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
