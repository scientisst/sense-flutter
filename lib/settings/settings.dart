import 'package:flutter/material.dart';
import 'package:sense/settings/bluetooth_search.dart';
import 'package:sense/settings/device.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Device("4C:11:AE:88:84:5A"),
    );
  }
}
