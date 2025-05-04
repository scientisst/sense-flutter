import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sense/acquisition/recording.dart';
import 'package:sense/ui/my_button.dart';
import 'package:sense/utils/device_settings.dart';
import 'package:sense/utils/utils.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart'; // Import necessário para XFile

class Acquisitions extends StatefulWidget {
  const Acquisitions({super.key});

  @override
  _AcquisitionsState createState() => _AcquisitionsState();
}

class _AcquisitionsState extends State<Acquisitions> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // To keep the state of the widget when it's moved off-screen
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: StreamBuilder<Iterable<FileSystemEntity>>(
                stream: watchFiles(), // Stream to listen for file changes
                builder: (BuildContext context, AsyncSnapshot<Iterable<FileSystemEntity>> snap) {
                  if (snap.connectionState != ConnectionState.active) {
                    return const Center(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(), // Loading indicator while fetching data
                      ),
                    );
                  } else if (!snap.hasData || snap.data!.isEmpty) {
                    return const Center(child: Text("No files found")); // If no files found
                  } else {
                    final items = snap.data!;

                    return ListView.separated(
                      padding: const EdgeInsets.only(top: 10),
                      physics: const BouncingScrollPhysics(),
                      separatorBuilder: (BuildContext context, _) => const Divider(),
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String path = items.elementAt(items.length - 1 - index).path;
                        final String filename = path.split("/").last;

                        return ListTile(
                          title: Text(
                            DateTime.fromMillisecondsSinceEpoch(
                              int.parse(filename.substring(6, filename.length - 4)), // Extract timestamp from filename
                            ).toString(),
                          ),
                          subtitle: Text(filename),
                          leading: const Icon(Icons.stacked_line_chart_rounded),
                          onTap: () => OpenFile.open(path), // Open the file when tapped
                          onLongPress: () => Share.shareXFiles([XFile(path)]) // Usa XFile corretamente
                        );
                      },
                    );
                  }
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Consumer<DeviceSettings>(
                builder: (BuildContext context, DeviceSettings settings, Widget? child) {
                  return MyButton(
                    text: "Start",
                    active: settings.address != null, // Button active only if address is not null
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => const Recording(),
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
