import 'dart:async';

import 'package:face_recognition_demo/model/User.dart';
import 'package:face_recognition_demo/common/utils/shared__preferences.dart';
import 'package:face_recognition_demo/model/user_attendance.dart';
import 'package:face_recognition_demo/servicies/database_helper.dart';
import 'package:face_recognition_demo/servicies/geo_fence_model.dart';
import 'package:face_recognition_demo/ui/home/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/src/enums/location_permission.dart'
    as lp;
import 'package:geolocator_platform_interface/src/enums/location_accuracy.dart'
    as la;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class CheckInOutScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CheckInOutState();
  }
}

class _CheckInOutState extends State<CheckInOutScreen> {
  late CameraPosition _initialCameraPos;
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  double _zoomLevel = 15.0;
  Set<Marker> _markers = {};
  late Set<Circle> geofenceArea = {};
  String? _currentAddress;
  final _addressTextController = TextEditingController();

  bool? _withinGpsRegion;
  bool _fetchingInitPos = false;

  User? user;

  DatebaseHelper _datebaseHelper = DatebaseHelper.instance;

  @override
  void initState() {
    setupMap();
    super.initState();
  }

  Future<void> setupMap() async {
    _fetchInitLoc();
    _getUser();
    _datebaseHelper.initailize();
  }

