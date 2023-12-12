import 'package:face_recognition_demo/check_in_out_screen.dart';
import 'package:face_recognition_demo/common/utils/shared__preferences.dart';
import 'package:face_recognition_demo/servicies/database_helper.dart';
import 'package:face_recognition_demo/ui/profile/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:face_recognition_demo/model/User.dart';

const int STATUS_CODE_OK = 200;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<StatefulWidget> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<User?> user;
  late User usr;
  final DatebaseHelper _dbHelper = DatebaseHelper.instance;
  int? status = 0;

  @override
  void initState() {


    user = PreferenceManager.instance.getUser().then((value) async {
      usr = value!;
      await _dbHelper.initailize();
      status = await _dbHelper.getUserAttendance(value.userId);
      return value;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home'), actions: [
        IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                        user: usr,
                      )));
            },
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
            ))
      ]),
      body: FutureBuilder<User?>(
          future: user,
          builder: (context, AsyncSnapshot<User?> snapshot) {
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(
                child: Text('Loading, please wait...'),
              );
            } else if (snapshot.hasData) {
              final usr = snapshot.data;
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 30, 0, 0),
                    child: Text(
                      'Welcome, ${usr?.username}',
                      style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Center(
                      child: ElevatedButton(
                          onPressed: () async {
                            final res = await Navigator.of(context).push<int>(
                              MaterialPageRoute(
                                  builder: (context) => CheckInOutScreen()),
                            );

                            if (res == STATUS_CODE_OK) {
                              status = await _dbHelper
                                  .getUserAttendance(usr!.userId);
                              setState(() {});
                            }
                          },
                          child: Text(status == 0 ? 'Check In' : 'Check Out')))
                ],
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }
}
