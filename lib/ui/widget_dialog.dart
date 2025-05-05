import "package:flutter/material.dart";

class WidgetDialog extends StatelessWidget {
  const WidgetDialog({required this.child, this.icon, super.key});

  final Widget child;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Container(
            // Bottom rectangular box
            margin: const EdgeInsets.only(
              top: 40,
            ), // to push the box half way below circle
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(
              20,
              60,
              20,
              20,
            ), // spacing inside the box
            width: double.infinity,
            child: child,
          ),
          Positioned(
            top: 50,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close_rounded),
              color: Colors.grey,
              onPressed: () {
                Navigator.of(context).pop("Dismiss");
              },
            ),
          ),
          if (icon != null)
            CircleAvatar(
              // Top Circle with icon
              backgroundColor: Theme.of(context).primaryColor,
              maxRadius: 32.0,
              child: IconTheme(
                data: const IconThemeData(size: 32, color: Colors.white),
                child: icon!,
              ),
            )
          else
            Container(),
        ],
      ),
    );
  }
}
