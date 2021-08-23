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

    final name = await SharedPref.read("name") as String?;
    final channels = List<int>.from(
        await SharedPref.read("channels") as List? ?? [1, 2, 3, 4, 5, 6, 7, 8]);
    final address = await SharedPref.read("address") as String?;
    final samplingRate = await SharedPref.read("samplingRate") as int?;
    final save = await SharedPref.read("save") as bool? ?? true;

    settings.name = name;
    settings.channels = channels;
    settings.save = save;
    if (samplingRate != null) settings.samplingRate = samplingRate;
    if (address != null) settings.address = address;

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
