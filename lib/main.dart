import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;
  List<dynamic> datas = [0, 0];
  List<double> chartdatas = [];

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future fetchAlbum() async {}

  Future getHttp() async {
    try {
      var response = await Dio().get('http://188.166.98.87:1880/GetChartData');

      setState(() {
        datas = response.data["dataPoints"];
        datas.forEach((element) {
          chartdatas.add(element["y"]);
        });
      });
      print(chartdatas);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          ElevatedButton(onPressed: getHttp, child: const Text('Get Chart')),
          Expanded(
            child: BarChart(BarChartData(
                borderData: FlBorderData(
                    border: const Border(
                  top: BorderSide.none,
                  right: BorderSide.none,
                  left: BorderSide(width: 1),
                  bottom: BorderSide(width: 1),
                )),
                groupsSpace: 10,
                barGroups: [
                  for (int i = 0; i < chartdatas.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                          y: chartdatas[i] - 400,
                          width: 5,
                          colors: [Colors.amber]),
                    ]),
                ])),
          )
        ],
      ),
    );
  }
}
