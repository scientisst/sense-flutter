import 'package:flutter/material.dart';

class Address with ChangeNotifier {
  Address(this.address);

  String? address;

  String? getAddress() => address;

  void setAddress(String? address) {
    this.address = address;
    notifyListeners();
  }
}
