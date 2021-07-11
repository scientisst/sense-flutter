import 'package:flutter/material.dart';
import 'package:scientisst_sense/scientisst_sense.dart';
import 'package:sense/acquisition/options.dart';
import 'package:sense/ui/my_button.dart';

class Acquisition extends StatefulWidget {
  const Acquisition(this.sense, {required this.goToDevice, Key? key})
      : super(key: key);
  final Sense? sense;
  final void Function() goToDevice;

  @override
  _AcquisitionState createState() => _AcquisitionState();
}

class _AcquisitionState extends State<Acquisition> {
  @override
  Widget build(BuildContext context) {
    if (widget.sense?.connected ?? false) {
      return const Options();
    } else {
      return Awaiting(widget.goToDevice);
    }
  }
}

class Awaiting extends StatelessWidget {
  const Awaiting(this.onPressed, {Key? key}) : super(key: key);
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                  ),
                  child: const Image(
                    image:
                        AssetImage('assets/images/undraw_Loading_re_5axr.png'),
                  ),
                ),
                const Text(
                  "Awaiting connection...",
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        MyButton(
          text: 'Device settings',
          onPressed: onPressed,
        ),
      ],
    );
  }
}
