import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import 'package:scientisst_sense/scientisst_sense.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sense/settings/device_details.dart';
import 'package:sense/ui/my_button.dart';
import 'package:sense/utils/address.dart';
import 'package:sense/utils/shared_pref.dart';

class Device extends StatefulWidget {
  const Device(this.sense, {Key? key}) : super(key: key);
  final Sense sense;

  @override
  _DeviceState createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  bool _connecting = true;
  bool _disconnected = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    if (widget.sense.connected) widget.sense.disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    if (mounted) {
      setState(() {
        _connecting = true;
        _disconnected = false;
      });
    }

    // check if it's already paired or (if it's not paired) if pairing was successful
    final paired = (await FlutterBluetoothSerial.instance
                .getBondStateForAddress(widget.sense.address))
            .isBonded ||
        ((await FlutterBluetoothSerial.instance.bondDeviceAtAddress(
                widget.sense.address,
                passkeyConfirm: true)) ??
            false);

    if (paired) {
      await widget.sense.connect(onDisconnect: () {
        if (mounted) setState(() {});
      });
    }
    _connecting = false;
    if (mounted) setState(() {});
  }

  Future<void> _disconnect() async {
    await widget.sense.disconnect();
    _disconnected = true;
    if (mounted) setState(() {});
  }

  Future<void> _forget() async {
    await widget.sense.disconnect();
    SharedPref.remove("address");
    Provider.of<Address>(context, listen: false).setAddress(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: MaterialButton(
                onPressed: () {
                  _forget();
                },
                color: Colors.grey[400],
                shape: const CircleBorder(),
                elevation: 2,
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    child: ClipOval(
                      child: Opacity(
                        opacity: 0.1,
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 200,
                          ),
                          height: 20,
                          child: const Image(
                            image: AssetImage(
                              "assets/images/shadow.png",
                            ),
                            width: 200,
                            height: 20,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.only(bottom: 8),
                    constraints: const BoxConstraints(
                      maxWidth: 200,
                      minWidth: 100,
                      minHeight: 100,
                    ),
                    child: Transform.rotate(
                      angle: pi / 4,
                      child: Visibility(
                        visible: widget.sense.connected,
                        replacement: const Image(
                          image: AssetImage('assets/images/sense_off.png'),
                        ),
                        child: const Image(
                          image: AssetImage('assets/images/sense_on.png'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(widget.sense.address),
            ),
            Expanded(
              child: _connecting
                  ? const Connecting()
                  : (widget.sense.connected
                      ? DeviceDetails(widget.sense)
                      : (_disconnected
                          ? const Disconnected()
                          : const FailedConnect())),
            ),
            MyButton(
              active: !_connecting,
              color: widget.sense.connected
                  ? Colors.red[800]?.withAlpha(200)
                  : null,
              onPressed: widget.sense.connected ? _disconnect : _connect,
              text: widget.sense.connected
                  ? "Disconnect"
                  : (_disconnected ? "Connect" : "Try again"),
              inactiveWidget: SpinKitThreeBounce(
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Connecting extends StatelessWidget {
  const Connecting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitRipple(
        color: Theme.of(context).accentColor,
        size: 100,
      ),
    );
  }
}

class FailedConnect extends StatelessWidget {
  const FailedConnect({Key? key}) : super(key: key);

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
              image: AssetImage('assets/images/undraw_warning_cyit.png'),
            ),
          ),
          const Text(
            "Could not connect to the device.",
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class Disconnected extends StatelessWidget {
  const Disconnected({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(
              maxWidth: 300,
            ),
            child: const Image(
              image:
                  AssetImage('assets/images/undraw_signal_searching_bhpc.png'),
            ),
          ),
          const Text(
            "You are not connected.",
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
