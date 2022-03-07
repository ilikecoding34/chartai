import 'dart:async';
import 'dart:ui';
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
  List<FlSpot> bigchart = [];
  List<double> chartdate = [];
  double sliderforscale = 0.0;
  RangeValues rangevalue = const RangeValues(0.0, 100.0);
  TextEditingController inputfieldcontroll = TextEditingController(text: '1');
  TextEditingController inputfieldcontroll2 =
      TextEditingController(text: '10.0');
  bool refreshing = true;
  bool curved = false;
  bool dots = false;
  String answer = '';

  Future getHttp() async {
    try {
      var response = await Dio().get('http://188.166.98.87:1880/GetChartData');
      chartdatas.clear();
      chartdate.clear();
      var gotdatas = response.data["dataPoints"];
      datas = List.from(gotdatas.reversed);
      datas.forEach((element) {
        if (element["y"].runtimeType == int) {
          chartdatas.add(element["y"].toDouble());
        } else {
          chartdatas.add(element["y"]);
        }
        chartdate.add(element["T"].toDouble());
      });
      bigchart.clear();
      for (int i = rangevalue.start.toInt(); i < rangevalue.end.toInt(); i++) {
        bigchart.add(FlSpot(chartdate[i], chartdatas[i]));
      }
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  Future postHttp() async {
    String index = inputfieldcontroll.text;
    double number = double.parse(inputfieldcontroll2.text);
    //  Map<int, double> datas = {index: number};
    var response;
    Dio dio = Dio();
    //  dio.options.contentType = Headers.formUrlEncodedContentType;
    //dio.options.headers['content-Type'] = 'application/json';
    dio.options.contentType = Headers.textPlainContentType;
    dio.options.responseType = ResponseType.plain;
    try {
      response = await dio.post('http://188.166.98.87:1880/AddPattern',
          data: bigchart);

      answer = response.data.toString();
    } on DioError catch (e) {
      print(e.error);
    }

    setState(() {});
  }

  Future autorefresh() async {
    var time = const Duration(minutes: 1);
    Timer.periodic(
        time,
        (timer) => {
              if (refreshing) {timer.cancel()},
              getHttp()
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

  bottomline(double input) {
    String hour =
        DateTime.fromMillisecondsSinceEpoch((input).toInt()).hour.toString();

    return hour;
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
        title: Text(widget.title + " post answer: " + answer),
      ),
      body: ListView(
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Wrap(children: [
                Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                        onPressed: getHttp, child: const Text('Adatlekérés'))),
                Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                        onPressed: postHttp, child: const Text('Adatküldés'))),
                Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                        onPressed: () => setState(() {
                              autorefresh();
                            }),
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
                Container(
                    padding: const EdgeInsets.all(10),
                    width: 80,
                    child: TextField(
                      selectionHeightStyle: BoxHeightStyle.tight,
                      decoration: const InputDecoration(label: Text('index')),
                      controller: inputfieldcontroll,
                    )),
                Container(
                    padding: const EdgeInsets.all(10),
                    width: 80,
                    child: TextField(
                      selectionHeightStyle: BoxHeightStyle.tight,
                      decoration: const InputDecoration(label: Text('value')),
                      controller: inputfieldcontroll2,
                    )),
              ])),
          Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: LineChart(LineChartData(
                      titlesData: FlTitlesData(
                          topTitles: SideTitles(showTitles: false),
                          bottomTitles: SideTitles(
                            showTitles: true,
                            getTitles: (value) {
                              return bottomline(value);
                            },
                          )),
                      lineBarsData: [
                        LineChartBarData(
                            isCurved: curved,
                            preventCurveOverShooting: true,
                            barWidth: 5,
                            belowBarData: BarAreaData(show: false),
                            dotData: FlDotData(
                              show: dots,
                            ),
                            spots: bigchart)
                      ])))),
          Column(
            children: [
              SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 70,
                  child: LineChart(LineChartData(
                      titlesData: FlTitlesData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                            preventCurveOverShooting: true,
                            barWidth: 5,
                            colors: [
                              for (int i = 0; i < chartdatas.length; i++)
                                coloring(i)
                            ],
                            belowBarData: BarAreaData(show: false),
                            dotData: FlDotData(
                              show: false,
                            ),
                            spots: [
                              for (int i = 0; i < chartdatas.length; i++)
                                FlSpot(chartdate[i], chartdatas[i]),
                            ])
                      ]))),
              Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: RangeSlider(
                      values: rangevalue,
                      labels: RangeLabels(
                          rangevalue.start.round().toString() + "-tól",
                          rangevalue.end.round().toString() + "-ig"),
                      divisions:
                          chartdatas.isNotEmpty ? (chartdatas.length - 1) : 1,
                      min: 0.0,
                      max: chartdatas.isEmpty
                          ? 100.0
                          : chartdatas.length.toDouble(),
                      onChanged: (value) {
                        if (value.end - value.start > 99) {
                          setState(() {
                            bigchart.clear();
                            rangevalue = value;
                            for (int i = rangevalue.start.toInt();
                                i < rangevalue.end.toInt();
                                i++) {
                              bigchart.add(FlSpot(chartdate[i], chartdatas[i]));
                            }
                          });
                        }
                      })),
              Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Slider(
                      label: "Kezdőérték: ${sliderforscale.round()}",
                      value: sliderforscale,
                      divisions:
                          chartdatas.isNotEmpty ? (chartdatas.length - 1) : 1,
                      min: 0.0,
                      max: chartdatas.isEmpty
                          ? 100.0
                          : chartdatas.length.toDouble(),
                      onChanged: (value) {
                        double distance = rangevalue.end - rangevalue.start;
                        if (value + distance < chartdatas.length) {
                          setState(() {
                            bigchart.clear();
                            sliderforscale = value;
                            rangevalue = RangeValues(value, value + distance);
                            for (int i = rangevalue.start.toInt();
                                i < rangevalue.end.toInt();
                                i++) {
                              bigchart.add(FlSpot(chartdate[i], chartdatas[i]));
                            }
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
