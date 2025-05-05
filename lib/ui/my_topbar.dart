import "package:flutter/material.dart";

class MyTopBar extends StatelessWidget implements PreferredSizeWidget {
  const MyTopBar({required this.child, this.actions, super.key});

  final Widget child;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(100.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: child,
      actions: actions,
      centerTitle: true,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipPath(
        clipper: MyClipper(),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: 30,
          ),
          color: Theme.of(context).primaryColor,
          height: double.infinity,
        ),
      ),
    );
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double height3 = size.height / 3;
    path.lineTo(0, height3);
    path.arcToPoint(
      Offset(height3, 2 * height3),
      clockwise: false,
      radius: Radius.circular(height3),
    );
    path.lineTo(size.width - height3, 2 * height3);
    path.arcToPoint(
      Offset(size.width, size.height),
      radius: Radius.circular(height3),
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
