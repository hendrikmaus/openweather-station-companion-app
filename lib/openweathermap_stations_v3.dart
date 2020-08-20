import 'dart:convert';

import 'package:http/http.dart' as http;

class Station {
  // Fields relevant for creating and updating
  String externalID;
  String name;
  double latitude;
  double longitude;
  int altitude;

  // Fields set by the API when returning station resources
  String id;
  String createdAt;
  String updatedAt;
  int rank;

  Station(
      {this.externalID,
      this.name,
      this.latitude,
      this.longitude,
      this.altitude});

  // ToJson yields the required structure to create/update stations
  Map<String, dynamic> toJson() => {
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
        latitude = json['latitude'] is int
            ? (json['latitude'] as int).toDouble()
            : json['latitude'],
        longitude = json['longitude'] is int
            ? (json['longitude'] as int).toDouble()
            : json['longitude'],
        altitude = json['altitude'] is int
            ? json['altitude'] as int
            : json['altitude'],
        rank = json['rank'];
}

class MeasurementTemperature {
  final double max;
  final double min;
  final double average;
  final int weight;

  MeasurementTemperature(this.max, this.min, this.average, this.weight);

  MeasurementTemperature.fromJson(Map<String, dynamic> json)
      : max =
            json['max'] is int ? (json['max'] as int).toDouble() : json['max'],
        min =
            json['min'] is int ? (json['min'] as int).toDouble() : json['min'],
        average = json['average'] is int
            ? (json['average'] as int).toDouble()
            : json['average'],
        weight = json['weight'];
}

class MeasurementHumidity {
  final double average;
  final int weight;

  MeasurementHumidity(this.average, this.weight);

  MeasurementHumidity.fromJson(Map<String, dynamic> json)
      : average = json['average'] is int
            ? (json['average'] as int).toDouble()
            : json['average'],
        weight = json['weight'];
}

class MeasurementWind {
  final int deg;
  final double speed;

  MeasurementWind(this.deg, this.speed);

  MeasurementWind.fromJson(Map<String, dynamic> json)
      : deg = json['deg'],
        speed = json['speed'] is int
            ? (json['speed'] as int).toDouble()
            : json['speed'];
}

class MeasurementPressure {
  final double max;
  final double min;
  final double average;
  final int weight;

  MeasurementPressure(this.max, this.min, this.average, this.weight);

  MeasurementPressure.fromJson(Map<String, dynamic> json)
      : max =
            json['max'] is int ? (json['max'] as int).toDouble() : json['max'],
        min =
            json['min'] is int ? (json['min'] as int).toDouble() : json['min'],
        average = json['average'] is int
            ? (json['average'] as int).toDouble()
            : json['average'],
        weight = json['weight'];
}

class MeasurementPrecipitation {
  final double rain;

  MeasurementPrecipitation(this.rain);

  MeasurementPrecipitation.fromJson(Map<String, dynamic> json)
      : rain = json['rain'] is int
            ? (json['rain'] as int).toDouble()
            : json['rain'];
}

class Measurement {
  final String type;
  final int date;
  final String stationID;
  final MeasurementTemperature temp;
  final MeasurementHumidity humidity;
  final MeasurementWind wind;
  final MeasurementPressure pressure;
  final MeasurementPrecipitation precipitation;

  Measurement(this.type, this.date, this.stationID, this.temp, this.humidity,
      this.wind, this.pressure, this.precipitation);

  Measurement.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        date = json['date'],
        stationID = json['station_id'],
        temp = MeasurementTemperature.fromJson(json['temp']),
        humidity = MeasurementHumidity.fromJson(json['humidity']),
        wind = MeasurementWind.fromJson(json['wind']),
        pressure = MeasurementPressure.fromJson(json['pressure']),
        precipitation =
            MeasurementPrecipitation.fromJson(json['precipitation']);
}

class MeasurementRequest {
  final String stationID;
  final String type;
  final int limit;
  final int from;
  final int to;

  MeasurementRequest(this.stationID, this.type, this.limit, this.from, this.to);

  Map<String, dynamic> toJson() => {
        'station_id': this.stationID,
        'type': this.type,
        'limit': this.limit,
        'from': this.from,
        'to': this.to,
      };
}

class OpenWeatherMapStationsV3 {
  static const String baseURI = "http://api.openweathermap.org/data/3.0";
  final String apiKey;

  OpenWeatherMapStationsV3(this.apiKey);

  Future<dynamic> createStation(Station station) async {
    http.Response resp = await http.post('$baseURI/stations?appid=$apiKey',
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(station.toJson()));
    return resp;
  }

  Future<dynamic> updateStation(Station station) async {
    http.Response resp = await http.put(
        '$baseURI/stations/${station.id}?appid=$apiKey',
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(station.toJson()));
    return resp;
  }

  Future<List<Station>> getStations() async {
    var stations = <Station>[];
    final resp = await http.get('$baseURI/stations?appid=$apiKey');
    if (resp.statusCode == 200) {
      final Iterable result = json.decode(resp.body);
      stations = result.map((e) => Station.fromJson(e)).toList();
    } else {
      if (resp.statusCode == 429) {
        throw Exception('You exceeded the API call quota');
      }
      throw Exception('Failed to get list of stations\n${resp.body}');
    }
    return stations;
  }

  Future<dynamic> deleteStationByID(String stationID) async {
    http.Response resp =
        await http.delete('$baseURI/stations/$stationID?appid=$apiKey');
    return resp;
  }

  Future<List<Measurement>> getMeasurements(MeasurementRequest req) async {
    var measurements = <Measurement>[];
    final resp = await http.get(
        '$baseURI/measurements?station_id=${req.stationID}&type=${req.type}&limit=${req.limit}&from=${req.from}&to=${req.to}&appid=$apiKey');
    if (resp.statusCode == 200) {
      final Iterable result = json.decode(resp.body);
      measurements = result.map((e) => Measurement.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch measurements\n${resp.body}');
    }
    // reverse the list to get the latest measurements on top
    return measurements.reversed.toList();
  }
}
