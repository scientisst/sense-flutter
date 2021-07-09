import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  const MyButton(
      {this.text,
      this.activeWidget,
      this.inactiveWidget,
      required this.onPressed,
      this.color,
      this.active = true,
      Key? key})
      : super(key: key);
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
      style: const TextStyle(
        fontSize: 22,
      ),
    );
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ElevatedButton(
        onPressed: active ? onPressed : null,
        style: ElevatedButton.styleFrom(
          primary: active
              ? color ?? Theme.of(context).primaryColor
              : Theme.of(context).disabledColor,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          alignment: Alignment.center,
          child: active
              ? (activeWidget ?? textWidget)
              : (inactiveWidget ?? textWidget),
        ),
      ),
    );
  }
}
