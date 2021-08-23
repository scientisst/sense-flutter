import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sense/acquisition/recording.dart';
import 'package:sense/acquisition/review.dart';
import 'package:sense/ui/my_button.dart';
import 'package:sense/utils/device_settings.dart';
import 'package:sense/utils/utils.dart';
import 'package:open_file/open_file.dart';

class Acquisitions extends StatefulWidget {
  const Acquisitions({Key? key}) : super(key: key);

  @override
  _AcquisitionsState createState() => _AcquisitionsState();
}

class _AcquisitionsState extends State<Acquisitions> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Acquisitions",
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder(
              stream: watchFiles(),
              builder:
                  (context, AsyncSnapshot<Iterable<FileSystemEntity>> snap) {
                if (snap.connectionState != ConnectionState.active) {
                  return const Center(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else {
                  final items = snap.data!;
                  return ListView.separated(
                    separatorBuilder: (context, _) => const Divider(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final path =
                          items.elementAt(items.length - 1 - index).path;
                      final filename = path.split("/").last;
                      return ListTile(
                        title: Text(DateTime.fromMillisecondsSinceEpoch(
                          int.parse(
                            filename.substring(6, filename.length - 4),
                          ),
                        ).toString()),
                        subtitle: Text(filename),
                        leading: const Icon(Icons.stacked_line_chart_rounded),
                        onTap: () => OpenFile.open(path),
                        /*onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => Review(path),
                          ),
                        ),*/
                      );
                    },
                  );
                }
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Consumer<DeviceSettings>(
                builder: (context, settings, child) {
                  return MyButton(
                    text: "Start",
                    active: settings.address != null,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const Recording(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
