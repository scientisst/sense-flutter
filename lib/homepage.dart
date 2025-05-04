import "dart:async";

import "package:flutter/material.dart";
import "package:permission_handler/permission_handler.dart";
import "package:provider/provider.dart";
import "package:sense/acquisition/acquisitions.dart";
import "package:sense/settings/settings.dart";
import "package:sense/ui/my_topbar.dart";
import "package:sense/utils/device_settings.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final List<Tab> _tabs = const <Tab>[
    Tab(
      icon: Icon(Icons.graphic_eq, size: 28),
    ),
    Tab(
      icon: Icon(Icons.settings, size: 28),
    ),
  ];
  late TabController _controller;

  final List<StatefulWidget> _children = const <StatefulWidget>[
    Acquisitions(),
    Settings(),
  ];

  final Completer<DeviceSettings> _loadingSettings = Completer<DeviceSettings>();

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
    _requestPermissions(); // Request permissions when the widget is initialized
  }

  Future<void> _requestPermissions() async {
    try {
      // Request multiple permissions at once, and handle each one separately
      final permissionResults = await Future.wait([
        Permission.bluetoothScan.request(),
        Permission.bluetoothConnect.request(),
        Permission.location.request(),
        Permission.bluetooth.request(),
        Permission.manageExternalStorage.request(),
        Permission.storage.request(),
        Permission.mediaLibrary.request(),
        Permission.photos.request(),
        Permission.videos.request(),
        Permission.audio.request()
      ]);

      // Optionally handle permission results here (if needed)
      for (var result in permissionResults) {
        if (result.isDenied || result.isPermanentlyDenied) {
          _showPermissionDeniedDialog();
        }
      }
    } catch (e) {
      debugPrint("Permission request failed: $e");
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Permission Denied'),
        content: Text('Some permissions are required for this app to function properly. Please enable them in the app settings.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();  // Opens app settings to enable permissions
            },
            child: Text('Go to Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadingSettings.isCompleted) {
      _loadSettings();
    }
  }

  // Loading the device settings from provider
  Future<void> _loadSettings() async {
    final DeviceSettings settings = Provider.of<DeviceSettings>(
      context,
      listen: false,
    );
    await settings.loadSettings();
    _loadingSettings.complete(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: <Widget>[
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
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.4),
                    width: 4,
                  ),
                ),
              ),
              child: TabBar(controller: _controller, tabs: _tabs),
            ),
          ],
        ),
      ),
    );
  }
}
