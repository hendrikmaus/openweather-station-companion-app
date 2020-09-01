# 🐴 OpenWeather Station Companion

> A unofficial companion app to the [OpenWeather Station API 3.0](https://openweathermap.org/stations) to manage
your own stations and retrieve their measurements.

## 🔬 Features

- Manage your own **stations**
- List **measurements**

> This is not yet another weather app.

Consider this to be a utility to quickly peek at your readings; for more sophisticated use cases,
you should probably integrate the API with your systems. For example, I can picture an integration with Home Assistant.

## 🔧 Usage

- Build your [station](https://github.com/hendrikmaus/openweather-station) (hardware)
- Create a station resource using the companion app
- Retrieve its ID for your micro-controller firmware
- Deploy

## 🥸 Rationale

I was building a weather station with a friend of mine and thought of a low-complexity implementation for a backend. Obviously, an existing platform came to mind, so I wouldn't have to host and/or build a bunch of services for the project. I immediately thought of using MQTT and began the search for a publicly available broker and an Android app to consume the data. My idea was to find something like the Things Network, just for MQTT. But there were several problems with that idea: 1) all public MQTT brokers are only meant for testing, so you cannot expect them to function all the time 2) MQTT itself has no persistence for historical data, but the main use case, my friend had in mind, was to retrieve short-term historical data (hours and days).

I have made good experiences with OpenWeatherMap in the past, and we were actually talking about submitting the data to an open system, so I went ahead and checked out their latest API documentation; turned out, you can connect your own stations and use their platform as a backend to record and retrieve measurements.

> Aside: as of 2020-08-20, your stations are not part of their public search results.

The free tier seemed to be a very reasonable option. So that was set for a backend.

We also wanted an easy way to retrieve the readings on Android. A colleague, just recently, told me about his side-project, which involved building a mobile application using Flutter. So I went ahead and checked out their documentation. I came back amazed and started to implement the companion app for the OpenWeatherMap Station API.

## 🍏 What About iOS

Unfortunately, I cannot compile and test for the iOS platform. I have not looked into any cloud service to work around the missing hardware and probably will not in the future.
