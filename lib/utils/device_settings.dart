import 'package:flutter/material.dart';

class DeviceSettings with ChangeNotifier {
  DeviceSettings();

  String? _address;
  String? _name;
  List<int> _channels = [1, 2, 3, 4, 5, 6, 7, 8];
  int _samplingRate = 1000;
  bool _save = true;

  String? get address => _address;
  String? get name => _name;
  List<int> get channels => _channels;
  int get samplingRate => _samplingRate;
  bool get save => _save;

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
}
