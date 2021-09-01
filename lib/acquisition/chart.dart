import 'package:charts_common/common.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Chart extends StatelessWidget {
  final List<DateTime> x;
  final List<int?> y;

  const Chart(this.x, this.y);

  @override
  Widget build(BuildContext context) {
    final _series = [
      charts.Series<int, DateTime>(
        id: 'Values',
        //colorFn: (_, __) => charts.Color.fromHex(code: "#5cbdd7"),
        domainFn: (int index, _) => x[index],
        measureFn: (int index, _) => (index < y.length) ? y[index] : null,
        data: List.generate(x.length, (index) => index),
      ),
    ];
    return charts.TimeSeriesChart(
      _series,
      defaultRenderer: LineRendererConfig(includeArea: false, strokeWidthPx: 3),
      animate: false,
      primaryMeasureAxis: const charts.NumericAxisSpec(
        //tickProviderSpec: NumericEndPointsTickProviderSpec(),
        tickProviderSpec: StaticNumericTickProviderSpec(
          <TickSpec<num>>[
            TickSpec<num>(0),
            TickSpec<num>(512),
            TickSpec<num>(1024),
            TickSpec<num>(1536),
            TickSpec<num>(2048),
            TickSpec<num>(2560),
            TickSpec<num>(3072),
            TickSpec<num>(3584),
            TickSpec<num>(4096),
          ],
        ),
        //renderSpec: NoneRenderSpec(),
        showAxisLine: true,
      ),
      domainAxis: DateTimeAxisSpec(
        showAxisLine: true,
        tickProviderSpec: const DateTimeEndPointsTickProviderSpec(),
        tickFormatterSpec:
            BasicDateTimeTickFormatterSpec.fromDateFormat(DateFormat.Hms()),
        //renderSpec: NoneRenderSpec(),
      ),
      layoutConfig: charts.LayoutConfig(
          leftMarginSpec: MarginSpec.fixedPixel(0),
          rightMarginSpec: MarginSpec.fixedPixel(0),
          topMarginSpec: MarginSpec.fixedPixel(0),
          bottomMarginSpec: MarginSpec.fixedPixel(0)),
    );
  }
}

class SensorValue {
  final DateTime time;
  final double value;

  SensorValue(this.time, this.value);
}
