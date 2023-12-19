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

import 'package:uuid/uuid.dart';

class CheckInOutScreen extends StatefulWidget {
  final String appBarTitle;

  const CheckInOutScreen({required this.appBarTitle, super.key});

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

  final DatebaseHelper _datebaseHelper = DatebaseHelper.instance;

  final GeoFenceModel _geoFenceModel = GeoFenceModel();
  bool start = false;

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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: Column(
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
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Within Geofence Area'),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 0.5),
                            color: _withinGpsRegion == null
                                ? Colors.grey
                                : (_withinGpsRegion!
                                    ? Colors.green
                                    : Colors.red)),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 0.6),
                shape: BoxShape.rectangle,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
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
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              '** Long press on map to add Geofence area **',
              style: TextStyle(color: Colors.red, fontSize: 16.0),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              '** User round button to start/stop Geofencing **',
              style: TextStyle(color: Colors.red, fontSize: 16.0),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: Container(
              height: 0.5,
              color: Colors.black38,
            ),
          ),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
              child: SizedBox(
                //   width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    markAttendance();
                  },
                  child: const Text('Done'),
                ),
              ))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.indigo,
          onPressed: () async {
            if (!start) {
              startMonitoring();
            } else {
              stopMonitoring();
            }

          },
          elevation: 10.0,
          child: Text(
            !start ? 'Start' : 'Stop',
            softWrap: true,
          )),
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

  void addGeofenceArea(LatLng? position, {double radius = 200.00}) async {
    if (position == null) return;

    geofenceArea.clear();
    _geoFenceModel.stopGeofence();

    if (start) {
      start = false;
      _withinGpsRegion = null;
    }

    Circle circle = Circle(
        center: position,
        radius: radius,
        fillColor: Colors.red.shade100.withOpacity(0.8),
        strokeColor: Colors.red.shade100.withOpacity(0.2),
        strokeWidth: 2,
        circleId: const CircleId('Business Unit'));
    geofenceArea.add(circle);

    setState(() {});

    await Future.delayed(const Duration(milliseconds: 300), () {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Geofencing area added'),
        backgroundColor: Colors.green,
      ));
    });
  }

  void startMonitoring() async {
    if (geofenceArea.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300), () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add Geofenc area first'),
          backgroundColor: Colors.red,
        ));
      });
      return;

    }

    start = !start;
    setState(() {});

    _geoFenceModel.startGeofence(
        pointedLatitude: geofenceArea.first.center.latitude,
        pointedLongitude: geofenceArea.first.center.longitude,
        radius: geofenceArea.first.radius,
        eventPeriodInSecs: 1000);

    final subs = _geoFenceModel.geoStream?.listen((event) {
      _getAddressFromCoordinates(event.latitude!, event.longitude!);
      _withinGpsRegion = (event.event == GeofenceEvent.enter) ? true : false;
      print('GEO Event ${event.event} within GPS region $_withinGpsRegion');
    });
    _geoFenceModel.geoStreamSubc = subs!;

    await Future.delayed(const Duration(milliseconds: 1000), () {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Geofencing started'),
        backgroundColor: Colors.green,
      ));
    });
  }

  Future<void> _goTodiffLoc() async {
    final controller = await _mapController.future;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.appBarTitle} success'),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 1000),
      ));
      Navigator.of(context).pop(STATUS_CODE_OK);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.appBarTitle} failure'),
        backgroundColor: Colors.red,
        duration: const Duration(milliseconds: 1000),
      ));
    }
  }

  @override
  void dispose() {
    _geoFenceModel.stopGeofence();
    super.dispose();
  }

  void stopMonitoring() async {
    _geoFenceModel.stopGeofence();
    _withinGpsRegion = null;
    start = !start;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 1000), () {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Geofencing stopped'),
        backgroundColor: Colors.red,
      ));
    });
  }
}
