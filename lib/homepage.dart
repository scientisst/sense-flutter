import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sense/acquisition/acquisitions.dart';
import 'package:sense/settings/settings.dart';
import 'package:sense/ui/my_topbar.dart';
import 'package:sense/utils/device_settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _tabs = const [
    Tab(
      //text: "Acquisitions",
      icon: Icon(
        Icons.graphic_eq,
        size: 28,
      ),
    ),
    Tab(
      //text: "Settings",
      icon: Icon(
        Icons.settings,
        size: 28,
      ),
    ),
  ];
  late TabController _controller;

  final _children = const [
    Acquisitions(),
    Settings(),
  ];
  final _loadingSettings = Completer<DeviceSettings>();

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadingSettings.isCompleted) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final settings = Provider.of<DeviceSettings>(context, listen: false);
    await settings.loadSettings();
    _loadingSettings.complete(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: TabBarView(
                      physics: const BouncingScrollPhysics(),
                      controller: _controller,
                      children: _children,
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: MyTopBar(
                        child: Image.asset(
                          "assets/icon/launcher.png",
                          height: 70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.4),
                    width: 4,
                  ),
                ),
              ),
              child: TabBar(
                controller: _controller,
                tabs: _tabs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
