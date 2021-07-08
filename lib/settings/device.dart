import 'package:flutter/material.dart';
import 'package:scientisst_sense/scientisst_sense.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Device extends StatefulWidget {
  const Device(this.address, {Key? key}) : super(key: key);
  final String address;

  @override
  _DeviceState createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  late Sense sense;
  bool _connecting = true;

  @override
  void initState() {
    super.initState();
    sense = Sense(widget.address);
    connect();
  }

  void connect() {
    if (mounted) {
      setState(() {
        _connecting = true;
      });
    }
    sense.connect().whenComplete(() {
      setState(() {
        _connecting = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _connecting
            ? const Connecting()
            : (sense.connected ? DeviceDetails() : FailedConnect()),
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

class DeviceDetails extends StatelessWidget {
  const DeviceDetails({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text("Connected");
  }
}

class FailedConnect extends StatelessWidget {
  const FailedConnect({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(
          maxWidth: 300,
        ),
        child: Image.asset('assets/images/undraw_warning_cyit.png'),
      ),
    );
  }
}
