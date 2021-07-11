import 'package:flutter/material.dart';
import 'package:sense/colors.dart';
import 'package:sense/ui/my_button.dart';

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

class Options extends StatefulWidget {
  const Options({Key? key}) : super(key: key);

  @override
  _OptionsState createState() => _OptionsState();
}

class _OptionsState extends State<Options> {
  int _fs = 5;
  final _channels = [false, false, false, false, false, false, false, false];
  bool _plot = true;
  bool _save = true;
  int duration = 0;

  void start() {
    final channels =
        List.generate(_channels.length, (index) => index + 1, growable: false)
            .where((int channel) => _channels[channel - 1])
            .toList();
    print(channels);
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
      },
      style: ElevatedButton.styleFrom(
        primary: _channels[index] ? MyColors.brown : Colors.grey[350],
      ),
      child: Text(CHANNELS[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _channels.any((value) => value);
    final theme = Theme.of(context);
    final placeHolder = ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        primary: theme.disabledColor,
      ),
      child: const Text("?"),
    );
    print(_channels);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Acquisition Options"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _plot = !_plot;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        primary: _plot ? null : theme.disabledColor,
                      ),
                      child: const Text("Plot"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _save = !_save;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        primary: _save ? null : theme.disabledColor,
                      ),
                      child: const Text("Save"),
                    ),
                  ],
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
                  onChanged: (value) {
                    setState(() {
                      _fs = value.toInt();
                    });
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
                          image: AssetImage('assets/images/sense_off.png'),
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
                          image: AssetImage('assets/images/sense_off.png'),
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
          MyButton(
            onPressed: start,
            text: "Start",
            active: ready,
          ),
        ],
      ),
    );
  }
}
