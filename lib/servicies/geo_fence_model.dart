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
  StreamSubscription<Position>? _positionStream;

  late Stream<GeofenceResult>? _geoStream;

  late StreamSubscription<GeofenceResult?> _geoStreamSubc;

  set geoStreamSubc(StreamSubscription<GeofenceResult?> value) {
    _geoStreamSubc = value;
  }

  Stream<GeofenceResult>? get geoStream => _geoStream;

  late StreamController<GeofenceResult> _geoStreamController;

  GeoFenceModel() {
    //  init();
  }

  init() {
    _geoStreamController = StreamController();
    _geoStream = _geoStreamController.stream;
  }

  startGeofence(
      {required double pointedLatitude,
      required double pointedLongitude,
      required double radius,
      required int eventPeriodInSecs}) async {
    init();

    if (_positionStream == null) {
      print('position stream $_geoStreamController');

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

  stopGeofence() async {
    if (_positionStream != null) {
      await _positionStream?.cancel();
      await _geoStreamController.close();
      await _geoStreamSubc.cancel();
      _positionStream = null;
    }
  }
}
