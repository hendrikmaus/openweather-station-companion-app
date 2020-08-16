import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:openweathermap_stations_api/openweathermap_stations_v3.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:timeago/timeago.dart' as timeago;

/*
TODO
- app starts and checks if it knows an api key
  - if not > form to enter api key
    - supporting one api is ok, right? a user should not have multiple api keys
- app displays a list view of stations
  - floating + button on the lower right side to create new stations
- a tap on a station switches to a list of the 10 latest measurements for the station
 */

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final String appTitle = 'OpenWeatherMap Stations';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appTitle,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Stations(),
    );
  }
}

class Stations extends StatefulWidget {
  @override
  _StationsState createState() => _StationsState();
}

class _StationsState extends State<Stations> {
  List<Station> _stations = List<Station>();

  @override
  void initState() {
    super.initState();
    _populateStations();
  }

  void _populateStations() async {
    String apiKey = await Settings().getString('api-key', '');
    if (apiKey.isEmpty) {
      setState(() {
        _stations = List<Station>();
      });
      return;
    }
    OpenWeatherMapStationsV3 client = OpenWeatherMapStationsV3(apiKey);
    client.getStations().then((value) => {
          setState(() {
            _stations = value;
          })
        });
  }

  ListTile _buildItemsForListView(BuildContext context, int index) {
    // TODO when the stations list is empty, we can display a single large tile in the center that helps to set up things
    // TODO add dividers to the list view
    return ListTile(
      title: _stations[index].name == null
          ? Text('No station found')
          : Text(_stations[index].name),
      subtitle: _stations[index].externalID == null
          ? Text('')
          : Text(_stations[index].externalID),
      trailing: Icon(Icons.keyboard_arrow_right),
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (BuildContext context) {
          return Measurements(station: _stations[index]);
        }));
      },
    );
  }

  void _pushSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return SettingsScreen(
        title: "Settings",
        children: [
          // TODO add some help on where to get an API key
          TextFieldModalSettingsTile(
            settingKey: 'api-key',
            title: 'API Key',
            obscureText: true,
            okCaption: 'Save',
            subtitle: 'Your API key to access OpenWeatherMap',
            icon: Icon(Icons.vpn_key),
          ),
          // TODO add a section with default settings to fetch measurements
        ],
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenWeatherMap Stations'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _pushSettings,
          ),
        ],
      ),
      body: ListView.builder(
        itemBuilder: _buildItemsForListView,
        itemCount: _stations.length,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Station',
        child: Icon(Icons.add),
        onPressed: () {},
      ),
    );
  }
}

class Measurements extends StatefulWidget {
  final Station station;

  const Measurements({Key key, @required this.station}) : super(key: key);

  @override
  _MeasurementsState createState() => _MeasurementsState(this.station);
}

class _MeasurementsState extends State<Measurements> {
  final Station _station;
  List<Measurement> _measurements = List<Measurement>();

  @override
  void initState() {
    super.initState();
    _getMeasurements();
  }

  void _getMeasurements() async {
    String apiKey = await Settings().getString('api-key', '');
    // TODO pretty impossible to get here without an api key, so we'll throw an exception if we cannot retrieve it
    if (apiKey.isEmpty) {
      throw Exception('Could not retrieve API key from settings');
    }

    OpenWeatherMapStationsV3 client = OpenWeatherMapStationsV3(apiKey);

    // TODO the request value defaults can come from the settings
    // TODO the user should be able to select them at the top of the view
    // TODO handle pagination
    MeasurementRequest req =
        MeasurementRequest(_station.id, 'm', 10, 1597501175, 1597574084);

    client.getMeasurements(req).then((value) => {
          setState(() {
            _measurements = value;
          })
        });
  }

  _MeasurementsState(this._station);

  ListTile _buildItemsForListView(BuildContext context, int index) {
    if (_measurements[index] == null) {
      return null;
    }

    final Measurement m = _measurements[index];
    final DateTime timeStamp =
        DateTime.fromMillisecondsSinceEpoch(m.date * 1000);
    return ListTile(
      subtitle: Text(timeago.format(timeStamp)),
      title: Text(
        m.temp.average.toString() + ' °C',
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
      ),
//      trailing: Text(m.humidity.average.toString() + '%'),
      trailing: Icon(Icons.keyboard_arrow_right),
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (BuildContext context) {
          return MeasurementDetail(measurement: _measurements[index]);
        }));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Measurements (${_station.externalID})'),
      ),
      body: ListView.builder(
        itemBuilder: _buildItemsForListView,
        itemCount: _measurements.length,
      ),
    );
  }
}

class MeasurementDetail extends StatefulWidget {
  final Measurement measurement;

  const MeasurementDetail({Key key, @required this.measurement})
      : super(key: key);

  @override
  _MeasurementDetailState createState() =>
      _MeasurementDetailState(this.measurement);
}

class _MeasurementDetailState extends State<MeasurementDetail> {
  final Measurement m;

  _MeasurementDetailState(this.m);

  @override
  Widget build(BuildContext context) {
    final DateTime timeStamp =
        DateTime.fromMillisecondsSinceEpoch(m.date * 1000);

    return Scaffold(
        appBar: AppBar(
          title: Text(timeago.format(timeStamp)),
        ),
        body: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: [
              // TODO some things might be null and should not be displayed then
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
          ).toList(),
        ));
  }
}
