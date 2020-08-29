import 'package:flutter/material.dart';
import 'package:openweathermap_stations_api/screens/stations_form.dart';
import 'package:share/share.dart';

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
        child: Column(
          children: [
            Text(this.widget.station.id),
            RaisedButton(
              child: Text('Share ID'),
              onPressed: () {
                _onShare(context);
              },
            )
          ],
        ),
      ),
    );
  }

  void _onShare(BuildContext context) async {
    // A builder is used to retrieve the context immediately
    // surrounding the RaisedButton.
    //
    // The context's `findRenderObject` returns the first
    // RenderObject in its descendent tree when it's not
    // a RenderObjectWidget. The RaisedButton's RenderObject
    // has its position and size after it's built.
    final RenderBox box = context.findRenderObject();

    await Share.share(this.widget.station.id,
        subject: 'Station ID of ${this.widget.station.name}',
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }
}
