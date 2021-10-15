import 'package:flutter/material.dart';
import 'package:sense/utils/shared_pref.dart';

class DeviceSettings with ChangeNotifier {
  DeviceSettings();

  String? _address;
  String? _name;
  List<int> _channels = [1, 2, 3, 4, 5, 6];
  int _samplingRate = 1000;
  int _refreshRate = 5;
  bool _save = true;
  bool _plot = true;

  String? get address => _address;
  String? get name => _name;
  List<int> get channels => _channels;
  int get samplingRate => _samplingRate;
  int get refreshRate => _refreshRate;
  bool get save => _save;
  bool get plot => _plot;

  set address(String? value) {
    _address = value;
    notifyListeners();
  }

  set name(String? value) {
    _name = value;
    notifyListeners();
  }

  set channels(List<int> value) {
    _channels = value;
    notifyListeners();
  }

  set samplingRate(int value) {
    _samplingRate = value;
    notifyListeners();
  }

  set refreshRate(int value) {
    _refreshRate = value;
    notifyListeners();
  }

  set save(bool save) {
    _save = save;
    notifyListeners();
  }

  set plot(bool plot) {
    _plot = plot;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    final name = await SharedPref.read("name") as String?;
    final channels = List<int>.from(
        await SharedPref.read("channels") as List? ?? [1, 2, 3, 4, 5, 6]);
    final address = await SharedPref.read("address") as String?;
    final samplingRate = await SharedPref.read("samplingRate") as int?;
    final refreshRate = await SharedPref.read("refreshRate") as int?;
    final save = await SharedPref.read("save") as bool? ?? true;
    final plot = await SharedPref.read("plot") as bool? ?? true;

    this.name = name;
    this.channels = channels;
    this.save = save;
    this.plot = plot;
    if (samplingRate != null) this.samplingRate = samplingRate;
    if (refreshRate != null) this.refreshRate = refreshRate;
    if (address != null) this.address = address;
  }
}
