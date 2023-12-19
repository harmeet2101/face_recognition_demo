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
      body:Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20,horizontal: 30),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(color: Colors.black54, width: 1.0)),
              child: Image.asset('assets/images/avatar_default_image.jpeg',
                  fit: BoxFit.contain),
            ),
          ),
          const SizedBox(
            height: 60,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20,horizontal: 30),
            child: Column(
              children: [
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
              ],
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
            padding: const EdgeInsets.symmetric(vertical: 20,horizontal: 30),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () async {
                        final res = await PreferenceManager.instance.removeUser();
                        if (res) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('User Logged out successfully'),
                            backgroundColor: Colors.green,
                            duration: Duration(milliseconds: 1000),
                          ));
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LandingScreen()),
                                  (route) => false);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('User Logged out failure'),
                            backgroundColor: Colors.red,
                            duration: Duration(milliseconds: 1000),
                          ));
                        }
                      },
                      child: const Text('Sign out')),
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                              MaterialPageRoute(
                                  builder: (context) => LandingScreen()),
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
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
