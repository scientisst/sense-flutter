import "package:flutter/material.dart";
import "package:sense/acquisition/chart.dart";

class ChartItem extends StatefulWidget {
  const ChartItem(
    this.time,
    this.data, {
    this.label = "A",
    this.onActivePressed,
    this.active = true,
    super.key,
  });

  final bool active;
  final void Function()? onActivePressed;
  final List<DateTime> time;
  final List<int?> data;
  final String label;

  @override
  _ChartItemState createState() => _ChartItemState();
}

class _ChartItemState extends State<ChartItem> {
  bool _autoScale = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              //horizontal: 8,
            ),
            child: Row(
              children: <Widget>[
                Chip(
                  backgroundColor: theme.colorScheme.primary,
                  label: Text(
                    widget.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(child: Container()),
                IconButton(
                  padding: EdgeInsets.zero,
                  color:
                      _autoScale
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                  onPressed: () {
                    setState(() {
                      _autoScale = !_autoScale;
                    });
                  },
                  icon: Icon(
                    _autoScale ? Icons.zoom_out : Icons.zoom_in,
                    color:
                        _autoScale
                            ? theme.colorScheme.primary
                            : theme.disabledColor,
                  ),
                ),
                IconButton(
                  color:
                      widget.active
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                  onPressed: widget.onActivePressed,
                  icon: const Icon(Icons.visibility),
                ),
              ],
            ),
          ),
          if (widget.active)
            SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 28, right: 30),
                child: Chart(widget.time, widget.data, zeroBound: !_autoScale),
              ),
            )
          else
            Container(),
        ],
      ),
    );
  }
}
