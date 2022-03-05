import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter ChartAI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter ChartAI'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> datas = [0, 0];
  List<double> chartdatas = [];
  double sliderforbegin = 10.0;
  double sliderforscale = 20.0;
  RangeValues rangevalue = RangeValues(1.0, 20.0);
  bool refreshing = true;
  bool curved = false;
  bool dots = false;

  Future getHttp() async {
    try {
      var response = await Dio().get('http://188.166.98.87:1880/GetChartData');
      chartdatas.clear();
      datas = response.data["dataPoints"];
      datas.forEach((element) {
        setState(() {
          if (element["y"].runtimeType == int) {
            chartdatas.add(element["y"].toDouble());
          } else {
            chartdatas.add(element["y"]);
          }
        });
      });
    } catch (e) {
      print(e);
    }
  }

  Future autorefresh() async {
    int _counter = rangevalue.end.toInt();
    var time = const Duration(seconds: 1);
    Timer.periodic(
        time,
        (timer) => {
              if (refreshing) {timer.cancel()},
              if (_counter == chartdatas.length) {timer.cancel()},
              setState(() {
                _counter++;
                chartdatas.clear();
                int kezdo = 0;
                for (int i = kezdo; i < _counter; i++) {
                  setState(() {
                    if (datas[i]["y"].runtimeType == int) {
                      chartdatas.add(datas[i]["y"].toDouble());
                    } else {
                      chartdatas.add(datas[i]["y"]);
                    }
                  });
                }
              })
            });
    refreshing = !refreshing;
  }

  coloring(int i) {
    if (i < rangevalue.start || i > rangevalue.end) {
      return Colors.black;
    } else {
      return Colors.amber;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getHttp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Wrap(children: [
                Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                        onPressed: getHttp, child: const Text('Adatlekérés'))),
                Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                        onPressed: autorefresh,
                        child: refreshing
                            ? const Text('Folyamatos \n frissítés')
                            : const Text("Leállítás"))),
                Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            curved = !curved;
                          });
                        },
                        child: const Text('Ívelés'))),
                Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            dots = !dots;
                          });
                        },
                        child: const Text('Pontok'))),
              ])),
          Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: LineChart(LineChartData(lineBarsData: [
                    LineChartBarData(
                        isCurved: curved,
                        preventCurveOverShooting: true,
                        barWidth: 5,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(
                          show: dots,
                        ),
                        spots: [
                          for (int i =
                                  (refreshing ? rangevalue.start.toInt() : 0);
                              i <
                                  (refreshing
                                      ? rangevalue.end.toInt()
                                      : chartdatas.length);
                              i++)
                            chartdatas.isNotEmpty
                                ? FlSpot(i.toDouble(), chartdatas[i])
                                : FlSpot(0, 0),
                        ])
                  ])))),
          Column(
            children: [
              SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 70,
                  child: LineChart(LineChartData(
                      titlesData: FlTitlesData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                            preventCurveOverShooting: true,
                            barWidth: 5,
                            colors: [
                              for (int i = 0; i < chartdatas.length; i++)
                                refreshing ? coloring(i) : Colors.blue
                            ],
                            belowBarData: BarAreaData(show: false),
                            dotData: FlDotData(
                              show: false,
                            ),
                            spots: [
                              for (int i = 0; i < chartdatas.length; i++)
                                FlSpot(i.toDouble(), chartdatas[i]),
                            ])
                      ]))),
              Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: RangeSlider(
                      values: rangevalue,
                      labels: RangeLabels(rangevalue.start.round().toString(),
                          rangevalue.end.round().toString()),
                      divisions: (chartdatas.length - 1),
                      min: 1.0,
                      max: chartdatas.isEmpty
                          ? 100.0
                          : chartdatas.length.toDouble(),
                      onChanged: (value) {
                        setState(() {
                          rangevalue = value;
                        });
                      })),
              Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: Slider(
                      label: "Hossz: ${sliderforscale.round()}",
                      value: sliderforscale,
                      divisions: (chartdatas.length - 1),
                      min: 1.0,
                      max: chartdatas.isEmpty
                          ? 100.0
                          : chartdatas.length.toDouble(),
                      onChanged: (value) {
                        double distance = rangevalue.end - rangevalue.start;
                        if (value + distance < 100) {
                          setState(() {
                            sliderforscale = value;
                            rangevalue = RangeValues(value, value + distance);
                          });
                        }
                      })),
            ],
          )
        ],
      ),
    );
  }
}
