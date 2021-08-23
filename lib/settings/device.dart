import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sense/colors.dart';
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

const CHANNELS = ["AI1", "AI2", "AI3", "AI4", "AI5", "AI6", "AX1", "AX2"];

class Device extends StatefulWidget {
  const Device({Key? key}) : super(key: key);

  @override
  _DeviceState createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  int _fs = 5;
  final _channels = [false, false, false, false, false, false, false, false];
  bool _plot = true;
  bool _save = true;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeHolder = ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        primary: theme.disabledColor,
        //tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text("-"),
    );
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
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
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            height: 48,
            width: 48,
            child: IconButton(
              onPressed: () {
                _forget();
              },
              icon: const Icon(
                Icons.close,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 8,
            right: 8,
            bottom: 80,
          ),
          children: [
            SwitchListTile(
              title: const Text("Plot signals"),
              subtitle: const Text("Might affect performance"),
              value: _plot,
              onChanged: (value) {
                setState(() {
                  _plot = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text("Save file"),
              value: settings.save,
              onChanged: (value) async {
                setState(() {
                  settings.save = value;
                });
                await SharedPref.write("save", value);
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
          ],
        ),
      ),
    );
  }

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
        primary: _channels[index] ? MyColors.brown : Colors.grey[300],
      ),
      child: Text(
        CHANNELS[index],
        style: TextStyle(
          color: _channels[index] ? Colors.white : Colors.grey[500],
        ),
      ),
    );
  }
}
