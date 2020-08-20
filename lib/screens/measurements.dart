import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../openweathermap_stations_v3.dart';
import 'package:duration/duration.dart';

class Measurements extends StatefulWidget {
  final Station station;

  const Measurements({Key key, @required this.station}) : super(key: key);

  @override
  _MeasurementsState createState() => _MeasurementsState(this.station);
}

class _MeasurementsState extends State<Measurements> {
  final Station _station;
  List<Measurement> _measurements = List<Measurement>();
  bool _displayEmptyList = false;

  @override
  void initState() {
    super.initState();
    _getMeasurements();
  }

  Future<void> _getMeasurements() async {
    // TODO turn the setting keys into an enum
    String apiKey = await Settings().getString('api-key', '');
    // TODO pretty impossible to get here without an api key, so we'll throw an exception if we cannot retrieve it
    if (apiKey.isEmpty) {
      throw Exception('Could not retrieve API key from settings');
    }

    OpenWeatherMapStationsV3 client = OpenWeatherMapStationsV3(apiKey);

    String durationSetting = await Settings().getString('m-from', '24h');
    Duration dur = parseDuration(durationSetting);

    // TODO the user should be able to select them at the top of the view
    // TODO handle pagination - I think the api does not support pagination (yet)
    // TODO display a snackbar during the api call as it might take some time
    MeasurementRequest req = MeasurementRequest(
        _station.id,
        await Settings().getString('m-type', 'h'),
        (await Settings().getDouble('m-limit', 10)).toInt(),
        DateTime
            .now()
            .subtract(dur)
            .millisecondsSinceEpoch ~/ 1000,
        DateTime
            .now()
            .millisecondsSinceEpoch ~/ 1000);

    client.getMeasurements(req).then((value) {
      setState(() {
        if (value.length == 0) {
          print('no measurements found');
          _displayEmptyList = true;
        } else {
          _displayEmptyList = false;
        }
        _measurements = value;
      });
    });
  }

  _MeasurementsState(this._station);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Measurements (${_station.externalID})'),
      ),
      body: _buildListView(),
    );
  }

  Widget _buildListView() {
    if (_displayEmptyList) {
      return RefreshIndicator(
        child: ListView(
          padding: EdgeInsets.all(8),
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 0, vertical: 50),
              child: ListTile(
                title: Text('No measurements found', textAlign: TextAlign.center),
                enabled: false,
              ),
            )
          ],
        ),
        onRefresh: _getMeasurements,
      );
    }

    return _measurements.length != 0 && _displayEmptyList == false
        ? RefreshIndicator(
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: _measurements.length,
        itemBuilder: _buildItemsForListViewExpandable,
      ),
      onRefresh: _getMeasurements,
    )
        : Center(child: CircularProgressIndicator());
  }

  Widget _buildItemsForListViewExpandable(BuildContext context, int index) {
    if (_measurements[index] == null) {
      return null;
    }

    final Measurement m = _measurements[index];
    final DateTime timeStamp =
    DateTime.fromMillisecondsSinceEpoch(m.date * 1000);
    return ExpansionTile(
      subtitle: Text(timeago.format(timeStamp)),
      title: Text(
        m.temp.average.toString() + ' °C',
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
      ),
      children: [
        ListTile(
          leading: Icon(Icons.wb_sunny),
          title: Text('Temperature'),
          subtitle: Text('min: ' +
              m.temp.min.toString() +
              ' °C' +
              ' / ' +
              'max: ' +
              m.temp.max.toString() +
              ' °C'),
          trailing: Text(m.temp.average.toString() + ' °C'),
        ),
        ListTile(
          leading: Icon(Icons.opacity),
          title: Text('Rel. Humidity'),
          trailing: Text(m.humidity.average.toString() + ' %'),
        ),
        ListTile(
          leading: Icon(Icons.outlined_flag),
          title: Text('Wind'),
          subtitle: Text('direction: ' + m.wind.deg.toString() + '°'),
          trailing: Text(m.wind.speed.toString() + ' km/h'),
        ),
        ListTile(
          leading: Icon(Icons.public),
          title: Text('Pressure'),
          subtitle: Text('min: ' +
              m.pressure.min.toString() +
              ' hPa' +
              ' / ' +
              'max: ' +
              m.pressure.max.toString() +
              ' hPa'),
          trailing: Text(m.pressure.average.toString() + ' hPa'),
        ),
        ListTile(
          leading: Icon(Icons.cloud),
          title: Text('Precipitation'),
          trailing: Text(m.precipitation.rain.toString() + ' mm'),
        )
      ],
    );
  }
}
