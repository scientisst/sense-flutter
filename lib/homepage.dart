import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scientisst_sense/scientisst_sense.dart';
import 'package:sense/sense_plot.dart';
import 'package:sense/settings/settings.dart';
import 'package:sense/utils/address.dart';
import 'package:sense/utils/shared_pref.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Sense? sense;

  int _currentIndex = 1;
  late String? address;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  void _loadAddress() {
    SharedPref.read("address").then(
      (address) {
        this.address = address as String?;
        if (address != null) {
          Provider.of<Address>(context, listen: false).setAddress(address);
        }
      },
    ).whenComplete(() {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Container();
    final sense = context.watch<Sense?>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  SensePlot(
                    sense,
                    goToDevice: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                  ),
                  Settings(sense)
                ],
              ),
            ),
            SizedBox(
              height: 56,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      AnimatedContainer(
                        width: sense == null ? 0 : constraints.maxWidth / 2,
                        duration: sense == null
                            ? const Duration(milliseconds: 200)
                            : const Duration(milliseconds: 250),
                        child: sense != null
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    _currentIndex = 0;
                                  });
                                },
                                icon: Icon(
                                  Icons.graphic_eq,
                                  color: _currentIndex == 0
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).disabledColor,
                                ),
                              )
                            : null,
                      ),
                      Expanded(
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _currentIndex = 1;
                            });
                          },
                          icon: Icon(
                            Icons.settings,
                            color: _currentIndex == 1
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).disabledColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
