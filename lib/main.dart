import 'dart:developer';

import 'package:openweathermap_stations_api/openweathermap_stations_v3.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';

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
        log('no api-key found');
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
    return ListTile(
      title: _stations[index].name == null
          ? Text('No station found')
          : Text(_stations[index].name),
    );
  }

  void _pushSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return SettingsScreen(
        title: "Settings",
        children: [
          TextFieldModalSettingsTile(
            settingKey: 'api-key',
            title: 'API Key',
            obscureText: true,
            okCaption: 'Save',
            subtitle: 'Your API key to access OpenWeatherMap',
            icon: Icon(Icons.vpn_key),
          )
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
