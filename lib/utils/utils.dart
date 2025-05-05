import "dart:io";

import "package:flutter/services.dart";
import "package:path_provider/path_provider.dart";
import "package:watcher/watcher.dart";

Stream<Iterable<FileSystemEntity>> watchFiles() async* {
  final Directory path = await getApplicationDocumentsDirectory();
  final Iterable<FileSystemEntity> files = path.listSync().where(
    (FileSystemEntity file) => file.path.endsWith(".csv"),
  );
  yield files;
  await for (final WatchEvent _ in DirectoryWatcher(path.path).events) {
    final Iterable<FileSystemEntity> files = path.listSync().where(
      (FileSystemEntity file) => file.path.endsWith(".csv"),
    );
    yield files;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
