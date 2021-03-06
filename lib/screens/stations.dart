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
  bool _displayEmptyList = false;
  String _displayError = "";

  @override
  void initState() {
    super.initState();
    _populateStations();
  }

  Future<void> _populateStations() async {
    String apiKey = await Settings().getString('api-key', '');
    if (apiKey.isEmpty) {
      _displayEmptyList = true;

      setState(() {
        _stations = List<Station>();
      });
      return;
    }

    OpenWeatherMapStationsV3 client = OpenWeatherMapStationsV3(apiKey);
    client.getStations().then((value) {
      _displayError = "";

      if (value.length == 0) {
        print('no stations found');
        _displayEmptyList = true;
      } else {
        _displayEmptyList = false;
      }
      setState(() {
        _stations = value;
      });
    }).catchError((err) {
      _displayError = err.toString();
    });
  }

  Widget _buildItemsForListView(BuildContext context, int index) {
    return Dismissible(
      key: Key(_stations[index].id),
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
            return StationFormUpdate(station: _stations[index]);
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
    if (_displayError.isNotEmpty) {
      return RefreshIndicator(
        child: ListView(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 0, vertical: 50),
              child: ListTile(
                title: Text(_displayError, textAlign: TextAlign.center),
                enabled: false,
              ),
            )
          ],
        ),
        onRefresh: _populateStations,
      );
    }

    if (_displayEmptyList) {
      return RefreshIndicator(
        child: ListView(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 0, vertical: 50),
              child: ListTile(
                title: Text('No stations found', textAlign: TextAlign.center),
                enabled: false,
              ),
            )
          ],
        ),
        onRefresh: _populateStations,
      );
    }

    return _stations.length != 0 && _displayEmptyList == false
        ? RefreshIndicator(
            child: ListView.builder(
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
        onPressed: () async {
          String apiKey = await Settings().getString('api-key', '');
          if (apiKey.isEmpty) {
            _pushSettings();
            return;
          }

          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return StationFormCreate();
          }));
        },
      ),
    );
  }
}
