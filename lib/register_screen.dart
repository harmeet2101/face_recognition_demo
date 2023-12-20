import 'dart:io';

import 'package:face_recognition_demo/model/User.dart';
import 'package:face_recognition_demo/common/utils/file_utils.dart';
import 'package:face_recognition_demo/common/utils/shared__preferences.dart';
import 'package:face_recognition_demo/servicies/ml_service.dart';
import 'package:face_recognition_demo/ui/home/home_screen.dart';
import 'package:flutter/material.dart';

import 'package:face_recognition_demo/servicies/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

const labelStyle = TextStyle(color: Colors.blue);

class RegisterFormWidget extends StatefulWidget {
  const RegisterFormWidget({Key? key, required this.picture}) : super(key: key);

  final File picture;

  @override
  State<RegisterFormWidget> createState() => _RegisterFormWidgetState();
}

class _RegisterFormWidgetState extends State<RegisterFormWidget> {
  late DatebaseHelper _datebaseHelper;
  late TextEditingController _nametextEditingController;
  late TextEditingController _passwordtextEditingController;
  late MLService _mlService;
  final FocusNode _nameTextFocusNode = FocusNode();
  final FocusNode _passTextFocusNode = FocusNode();

  @override
  void initState() {
    _datebaseHelper = DatebaseHelper.instance;
    _datebaseHelper.initailize();
    _nametextEditingController = TextEditingController();
    _passwordtextEditingController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Register')),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          border: Border.all(color: Colors.black54, width: 0.5),
                        ),
                        child: Image.file(
                          File(widget.picture.path),
                          fit: BoxFit.fill,
                          width: 170,
                          height: 170,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 40.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'Enter Name',
                        ),
                        controller: _nametextEditingController,
                        keyboardType: TextInputType.text,
                        focusNode: _nameTextFocusNode,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (value) {
                          FocusScope.of(context)
                              .requestFocus(_passTextFocusNode);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: TextFormField(
                        decoration:
                            const InputDecoration(hintText: 'Enter Password'),
                        controller: _passwordtextEditingController,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        focusNode: _passTextFocusNode,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (value) {
                          FocusScope.of(context)
                              .unfocus();
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: ElevatedButton(
                          onPressed: () {
                            _saveUserToDb();
                          },
                          child: const Text('Done')),
                    ),
                  ],
                )),
          );
        },
      ),
    );
  }

  void _saveUserToDb() async {
    if (_nametextEditingController.text.isEmpty ||
        _passwordtextEditingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Username & password fields are mandatory'),
        duration: Duration(milliseconds: 2000),
      ));
      return;
    }

    _mlService = Provider.of<MLService>(context, listen: false);
    List<dynamic> model = _mlService.predictedData;
    User user = User(
        userId: const Uuid().v6(),
        username: _nametextEditingController.text,
        password: _passwordtextEditingController.text,
        userModel: model);
    final res = await _datebaseHelper.insertUser(user);
    if (res > 0) {
      print('db insert success');
      _mlService.setPredictedData([]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User saved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 1000),
        ));
      }

      // saving registered emp to shared prefs;

      PreferenceManager.instance.saveUser(user);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User record not saved'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 1000),
        ));
      }
    }
  }
}
