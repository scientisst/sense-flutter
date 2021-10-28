import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sense/acquisition/recording.dart';
import 'package:sense/ui/my_button.dart';
import 'package:sense/utils/device_settings.dart';
import 'package:sense/utils/utils.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class Acquisitions extends StatefulWidget {
  const Acquisitions({Key? key}) : super(key: key);

  @override
  _AcquisitionsState createState() => _AcquisitionsState();
}

class _AcquisitionsState extends State<Acquisitions>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: StreamBuilder(
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
                      padding: const EdgeInsets.only(top: 10),
                      physics: const BouncingScrollPhysics(),
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
                          onLongPress: () => Share.shareFiles([path]),
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
