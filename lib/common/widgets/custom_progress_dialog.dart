import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomProgressDialog {
  String desc;
  bool dismissable;
  final BuildContext context;

  CustomProgressDialog(
      {required this.context,
      this.desc = 'Please wait...',
      this.dismissable = true});

  Future<void> show() async {
    return showDialog(
        context: context,
        barrierDismissible: dismissable,
        builder: (BuildContext context) {
          return WillPopScope(
              child: AlertDialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0))),
                backgroundColor: Colors.black87,
                content: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        desc,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              onWillPop: () async => false);
        });
  }

  hide() {
    Navigator.pop(context);
  }
}