  Future<void> _getUser() async {
    user = await PreferenceManager.instance.getUser();
    print('User ${user ?? 'NA'}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Screen')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextFormField(
                    enabled: false,
                    controller: _addressTextController,
                    decoration: const InputDecoration(
                      labelStyle: TextStyle(
                        color: Colors.black,
                      ),
                      labelText: 'Current Location',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Within Geofence Area'),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.black, width: 0.5),
                              color: _withinGpsRegion == null
                                  ? Colors.grey
                                  : (_withinGpsRegion!
                                      ? Colors.green
                                      : Colors.red)),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Check In:'),
                        Text('Test'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Check Out:'),
                        Text('Test'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Work Duration:'),
                        Text('8 hrs'),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 20.0),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                width: double.infinity,
                child: _fetchingInitPos
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : GoogleMap(
                        zoomControlsEnabled: true,
                        compassEnabled: true,
                        markers: _markers,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController.complete(controller);
                          _goTodiffLoc();
                        },
                        circles: geofenceArea,
                        initialCameraPosition: _initialCameraPos,
                        mapType: MapType.normal,
                        myLocationEnabled: true,
                        onLongPress: (position) => addGeofenceArea(position),
                      ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    markAttendance();
                  },
                  child: Text('Done'),
                ))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            // _goTodiffLoc();
            startMonitoring();
          },
          child: const Icon(Icons.home)),
    );
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('serice enabled $serviceEnabled');
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();

      Geolocator.getServiceStatusStream().listen((event) {
        if (event != ServiceStatus.enabled) {
          throw Future.error('Location service not enabled');
        }
      });
    }

    lp.LocationPermission locationPermission;

    locationPermission = await Geolocator.requestPermission();

    if (locationPermission == lp.LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == lp.LocationPermission.denied) {
        throw Future.error('Location permission denied');
      }
    }
    if (locationPermission == lp.LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final res = await Geolocator.getCurrentPosition(
        desiredAccuracy: la.LocationAccuracy.high);
    print('Here ${res.latitude}');
    return res;
  }

  Future<void> _fetchInitLoc() async {
    try {
      _fetchingInitPos = true;
      Position currentLoc = await _getCurrentLocation();
      final ltlng = LatLng(currentLoc.latitude, currentLoc.longitude);
      _initialCameraPos = CameraPosition(target: ltlng, zoom: _zoomLevel);
      _fetchingInitPos = false;
      print('current pos ${ltlng.latitude} ${ltlng.longitude}');
      _markers.clear();
      _markers.add(Marker(
          markerId: const MarkerId('My location'),
          position: ltlng,
          infoWindow: InfoWindow(
              title: 'Current location',
              onTap: () {
                print('On Click');
              })));

      _getAddressFromCoordinates(ltlng.latitude, ltlng.longitude);
    } on Exception catch (e) {
      print('Error $e');
      _fetchingInitPos = false;
    }
    setState(() {});
  }

  void addGeofenceArea(LatLng position) {
    geofenceArea.clear();
    GeoFenceModel.stopGeofence();

    Circle circle = Circle(
        center: position,
        radius: 100.0,
        fillColor: Colors.red.shade100.withOpacity(0.8),
        strokeColor: Colors.red.shade100.withOpacity(0.2),
        strokeWidth: 2,
        circleId: const CircleId('Area 1'));
    geofenceArea.add(circle);

    setState(() {});
  }

  void startMonitoring() {
    if (geofenceArea.isEmpty) return;

    GeoFenceModel.startGeofence(
        pointedLatitude: geofenceArea.first.center.latitude,
        pointedLongitude: geofenceArea.first.center.longitude,
        radius: geofenceArea.first.radius,
        eventPeriodInSecs: 1200);

    GeoFenceModel.geoStream?.listen((event) {
      _getAddressFromCoordinates(event.latitude!, event.longitude!);
      _withinGpsRegion = (event.event == GeofenceEvent.enter) ? true : false;
      print('GEO Event ${event.event} within GPS region $_withinGpsRegion');
    });
  }

  Future<void> _goTodiffLoc() async {
    final controller = await _mapController.future;
    /*print('calling ${controller}');
    Position currentLoc = await _getCurrentLocation();
    final ltlng = LatLng(currentLoc.latitude, currentLoc.longitude);
    print('current pos ${ltlng.latitude} ${ltlng.longitude}');
    _markers.clear();
    _markers.add(Marker(
        markerId: const MarkerId('My location'),
        position: ltlng,
        infoWindow: InfoWindow(
            title: 'Current location',
            onTap: () {
              print('On Click');
            })));*/

    /* geofenceArea.add(Circle(
        center: ltlng,
        radius: 100.0,
        fillColor: Colors.red.shade100.withOpacity(0.8),
        strokeColor: Colors.red.shade100.withOpacity(0.2),
        strokeWidth: 2,
        circleId: CircleId('Area 1')));*/

    /*  await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: ltlng, zoom: _zoomLevel)));*/

    /*  final address =
        await _getAddressFromCoordinates(ltlng.latitude, ltlng.longitude);
    print('Address $address');
    _addressTextController.text = address ?? 'Not known';*/

    /* GeoFenceModel.startGeofence(
        pointedLatitude: ltlng.latitude,
        pointedLongitude: ltlng.longitude,
        radius: 100,
        eventPeriodInSecs: 1500);

    GeoFenceModel.geoStream?.listen((event) {

      _getAddressFromCoordinates(event.latitude!, event.longitude!);
      _withinGpsRegion = (event.event == GeofenceEvent.enter) ? true : false;
      print('GEO Event ${event.event} within GPS region $_withinGpsRegion');
    });*/

    await controller
        .animateCamera(CameraUpdate.newCameraPosition(_initialCameraPos));
    setState(() {});
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    final addressList =
        await GeocodingPlatform.instance.placemarkFromCoordinates(lat, lng);

    final firstAddress = addressList.firstWhere((placement) =>
        placement.street != null &&
        placement.subLocality != null &&
        placement.postalCode != null);

    _currentAddress =
        '${firstAddress.locality} ${firstAddress.street}, ${firstAddress.subLocality}, ${firstAddress.postalCode}';
    setState(() {
      _addressTextController.text = _currentAddress ?? 'Not Known';
    });
  }

  void markAttendance() async {
    final res = await _datebaseHelper.upsertUserAttendance(
        UserAttendance(attendanceId: const Uuid().v6(), userId: user!.userId),
        currentLocation: _addressTextController.text);

    setState(() {});

    if (res > 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Attendance marked successfully'),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 1500),
      ));
      Navigator.of(context).pop(STATUS_CODE_OK);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Attendance marked failure'),
        backgroundColor: Colors.red,
        duration: Duration(milliseconds: 1500),
      ));
    }
  }

  @override
  void dispose() {
    GeoFenceModel.stopGeofence();
    super.dispose();
  }
}
