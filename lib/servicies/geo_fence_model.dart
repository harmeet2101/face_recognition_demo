import 'dart:async';

import 'package:geolocator/geolocator.dart';

class GeofenceResult {
  double? latitude;
  double? longitude;
  GeofenceEvent? event;

  GeofenceResult({required this.event, this.latitude, this.longitude});
}

enum GeofenceEvent {
  init,
  enter,
  exit,
}

class GeoFenceModel {
  static StreamSubscription<Position>? _positionStream;

  static Stream<GeofenceResult>? _geoStream;

  static Stream<GeofenceResult>? get geoStream => _geoStream;

  static final StreamController<GeofenceResult> _geoStreamController =
      StreamController<GeofenceResult>();

  static startGeofence(
      {required double pointedLatitude,
      required double pointedLongitude,
      required double radius,
      required int eventPeriodInSecs}) async {
    if (_positionStream == null) {
      _geoStream = _geoStreamController.stream;
      _positionStream = Geolocator.getPositionStream(
              locationSettings:
                  const LocationSettings(accuracy: LocationAccuracy.best))
          .listen((position) {
        if (position != null) {
          print('current loc ${position.latitude} ${position.longitude}');

          double dist = Geolocator.distanceBetween(pointedLatitude,
              pointedLongitude, position.latitude, position.longitude);
          print('Radius $radius and dist $dist');
          if (dist > radius) {
            _geoStreamController.add(GeofenceResult(
                event: GeofenceEvent.exit,
                latitude: position.latitude,
                longitude: position.longitude));
          } else {
            _geoStreamController.add(GeofenceResult(
                event: GeofenceEvent.enter,
                latitude: position.latitude,
                longitude: position.longitude));
          }

          _positionStream?.pause(
              Future.delayed(Duration(milliseconds: eventPeriodInSecs)));
        }
      });
      _geoStreamController.add(GeofenceResult(
          event: GeofenceEvent.init,
          longitude: pointedLongitude,
          latitude: pointedLatitude));
    }
  }

  static stopGeofence() {
    if (_positionStream != null) {
      _positionStream!.cancel();
    }
   //  _geoStreamController.close();
  }
}
