import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:sense/ui/my_button.dart';
import 'package:sense/ui/widget_dialog.dart';
import 'package:sense/utils/device_settings.dart';
import 'package:sense/utils/shared_pref.dart';
import 'package:bluetooth_enable/bluetooth_enable.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:sense/utils/utils.dart';

class BluetoothSearch extends StatefulWidget {
  const BluetoothSearch({Key? key}) : super(key: key);

  @override
  _BluetoothSearchState createState() => _BluetoothSearchState();
}

class _BluetoothSearchState extends State<BluetoothSearch> {
  final Map<String, BluetoothDiscoveryResult> _devices = {};
  final List<String> _devicesOrder = [];
  bool _searching = false;
  StreamSubscription? _subscription;
  late DeviceSettings settings;
  final _maskFormatter = MaskTextInputFormatter(
    mask: "##:##:##:##:##:##",
    filter: {
      "#": RegExp("[a-fA-F0-9]"),
    },
  );
  final _controller = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    settings = Provider.of<DeviceSettings>(context);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    FlutterBluetoothSerial.instance.cancelDiscovery();
    super.dispose();
  }

  Future<bool?> showBluetoothDialog() async {
    final result = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turn on Bluetooth'),
        content: SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
              Text('You need to turn on Bluetooth on your device.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              //await AppSettings.openBluetoothSettings();
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<bool> _checkBluetooth() async {
    if (!(await FlutterBluetoothSerial.instance.isEnabled ?? false)) {
      if (Platform.isAndroid) {
        // Request to turn on Bluetooth within an app
        BluetoothEnable.enableBluetooth.then((result) {
          return result == "true";
        });
      } else {
        return false;
      }
    }
    return true;
  }

  Future<bool> _checkLocation() async {
    final location = Location();
    if (!await location.serviceEnabled()) {
      if (!await location.requestService()) {
        return false;
      }
    }
    return true;
  }

  Future<void> _searchDevices() async {
    final bluetoothEnabled = await _checkBluetooth();
    final locationEnabled = await _checkLocation();
    if (!bluetoothEnabled || !locationEnabled) {
      debugPrint("Something went wrong");
      // TODO: show error dialog
      return;
    }

    setState(() {
      _searching = true;
    });

    _devices.clear();
    _devicesOrder.clear();
    _subscription = FlutterBluetoothSerial.instance.startDiscovery().listen(
      (result) {
        if (result.device.name?.toLowerCase().contains("scientisst") ?? false) {
          final address = result.device.address;
          if (_devices.isEmpty) {
            _devicesOrder.add(address);
          } else {
            for (int i = 0; i < _devices.length; i++) {
              if (!_devicesOrder.contains(address) &&
                  _devices[_devices.keys.elementAt(i)]!.rssi < result.rssi) {
                _devicesOrder.insert(i, address);
                break;
              }
            }
          }
          _devices[address] = result;
          if (mounted) {
            setState(() {});
          }
        }
      },
    );
    Future.delayed(const Duration(seconds: 5)).then((_) {
      _searching = false;
      _subscription?.cancel();
      FlutterBluetoothSerial.instance.cancelDiscovery();
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> setDevice(String address, [String? name]) async {
    final paired =
        (await FlutterBluetoothSerial.instance.getBondStateForAddress(address))
                .isBonded ||
            ((await FlutterBluetoothSerial.instance
                    .bondDeviceAtAddress(address, passkeyConfirm: true)
                    .timeout(
                      const Duration(seconds: 10),
                      onTimeout: () => false,
                    )) ??
                false);

    if (paired) {
      String? _name = name;
      if (_name == null) {
        final devices =
            (await FlutterBluetoothSerial.instance.getBondedDevices()).where(
          (device) => device.address == address,
        );
        if (devices.isNotEmpty) _name = devices.first.name;
      }
      settings.name = _name;
      settings.address = address;
      await SharedPref.write("address", address);
      await SharedPref.write("name", _name);
    } else {
      Fluttertoast.showToast(
        msg: "Failed to connect",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Devices found:",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                        ),
                        iconSize: 32,
                        color: Theme.of(context).primaryColor,
                        onPressed: _addDeviceDialog,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (_searching && _devices.isEmpty) {
                        return Center(
                          child: SpinKitRipple(
                            color: Theme.of(context).primaryColor,
                            size: 128,
                          ),
                        );
                      } else if (_devices.isEmpty) {
                        return const _EmptyDevices();
                      } else {
                        return _buildDevices();
                      }
                    },
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: MyButton(
                text: "Search",
                inactiveWidget: SpinKitThreeBounce(
                  color: Theme.of(context).primaryColor,
                  size: 16,
                ),
                onPressed: _searchDevices,
                active: !_searching,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDeviceDialog() async {
    final formKey = GlobalKey<FormState>();
    final String? address = await showDialog(
      context: context,
      builder: (context) => WidgetDialog(
        icon: const Icon(
          Icons.bluetooth_rounded,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Manually add a device:",
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            SizedBox(
              width: 140,
              child: Form(
                key: formKey,
                child: TextFormField(
                  autofocus: true,
                  inputFormatters: [
                    _maskFormatter,
                    UpperCaseTextFormatter(),
                  ],
                  style: const TextStyle(
                    fontFeatures: [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                  controller: _controller,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    hintText: "AA:BB:CC:DD:EE:FF",
                    hintStyle: Theme.of(context)
                        .inputDecorationTheme
                        .hintStyle
                        ?.copyWith(
                      fontFeatures: [
                        const FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  validator: (String? address) {
                    if (!_maskFormatter.isFill()) {
                      return "Invalid MAC address";
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context)
                        .pop(_maskFormatter.getMaskedText().toUpperCase());
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text("Connect"),
                    Icon(Icons.arrow_right_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (address != null) {
      setDevice(address);
    }
  }

  Widget _buildDevices() => ListView.separated(
        //padding: const EdgeInsets.only(top: 10),
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => const Divider(),
        itemCount: _devicesOrder.length,
        itemBuilder: (context, index) {
          final strength = ((100 + _devices[_devicesOrder[index]]!.rssi) / 50)
              .clamp(0.0, 1.0);
          final device = _devices[_devicesOrder[index]]!.device;
          bool connecting = false;
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(device.name ?? ""),
                subtitle: Text(device.address),
                trailing: connecting
                    ? SizedBox(
                        width: 32,
                        child: SpinKitDoubleBounce(
                          size: 24,
                          color: Theme.of(context).accentColor,
                        ),
                      )
                    : SignalIcon(strength),
                onTap: () async {
                  setState(() {
                    connecting = true;
                  });
                  await setDevice(device.address, device.name);
                  setState(() {
                    connecting = false;
                  });
                },
              );
            },
          );
        },
      );
}

class SignalIcon extends StatelessWidget {
  const SignalIcon(this.level);
  final double level;
  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(Colors.orange, Colors.green, level + 0.2);
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(7),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ClipPath(
                clipper: _TriangleClipPath(),
                child: Container(
                  height: 30 * level,
                  width: 30 * level,
                  color: color,
                ),
              ),
            ),
          ),
          const Icon(
            Icons.signal_cellular_null_rounded,
            color: Colors.black,
          ),
        ],
      ),
    );
  }
}

class _TriangleClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices({this.text = "", Key? key}) : super(key: key);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(
              maxWidth: 300,
            ),
            child: const Image(
                image: AssetImage(
                    'assets/images/undraw_Location_search_re_ttoj.png')),
          ),
          const SizedBox(height: 16),
          const Text(
            "No ScientISST Sense devices found.",
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
