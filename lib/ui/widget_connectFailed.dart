import "package:flutter/material.dart";

class FailedConnect extends StatelessWidget {
  final VoidCallback connect;

  const FailedConnect(this.connect, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxWidth: 250),
                child: const Image(
                  image: AssetImage("assets/images/undraw_warning_cyit.png"),
                ),
              ),
              const Text(
                "Could not connect to the device.",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: connect,
              child: const Text("Retry"),
            ),
          ),
        ),
      ],
    );
  }
}
