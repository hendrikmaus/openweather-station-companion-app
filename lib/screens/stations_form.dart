// TODO we also need to be able to edit Stations; it would be nice to re-use the form
// instead if duplicating it entirely with different labels
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:http/http.dart' as http;
import '../openweathermap_stations_v3.dart';

class StationForm extends StatefulWidget {
  @override
  _StationFormState createState() => _StationFormState();
}

class _StationFormState extends State<StationForm> {
  final _formKey = GlobalKey<FormState>();
  final _station = Station();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Station'),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Form(
            key: _formKey,
            child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                children: <Widget>[
                  TextFormField(
                    autofocus: true,
                    decoration: InputDecoration(
                        labelText: 'External ID', hintText: 'CITYCODE_0001'),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'This value is required';
                      }
                      // TODO should we restrict the value somehow according to the API specs?
                      return null;
                    },
                    onSaved: (value) {
                      setState(() {
                        _station.externalID = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Name', hintText: 'My Station\'s Name'),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'This value is required';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      setState(() {
                        _station.name = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Latitude', hintText: '0.000000'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'This value is required';
                      }
                      final n = num.tryParse(value).toDouble();
                      if (n == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      setState(() {
                        _station.latitude = num.parse(value).toDouble();
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Longitude', hintText: '0.000000'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'This value is required';
                      }
                      final n = num.tryParse(value).toDouble();
                      if (n == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      setState(() {
                        _station.latitude = num.parse(value).toDouble();
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Altitude',
                        hintText: '42',
                        helperText: 'Altitude in meters above sea level'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'This value is required';
                      }
                      final n = num.tryParse(value).toInt();
                      if (n == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      setState(() {
                        _station.altitude = num.parse(value).toInt();
                      });
                    },
                  ),
                  Container(
                    margin: EdgeInsets.all(10.0),
                    child: RaisedButton(
                      onPressed: () async {
                        final form = _formKey.currentState;
                        if (form.validate()) {
                          form.save();
                          Scaffold.of(context).showSnackBar(
                              SnackBar(content: Text('Processing ...')));

                          // TODO call the OpenWeatherMap API with the station model
                          // TODO what happens of the API call fails?
                          // I would like to not loose the form content, but mark the respective fields
                          String apiKey =
                              await Settings().getString('api-key', '');
                          if (apiKey.isEmpty) {
                            throw Exception(
                                'Could not retrieve API key from settings');
                          }
                          OpenWeatherMapStationsV3 client =
                              OpenWeatherMapStationsV3(apiKey);
                          http.Response resp =
                              await client.createStation(_station);
                          if (resp.statusCode == 201) {
                            Navigator.of(context).pop();
                            // TODO how do we refresh the underlying view?
                          } else {
                            var errMsg = jsonDecode(resp.body);
                            if (errMsg['message'] == null) {
                              Scaffold.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('Failed to create station'),
                              ));
                            } else {
                              Scaffold.of(context)
                                .showSnackBar(SnackBar(
                                  content: Text('Failed to create station:\n${errMsg['message']}'),
                              ));
                            }
                          }
                        }
                      },
                      child: Text('Create'),
                      color: Colors.blueAccent,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
