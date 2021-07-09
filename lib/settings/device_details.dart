import 'package:flutter/material.dart';
import 'package:scientisst_sense/scientisst_sense.dart';

class DeviceDetails extends StatefulWidget {
  const DeviceDetails(this.sense, {Key? key}) : super(key: key);
  final Sense sense;

  @override
  _DeviceDetailsState createState() => _DeviceDetailsState();
}

class _DeviceDetailsState extends State<DeviceDetails> {
  String version = "   ";

  @override
  void initState() {
    super.initState();
    widget.sense.version().then(
      (version) {
        setState(() {
          this.version = version;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      children: [
        Center(
          child: Text(
            "ScientISST Version ${version.toLowerCase().replaceFirst("scientisst", "")}",
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        )
      ],
    );
  }
}
