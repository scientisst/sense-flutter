import "dart:async";
import "dart:io";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/src/services/text_formatter.dart";
import "package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:location/location.dart";
import "package:provider/provider.dart";
import "package:sense/ui/my_button.dart";
import "package:sense/ui/widget_dialog.dart";
import "package:sense/utils/device_settings.dart";
import "package:sense/utils/shared_pref.dart";
import "package:bluetooth_enable/bluetooth_enable.dart";
import "package:mask_text_input_formatter/mask_text_input_formatter.dart";
import "package:sense/utils/utils.dart";

class BluetoothSearch extends StatefulWidget {
  const BluetoothSearch({super.key});

  @override
  _BluetoothSearchState createState() => _BluetoothSearchState();
}

class _BluetoothSearchState extends State<BluetoothSearch> {
  final Map<String, BluetoothDiscoveryResult> _devices =
      <String, BluetoothDiscoveryResult>{};
  final List<String> _devicesOrder = <String>[];
  bool _searching = false;
  StreamSubscription? _subscription;
  late DeviceSettings settings;
  final MaskTextInputFormatter _maskFormatter = MaskTextInputFormatter(
    mask: "##:##:##:##:##:##",
    filter: <String, RegExp>{"#": RegExp("[a-fA-F0-9]")},
  );
  final TextEditingController _controller = TextEditingController(text: "");

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
    final bool? result = await showDialog<bool?>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text("Turn on Bluetooth"),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("You need to turn on Bluetooth on your device."),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(true);
                  //await AppSettings.openBluetoothSettings();
                },
                child: const Text("Go to Settings"),
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
        BluetoothEnable.enableBluetooth.then((String result) {
          return result == "true";
        });
      } else {
        return false;
      }
    }
    return true;
  }

  Future<bool> _checkLocation() async {
    final Location location = Location();
    if (!await location.serviceEnabled()) {
      if (!await location.requestService()) {
        return false;
      }
    }
    return true;
  }

  Future<void> _searchDevices() async {
    final bool bluetoothEnabled = await _checkBluetooth();
    final bool locationEnabled = await _checkLocation();
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
    _subscription = FlutterBluetoothSerial.instance.startDiscovery().listen((
      BluetoothDiscoveryResult result,
    ) {
      if (result.device.name?.toLowerCase().contains("scientisst") ?? false) {
        final String address = result.device.address;
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
    });
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
    final bool paired =
        (await FlutterBluetoothSerial.instance.getBondStateForAddress(
          address,
        )).isBonded ||
        ((await FlutterBluetoothSerial.instance
                .bondDeviceAtAddress(address, passkeyConfirm: true)
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () => false,
                )) ??
            false);

    if (paired) {
      String? name0 = name;
      if (name0 == null) {
        final Iterable<BluetoothDevice> devices = (await FlutterBluetoothSerial
                .instance
                .getBondedDevices())
            .where((BluetoothDevice device) => device.address == address);
        if (devices.isNotEmpty) name0 = devices.first.name;
      }
      settings.name = name0;
      settings.address = address;
      await SharedPref.write("address", address);
      await SharedPref.write("name", name0);
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
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                  child: Row(
                    children: <Widget>[
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
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                        color: Theme.of(context).primaryColor,
                        onPressed: _addDeviceDialog,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (BuildContext context) {
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

  Future<void> _addDeviceDialog() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final String? address = await showDialog(
      context: context,
      builder:
          (BuildContext context) => WidgetDialog(
            icon: const Icon(Icons.bluetooth_rounded),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  "Manually add a device:",
                  style: TextStyle(color: Colors.black54),
                ),
                SizedBox(
                  width: 140,
                  child: Form(
                    key: formKey,
                    child: TextFormField(
                      autofocus: true,
                      inputFormatters: <TextInputFormatter>[
                        _maskFormatter,
                        UpperCaseTextFormatter(),
                      ],
                      style: const TextStyle(
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                      controller: _controller,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        hintText: "AA:BB:CC:DD:EE:FF",
                        hintStyle: Theme.of(
                          context,
                        ).inputDecorationTheme.hintStyle?.copyWith(
                          fontFeatures: <FontFeature>[
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
                        Navigator.of(
                          context,
                        ).pop(_maskFormatter.getMaskedText().toUpperCase());
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
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
    separatorBuilder: (BuildContext context, int index) => const Divider(),
    itemCount: _devicesOrder.length,
    itemBuilder: (BuildContext context, int index) {
      final double strength =
          ((100 + _devices[_devicesOrder[index]]!.rssi) / 50).clamp(0.0, 1.0);
      final BluetoothDevice device = _devices[_devicesOrder[index]]!.device;
      bool connecting = false;
      return StatefulBuilder(
        builder: (BuildContext context, setState) {
          return ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(device.name ?? ""),
            subtitle: Text(device.address),
            trailing:
                connecting
                    ? SizedBox(
                      width: 32,
                      child: SpinKitDoubleBounce(
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                    : SignalIcon(strength),
            onTap: () async {
              setState(() {
                connecting = true;
              });
              await setDevice(device.address, device.name);
              if (mounted) {
                setState(() {
                  connecting = false;
                });
              }
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
    final Color? color = Color.lerp(Colors.orange, Colors.green, level + 0.2);
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
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
          const Icon(Icons.signal_cellular_null_rounded, color: Colors.black),
        ],
      ),
    );
  }
}

class _TriangleClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
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
  const _EmptyDevices({super.key});
  final String text='';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 300),
            child: const Image(
              image: AssetImage(
                "assets/images/undraw_Location_search_re_ttoj.png",
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No ScientISST Sense devices found.",
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
