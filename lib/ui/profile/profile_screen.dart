import 'package:face_recognition_demo/model/User.dart';
import 'package:face_recognition_demo/common/utils/shared__preferences.dart';
import 'package:face_recognition_demo/main.dart';
import 'package:face_recognition_demo/servicies/database_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const headingTextStyle = TextStyle(
  fontWeight: FontWeight.w400,
  fontSize: 18.0,
);
const subHeadingTextStyle = TextStyle(
  fontWeight: FontWeight.normal,
  fontSize: 16.0,
);

class ProfileScreen extends StatelessWidget {
  final User user;

  const ProfileScreen({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black54, width: 0.5)),
              child: Icon(Icons.person),
            ),
            const SizedBox(
              height: 60,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Username',
                  style: headingTextStyle,
                ),
                Text(
                  '${user.username}',
                  style: subHeadingTextStyle,
                )
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Email', style: headingTextStyle),
                Text(user.email ?? 'NA', style: subHeadingTextStyle)
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Department', style: headingTextStyle),
                Text(user.dept ?? 'NA', style: subHeadingTextStyle)
              ],
            ),
            const Spacer(),
            ElevatedButton(
                onPressed: () async {
                  final res = await PreferenceManager.instance.removeUser();
                  if (res) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('User removed successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(milliseconds: 1000),
                    ));
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LandingScreen()),
                        (route) => false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('User not removed'),
                      backgroundColor: Colors.red,
                      duration: Duration(milliseconds: 1000),
                    ));
                  }
                },
                child: const Text('Sign out')),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
                onPressed: () async {
                  final local = await PreferenceManager.instance.removeUser();
                  final dbClear =
                      await DatebaseHelper.instance.removeAllUsers();
                  if (local && dbClear!) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('All Data has been removed successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(milliseconds: 1000),
                    ));
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LandingScreen()),
                        (route) => false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Something went wrong'),
                      backgroundColor: Colors.red,
                      duration: Duration(milliseconds: 1000),
                    ));
                  }
                },
                child: const Text('Clear All Data')),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
