import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:face_recognition_demo/common/utils/image_utils.dart';
import 'package:face_recognition_demo/common/widgets/custom_progress_dialog.dart';
import 'package:face_recognition_demo/model/User.dart';
import 'package:face_recognition_demo/common/utils/shared__preferences.dart';
import 'package:face_recognition_demo/model/user_attendance.dart';
import 'package:face_recognition_demo/servicies/database_helper.dart';
import 'package:face_recognition_demo/servicies/face_detector_service.dart';
import 'package:face_recognition_demo/servicies/geo_fence_model.dart';
import 'package:face_recognition_demo/servicies/ml_service.dart';
import 'package:face_recognition_demo/servicies/models/camera_preview_model.dart';
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
import 'package:provider/provider.dart';

import 'package:uuid/uuid.dart';

import 'FacePainter.dart';

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

  late CameraController _cameraController;

  late final MLService _mlViewModel = context.read<MLService>();
  late final FaceDetectorService _faceDetectorService =
      context.read<FaceDetectorService>();

  late final CameraPreviewModel _cameraPreviewModel = CameraPreviewModel(
      faceDetectorService: _faceDetectorService, mlService: _mlViewModel);

  Future<List<CameraDescription>>? _cameraList;

  @override
  void initState() {
    setupMap();
    _cameraList = _availableCameras();
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

  Future<List<CameraDescription>> _availableCameras() async {
    final cameras = await availableCameras();

    if (cameras.isNotEmpty) {
      _cameraController = CameraController(cameras[1], ResolutionPreset.high);
      await _cameraController.initialize().then((value) {
        _cameraPreviewModel.cameraController = _cameraController;
        _cameraPreviewModel.startFaceDetection();
      }).onError((error, stackTrace) => throw Future.error('Error $error'));
    }

    return cameras;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
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
              ],
            ),
          ),
          Center(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 0.6),
                    shape: BoxShape.rectangle,
                  ),
                  child: FutureBuilder<List<CameraDescription>>(
                      future: _cameraList,
                      builder: (BuildContext context,
                          AsyncSnapshot<List<CameraDescription>> snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Something went wrong'),
                          );
                        } else if (snapshot.hasData) {
                          return Stack(fit: StackFit.expand, children: [
                            CameraPreview(_cameraController),
                            ChangeNotifierProvider.value(
                              value: _cameraPreviewModel,
                              builder: (context, _) {
                                final model =
                                    context.watch<CameraPreviewModel>();
                                final controller = context
                                    .watch<CameraPreviewModel>()
                                    .cameraController;
                                if (controller != null) {
                                  return CustomPaint(
                                    painter: FacePainter(
                                        face: model.faceDetected,
                                        imageSize: ImageUitls.getImageSize(
                                            controller)),
                                  );
                                } else {
                                  return Container();
                                }
                              },
                            ),
                            /*ChangeNotifierProvider.value(
                              value:
                              _cameraPreviewModel,
                              builder: (context, _) {
                                final value = context
                                    .watch<CameraPreviewModel>()
                                    .userFound;
                                if (value == null) {

                                  print('############### NO FACE DETECTED');

                                } else if (!value) {
                                  print('############### USER NOT FOUND');
                                } else {
                                  print('############### FACE DETECTED');
                                }

                                return SizedBox.shrink();
                              },
                            )*/
                          ]);
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      }),
                )),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 0.6),
                shape: BoxShape.rectangle,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.28,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Within Geofence area'),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 0.5),
                      color: _withinGpsRegion == null
                          ? Colors.grey
                          : (_withinGpsRegion! ? Colors.green : Colors.red)),
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 0, 5),
            child: Text(
              '*Long press on map to add Geofence area.',
              style: TextStyle(color: Colors.red, fontSize: 14.0),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 0, 10),
            child: Text(
              '*User round button to start/stop Geofencing.',
              style: TextStyle(color: Colors.red, fontSize: 14.0),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Container(
              height: 0.5,
              color: Colors.black38,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                //   width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    markAttendance();
                  },
                  child: const Text('Done'),
                ),
              ),
            ),
          ),
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
    CustomProgressDialog(context: context).show();

    final prediction = await _cameraPreviewModel.predict(checkInOut: true);

    if (prediction == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No face detected!'),
        backgroundColor: Colors.red,
        duration: Duration(milliseconds: 1000),
      ));
      CustomProgressDialog(context: context).hide();
      return;
    } else if (!prediction) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('User record not found'),
        duration: Duration(milliseconds: 1000),
        backgroundColor: Colors.red,
      ));
      CustomProgressDialog(context: context).hide();
      return;
    }

    final res = await _datebaseHelper.upsertUserAttendance(
        UserAttendance(attendanceId: const Uuid().v6(), userId: user!.userId),
        currentLocation: _addressTextController.text);

    CustomProgressDialog(context: context).hide();

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
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraPreviewModel.dispose();
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
