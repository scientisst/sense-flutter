import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sense/settings/bluetooth_search.dart';
import 'package:sense/settings/device.dart';
import 'package:sense/utils/device_settings.dart';
import 'package:sense/utils/shared_pref.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _loadingSettings = Completer<DeviceSettings>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadingSettings.isCompleted) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final settings = Provider.of<DeviceSettings>(context, listen: false);

    await settings.loadSettings();

    _loadingSettings.complete(settings);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadingSettings.future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) {
          return Consumer<DeviceSettings>(
            builder: (context, settings, child) {
              if (settings.address == null) {
                return const BluetoothSearch();
              } else {
                return const Device();
              }
            },
          );
        } else {
          return Container();
        }
      },
    );
  }
}
