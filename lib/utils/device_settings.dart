import 'package:flutter/material.dart';
import 'package:sense/utils/shared_pref.dart';

class DeviceSettings with ChangeNotifier {
  DeviceSettings();

  String? _address;
  String? _name;
  List<int> _channels = [1, 2, 3, 4, 5, 6, 7, 8];
  int _samplingRate = 1000;
  bool _save = true;
  bool _plot = true;

  String? get address => _address;
  String? get name => _name;
  List<int> get channels => _channels;
  int get samplingRate => _samplingRate;
  bool get save => _save;
  bool get plot => _plot;

  set address(String? address) {
    _address = address;
    notifyListeners();
  }

  set name(String? name) {
    _name = name;
    notifyListeners();
  }

  set channels(List<int> channels) {
    _channels = channels;
    notifyListeners();
  }

  set samplingRate(int samplingRate) {
    _samplingRate = samplingRate;
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
        await SharedPref.read("channels") as List? ?? [1, 2, 3, 4, 5, 6, 7, 8]);
    final address = await SharedPref.read("address") as String?;
    final samplingRate = await SharedPref.read("samplingRate") as int?;
    final save = await SharedPref.read("save") as bool? ?? true;
    final plot = await SharedPref.read("plot") as bool? ?? true;

    this.name = name;
    this.channels = channels;
    this.save = save;
    this.plot = plot;
    if (samplingRate != null) this.samplingRate = samplingRate;
    if (address != null) this.address = address;
  }
}
