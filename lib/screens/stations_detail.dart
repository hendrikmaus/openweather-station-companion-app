import 'package:flutter/material.dart';
import 'package:openweathermap_stations_api/screens/stations_form.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(this.widget.station.name),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return StationFormUpdate(station: this.widget.station);
              }));
            },
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(8),
        // TODO the station model does not contain the externally assigned ID
        child: Text(this.widget.station.toJson().toString()),
      ),
    );
  }
}
