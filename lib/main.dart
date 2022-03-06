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
  double sliderforbegin = 10.0;
  double sliderforscale = 20.0;
  RangeValues rangevalue = RangeValues(1.0, 20.0);
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
      var gotdatas = response.data["dataPoints"];
      datas = List.from(gotdatas.reversed);
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

  Future postHttp() async {
    String index = inputfieldcontroll.text;
    double number = double.parse(inputfieldcontroll2.text);
    //  Map<int, double> datas = {index: number};
    var response;
    Dio dio = Dio();
    //  dio.options.contentType = Headers.formUrlEncodedContentType;
    //dio.options.headers['content-Type'] = 'application/json';
    dio.options.contentType = 'application/json';
    dio.options.responseType = ResponseType.plain;
    try {
      response = await dio
          .post('http://188.166.98.87:1880/AddPattern', data: {index: number});
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
                          for (int i = rangevalue.start.toInt();
                              i < rangevalue.end.toInt();
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
                                coloring(i)
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
                      divisions:
                          chartdatas.isNotEmpty ? (chartdatas.length - 1) : 1,
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
                      divisions:
                          chartdatas.isNotEmpty ? (chartdatas.length - 1) : 1,
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
