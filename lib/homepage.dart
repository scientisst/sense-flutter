import 'package:flutter/material.dart';
import 'package:sense/acquisition/acquisitions.dart';
import 'package:sense/settings/settings.dart';
import 'package:sense/utils/device_settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final _items = [
    const BottomNavigationBarItem(
      label: "Acquisitions",
      icon: Icon(
        Icons.graphic_eq,
      ),
    ),
    const BottomNavigationBarItem(
      label: "Settings",
      icon: Icon(
        Icons.settings,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: const [Acquisitions(), Settings()],
              ),
            ),
            BottomNavigationBar(
              onTap: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              currentIndex: _currentIndex,
              items: _items,
            ),
          ],
        ),
      ),
    );
  }
}
