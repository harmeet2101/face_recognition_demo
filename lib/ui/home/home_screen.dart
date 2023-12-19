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
  String? lastLoggedInTime;

  @override
  void initState() {
    user = PreferenceManager.instance.getUser().then((value) async {
      usr = value!;
      print('UserId ${value.userId}');
      await _dbHelper.initailize();
      status = await _dbHelper.getUserAttendance(value.userId);
      if (status != null && status == 1) {
        final res = await _dbHelper.getUserAttendance2(value.userId);
        lastLoggedInTime = '${res?.checkInDate} ${res?.clockInTime}';
      }
      return value;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home'), actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                        user: usr,
                      )));
            }, // Handle your callback.
            splashColor: Colors.brown.withOpacity(0.5),
            child: Ink(
              height: 36,
              width: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/profile_image.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        )
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
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(30, 30, 0, 40),
                      child: Text(
                        'Welcome, ${usr?.username}',
                        style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    (status != null && status == 1)
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(30, 0, 0, 10),
                            child: Text(
                              'Last Log-in at: $lastLoggedInTime',
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.normal),
                            ),
                          )
                        : SizedBox.shrink(),
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 30),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final res = await Navigator.of(context).push<int>(
                                MaterialPageRoute(
                                    builder: (context) => CheckInOutScreen(
                                          appBarTitle: status == 0
                                              ? 'Check In'
                                              : 'Check Out',
                                        )),
                              );

                              if (res == STATUS_CODE_OK) {
                                status = await _dbHelper
                                    .getUserAttendance(usr!.userId);
                                if (status != null && status == 1) {
                                  final res2 = await _dbHelper
                                      .getUserAttendance2(usr!.userId);
                                  lastLoggedInTime =
                                      '${res2?.checkInDate} ${res2?.clockInTime}';
                                }

                                setState(() {});
                              }
                            },
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.lightGreen)),
                            child: Text(status == 0 ? 'Check In' : 'Check Out'),
                          ),
                        )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: () {},
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.lightGreen)),
                            child: const Text('View Attendance')),
                      ),
                    )
                  ]);
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }
}
