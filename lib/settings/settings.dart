import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sense/settings/bluetooth_search.dart';
import 'package:sense/settings/device.dart';
import 'package:sense/utils/device_settings.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<DeviceSettings>(
      builder: (context, settings, child) {
        if (settings.address == null) {
          return const BluetoothSearch();
        } else {
          return const Device();
        }
      },
    );
  }
}
