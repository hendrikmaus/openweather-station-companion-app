import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:openweathermap_stations_api/screens/settings.dart';
import 'package:openweathermap_stations_api/screens/stations_form.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:http/http.dart' as http;
import '../openweathermap_stations_v3.dart';
import 'measurements.dart';

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

  Future<void> _populateStations() async {
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

  Widget _buildItemsForListView(BuildContext context, int index) {
    // TODO when the stations list is empty, we can display a single large tile in the center that helps to set up things
    // TODO add dividers to the list view
    // https://medium.com/flutter-community/an-in-depth-dive-into-implementing-swipe-to-dismiss-in-flutter-41b9007f1e0
    return Dismissible(
      key: Key(_stations[index].id),
      // TODO one of these actions should be tuned into editing the station details
      background: Container(
        color: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: AlignmentDirectional.centerStart,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: AlignmentDirectional.centerEnd,
        child: Icon(Icons.edit, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Text(
                      'Do you really want to delete this station? All measurements will be deleted as well. This action cannot be undone.'),
                  actions: [
                    FlatButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(false),
                      textColor: Colors.grey,
                    ),
                    FlatButton(
                      child: Text('Delete'),
                      onPressed: () => Navigator.of(context).pop(true),
                      textColor: Colors.red,
                    ),
                  ],
                );
              });
        } else {
          return await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) {
            // TODO now the form needs to support being in update mode
            return StationForm(
              station: _stations[index],
            );
          }));
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          String apiKey = await Settings().getString('api-key', '');
          if (apiKey.isEmpty) {
            throw Exception('Could not retrieve API key from settings');
          }
          OpenWeatherMapStationsV3 client = OpenWeatherMapStationsV3(apiKey);
          http.Response resp =
              await client.deleteStationByID(_stations[index].id);
          if (resp.statusCode == 204) {
            Scaffold.of(context).showSnackBar(SnackBar(
                content:
                    Text('Deleted station: ${_stations[index].externalID}')));
            setState(() {
              _stations.removeAt(index);
            });
          } else {
            var errMsg = jsonDecode(resp.body);
            if (errMsg['message'] == null) {
              Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Failed to delete station: ${_stations[index].externalID}')));
            } else {
              Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Failed to delete station: ${_stations[index].externalID}\n${errMsg['message']}')));
            }
            print(resp.body);
          }
        }
      },
      child: ListTile(
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
      ),
    );
  }

  void _pushSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return AppSettings();
    }));
  }

  Widget _buildListView() {
    return _stations.length != 0
        ? RefreshIndicator(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _stations.length,
              itemBuilder: _buildItemsForListView,
            ),
            onRefresh: _populateStations,
          )
        : Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stations'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _pushSettings,
          ),
        ],
      ),
      body: _buildListView(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Station',
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return StationForm();
          }));
        },
      ),
    );
  }
}
