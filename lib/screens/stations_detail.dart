import 'package:flutter/material.dart';

import '../openweathermap_stations_v3.dart';

class StationsDetail extends StatefulWidget {
  final Station station;

  const StationsDetail({Key key, @required this.station}) : super(key: key);

  @override
  _StationsDetailState createState() => _StationsDetailState();
}

class _StationsDetailState extends State<StationsDetail> {
  @override
  Widget build(BuildContext context) {
    return Container(child: Text(this.widget.station.name),);
  }
}
