import 'dart:convert';

import 'package:http/http.dart' as http;

class Station {
  // Fields relevant for creating and updating
  final String externalID;
  final String name;
  final double latitude;
  final double longitude;
  final int altitude;

  // Fields set by the API when returning station resources
  String id;
  String createdAt;
  String updatedAt;
  int rank;

  Station(this.externalID,
      this.name,
      this.latitude,
      this.longitude,
      this.altitude);

  // ToJson yields the required structure to create/update stations
  Map<String, dynamic> toJson() =>
      {
        'external_id': this.externalID,
        'name': this.name,
        'latitude': this.latitude,
        'longitude': this.longitude,
        'altitude': this.altitude,
      };

  Station.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      createdAt = json['created_at'],
      updatedAt = json['updated_at'],
      externalID = json['external_id'],
      latitude = json['latitude'],
      longitude = json['longitude'],
      altitude = json['altitude'],
      rank = json['rank'];
}

class OpenWeatherMapStationsV3 {
  static const String baseURI = "http://api.openweathermap.org/data/3.0";

  OpenWeatherMapStationsV3(this.apiKey);

  final String apiKey;

  // TODO return Station model instead of the http response
  Future<dynamic> getStationByID(String stationID) async {
    http.Response resp =
    await http.get('$baseURI/stations/$stationID?appid=$apiKey');

    return resp;
  }

  Future<dynamic> createStation(Station station) async {
    http.Response resp = await http.post('$baseURI/stations?appid=$apiKey',
      headers: {'Content-Type': 'application/json; charset=utf-8'}, body: station.toJson());
    return resp;
  }

  // TODO this function can only work with a fully populated station model returned by the api
  Future<dynamic> updateStation(Station station) async {
    http.Response resp = await http.put('$baseURI/stations/${station.id}?appid=$apiKey',
      headers: {'Content-Type': 'application/json; charset=utf-8'}, body: station.toJson());
    return resp;
  }

  Future<List<Station>> getStations() async {
    var stations = <Station>[];
    final resp = await http.get('$baseURI/stations?appid=$apiKey');
    if (resp.statusCode == 200) {
      final Iterable result = json.decode(resp.body);
      stations = result.map((e) => Station.fromJson(e)).toList();
    } else {
      // TODO build a proper user facing error message; e.g. the api requests in the free tier might have run out
      throw Exception('Failed to get list of stations');
    }
    return stations;
  }

  Future<dynamic> deleteStationByID(String stationID) async {
    http.Response resp = await http.delete('$baseURI/stations/$stationID?appid=$apiKey');
    return resp;
  }
}
