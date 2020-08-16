import 'dart:developer';

import 'package:duration/duration.dart';
import 'package:flutter/cupertino.dart';
import 'package:openweathermap_stations_api/openweathermap_stations_v3.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:timeago/timeago.dart' as timeago;

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
          SettingsTileGroup(
            title: 'Connectivity',
            children: [
              // TODO add some help on where to get an API key
              TextFieldModalSettingsTile(
                settingKey: 'api-key',
                title: 'API Key',
                obscureText: true,
                okCaption: 'Save',
                subtitle:
                    'Your API key to access OpenWeatherMap\n\nGet your key:\n1) Register for a free account on https://openweathermap.org\n2) Navigate to "API keys" in your profile view\n3) Create a key for the app to use\n',
              ),
            ],
          ),
          SettingsTileGroup(
            title: 'Measurements',
            children: [
              RadioPickerSettingsTile(
                settingKey: 'm-type',
                title: 'Aggregation Type',
                subtitle: 'Define the resolution of the aggregated data',
                values: {
                  'm': 'Minute',
                  'h': 'Hour',
                  'd': 'Day',
                },
                defaultKey: 'h',
              ),
              RadioPickerSettingsTile(
                settingKey: 'm-from',
                title: 'Timeframe',
                subtitle: 'Default time from which to start the data points',
                // Since the map can only have a string for a key,
                // we need to turn it into an integer, multiply it by 60 to get seconds
                // multiply it by 1000 to get milliseconds and then add it to the epoch millis
                // to get the value for the DateTime. The api ultimately wants a unix timestamp in seconds
                values: {
                  '1h': '1 hour',
                  '2h': '2 hours',
                  '3h': '3 hours',
                  '5h': '5 hours',
                  '8h': '8 hours',
                  '1d': '1 day',
                  '3d': '3 days',
                  '1w': '1 week',
                },
                defaultKey: '24',
              ),
              SliderSettingsTile(
                settingKey: 'm-limit',
                title: 'Result Limit',
                subtitle: 'Default amount of data points',
                defaultValue: 10.0,
                minValue: 1.0,
                maxValue: 100.0,
              ),
            ],
          ),
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
        DateTime.now().subtract(dur).millisecondsSinceEpoch ~/ 1000,
        DateTime.now().millisecondsSinceEpoch ~/ 1000);

    client.getMeasurements(req).then((value) => {
          setState(() {
            _measurements = value;
          })
        });
  }

  _MeasurementsState(this._station);

  ExpansionTile _buildItemsForListViewExpandable(
      BuildContext context, int index) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Measurements (${_station.externalID})'),
      ),
      body: ListView.builder(
        itemBuilder: _buildItemsForListViewExpandable,
        itemCount: _measurements.length,
      ),
    );
  }
}
