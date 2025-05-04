import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  const MyButton({
    Key? key,
    this.text,
    this.activeWidget,
    this.inactiveWidget,
    required this.onPressed,
    this.color,
    this.active = true,
  }) : super(key: key);

  final String? text;
  final Widget? activeWidget;
  final Widget? inactiveWidget;
  final void Function() onPressed;
  final bool active;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text ?? "",
      style: TextStyle(
        fontSize: 22,
        color: active ? null : Colors.grey[500],
      ),
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 80),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            stops: <double>[0, 0.8],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[Colors.white, Color(0x00FFFFFF)],
          ),
        ),
        child: ElevatedButton(
          onPressed: active ? onPressed : null, // Disable if not active
          style: ElevatedButton.styleFrom(
            backgroundColor: active
                ? color ?? Theme.of(context).colorScheme.primary
                : Colors.grey[300], // Color change when inactive
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            alignment: Alignment.center,
            child: active
                ? (activeWidget ?? textWidget)
                : (inactiveWidget ?? textWidget),
          ),
        ),
      ),
    );
  }
}