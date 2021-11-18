import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:sense/utils/device_settings.dart';
import 'package:sense/utils/shared_pref.dart';

const FS = [
  1,
  10,
  50,
  100,
  500,
  1000,
  2000,
  3000,
  4000,
  5000,
  6000,
  7000,
  8000,
  9000,
  10000,
];

const REFRESH_RATE = [
  1,
  5,
  10,
  15,
  20,
  25,
  30,
];

const CHANNELS = ["AI1", "AI2", "AI3", "AI4", "AI5", "AI6", "AX1", "AX2"];

class Device extends StatefulWidget {
  const Device({Key? key}) : super(key: key);

  @override
  _DeviceState createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  int _fs = 4;
  int _refresh = 1;

  final _channels = [false, false, false, false, false, false, false, false];
  int duration = 0;
  late DeviceSettings settings;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    settings = Provider.of<DeviceSettings>(context);
    settings.channels.forEach((int channel) => _channels[channel - 1] = true);
    _fs = FS.indexOf(settings.samplingRate);
    _refresh = REFRESH_RATE.indexOf(settings.refreshRate);
  }

  Future<void> _forget() async {
    SharedPref.remove("address");
    SharedPref.remove("name");
    settings.address = null;
    settings.name = null;
  }

  Future<void> _updateChannels() async {
    final channels =
        List.generate(_channels.length, (index) => index + 1, growable: false)
            .where((int channel) => _channels[channel - 1])
            .toList();
    settings.channels = channels;
    await SharedPref.write("channels", settings.channels);
  }

  Future<void> _setPlotState(bool value) async {
    setState(() {
      settings.plot = value;
    });
    await SharedPref.write("plot", value);
  }

  Future<void> _setSaveState(bool value) async {
    setState(() {
      settings.save = value;
    });
    await SharedPref.write("save", value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeHolder = ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        primary: theme.disabledColor,
      ),
      child: const Text("-"),
    );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 8,
            right: 8,
            bottom: 20,
          ),
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (settings.name != null)
                        Text(
                          settings.name!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        settings.address!,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: IconButton(
                    onPressed: () {
                      _forget();
                    },
                    icon: const Icon(
                      Icons.highlight_remove,
                    ),
                    iconSize: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text("Plot signals"),
              subtitle: const Text("Might affect performance"),
              value: settings.plot,
              onChanged: (value) async {
                if (!value && !settings.save) {
                  Fluttertoast.showToast(
                    msg: "You must select one of the options.",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                  );

                  _setPlotState(false);
                  _setSaveState(true);
                } else {
                  _setPlotState(value);
                }
              },
            ),
            if (settings.plot) _buildRefreshRateSlider(),
            SwitchListTile(
              title: const Text("Save file"),
              value: settings.save,
              onChanged: (value) async {
                if (!value && !settings.plot) {
                  Fluttertoast.showToast(
                    msg: "You must select one of the options.",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                  );

                  _setSaveState(false);
                  _setPlotState(true);
                } else {
                  _setSaveState(value);
                }
              },
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Sampling Frequency",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${FS[_fs]}",
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Hz",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Slider.adaptive(
              value: _fs.toDouble(),
              divisions: FS.length - 1,
              max: FS.length - 1,
              onChanged: (value) async {
                setState(() {
                  _fs = value.toInt();
                });
                settings.samplingRate = FS[_fs];
                await SharedPref.write("samplingRate", settings.samplingRate);
                _verifyRefreshRate();
              },
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Channels",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Front",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _getChannelButton(1),
                      _getChannelButton(3),
                      placeHolder,
                      placeHolder,
                    ],
                  ),
                  const Expanded(
                    child: Image(
                      image: AssetImage('assets/images/sense_front_on.png'),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _getChannelButton(7),
                      _getChannelButton(5),
                      placeHolder,
                      placeHolder,
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Back",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _getChannelButton(2),
                      _getChannelButton(4),
                      placeHolder,
                      placeHolder,
                    ],
                  ),
                  const Expanded(
                    child: Image(
                      image: AssetImage('assets/images/sense_back.png'),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _getChannelButton(8),
                      _getChannelButton(6),
                      placeHolder,
                      placeHolder,
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Biomedical engineering for everyone",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                FutureBuilder(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, AsyncSnapshot<PackageInfo> snap) {
                    if (snap.hasData) {
                      return Text(
                        "v${snap.data!.version}+${snap.data!.buildNumber}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      );
                    }
                    return Container();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshRateSlider() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Refresh Rate: ",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              Text(
                "${REFRESH_RATE[_refresh]}",
              ),
              const Text(
                " Hz",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Slider.adaptive(
            value: _refresh.toDouble(),
            divisions: REFRESH_RATE.length - 1,
            max: REFRESH_RATE.length - 1,
            onChanged: (value) async {
              if (FS[_fs] >= REFRESH_RATE[value.toInt()]) {
                setState(() {
                  _refresh = value.toInt();
                });
                settings.refreshRate = REFRESH_RATE[_refresh];
                await SharedPref.write("refreshRate", settings.refreshRate);
              }
            },
          ),
        ],
      );

  Widget _getChannelButton(
    int channel,
  ) {
    final index = channel - 1;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _channels[index] = !_channels[index];
        });
        _updateChannels();
      },
      style: ElevatedButton.styleFrom(
        primary: _channels[index]
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[300],
      ),
      child: Text(
        CHANNELS[index],
        style: TextStyle(
          color: _channels[index] ? Colors.white : Colors.grey[500],
        ),
      ),
    );
  }

  Future<void> _verifyRefreshRate() async {
    if (FS[_fs] < REFRESH_RATE[_refresh]) {
      final value =
          REFRESH_RATE.lastIndexWhere((int value) => value <= FS[_fs]);
      setState(() {
        _refresh = value;
      });
      settings.refreshRate = REFRESH_RATE[_refresh];
      await SharedPref.write("refreshRate", settings.refreshRate);
    }
  }
}
