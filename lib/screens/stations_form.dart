// TODO the form setup is 100% duplicated code; there must be a better way to do that
// TODO reactive forms & provider maybe? reads amazing and would mean a rewrite of the entire app
// TODO https://github.com/joanpablo/reactive_forms
// TODO https://pub.dev/packages/provider/example
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:http/http.dart' as http;
import '../openweathermap_stations_v3.dart';

class StationFormCreate extends StatefulWidget {
  @override
  _StationFormCreateState createState() => _StationFormCreateState();
}

class _StationFormCreateState extends State<StationFormCreate> {
  final _formKey = GlobalKey<FormState>();
  final Station _station = Station();

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
                              Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text('Failed to create station'),
                              ));
                            } else {
                              Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    'Failed to create station:\n${errMsg['message']}'),
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

class StationFormUpdate extends StatefulWidget {
  final Station station;

  const StationFormUpdate({Key key, this.station}) : super(key: key);

  @override
  _StationFormUpdateState createState() => _StationFormUpdateState();
}

class _StationFormUpdateState extends State<StationFormUpdate> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Station ${this.widget.station.externalID}'),
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
                    initialValue: this.widget.station.externalID,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'This value is required';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      setState(() {
                        this.widget.station.externalID = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Name', hintText: 'My Station\'s Name'),
                    initialValue: this.widget.station.name,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'This value is required';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      setState(() {
                        this.widget.station.name = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Latitude', hintText: '0.000000'),
                    keyboardType: TextInputType.number,
                    initialValue: this.widget.station.latitude.toString(),
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
                        this.widget.station.latitude =
                            num.parse(value).toDouble();
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Longitude', hintText: '0.000000'),
                    keyboardType: TextInputType.number,
                    initialValue: this.widget.station.longitude.toString(),
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
                        this.widget.station.latitude =
                            num.parse(value).toDouble();
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Altitude',
                        hintText: '42',
                        helperText: 'Altitude in meters above sea level'),
                    keyboardType: TextInputType.number,
                    initialValue: this.widget.station.altitude.toString(),
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
                        this.widget.station.altitude = num.parse(value).toInt();
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
                          String apiKey =
                              await Settings().getString('api-key', '');
                          if (apiKey.isEmpty) {
                            throw Exception(
                                'Could not retrieve API key from settings');
                          }
                          OpenWeatherMapStationsV3 client =
                              OpenWeatherMapStationsV3(apiKey);
                          http.Response resp =
                              await client.updateStation(this.widget.station);
                          if (resp.statusCode == 200) {
                            Navigator.of(context).pop();
                            // TODO how do we refresh the underlying view?
                          } else {
                            var errMsg = jsonDecode(resp.body);
                            if (errMsg['message'] == null) {
                              Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text('Failed to update station'),
                              ));
                            } else {
                              Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    'Failed to update station:\n${errMsg['message']}'),
                              ));
                            }
                          }
                        }
                      },
                      child: Text('Save'),
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
