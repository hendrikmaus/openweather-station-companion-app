import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';

class AppSettings extends StatefulWidget {
  @override
  _AppSettingsState createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: "Settings",
      children: [
        SettingsTileGroup(
          title: 'Connectivity',
          children: [
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
                '7d': '1 week',
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
  }
}
