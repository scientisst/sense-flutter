import 'package:flutter/material.dart';
import 'package:scientisst_sense/scientisst_sense.dart';
import 'package:sense/settings/bluetooth_search.dart';
import 'package:sense/settings/device.dart';

class Settings extends StatelessWidget {
  const Settings(this.sense, {Key? key}) : super(key: key);

  final Sense? sense;

  @override
  Widget build(BuildContext context) {
    if (sense == null) {
      return const BluetoothSearch();
    } else {
      return Device(sense!);
    }
  }
}
