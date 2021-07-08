import 'package:flutter/material.dart';
import 'package:sense/sense_plot.dart';
import 'package:sense/settings/settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _items = [
    const BottomNavigationBarItem(icon: Icon(Icons.graphic_eq), label: "Sense"),
    const BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Device"),
  ];
  final _children = [
    const SensePlot(),
    const Settings(),
  ];

  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _children,
              ),
            ),
            BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                items: _items),
          ],
        ),
      ),
    );
  }
}
