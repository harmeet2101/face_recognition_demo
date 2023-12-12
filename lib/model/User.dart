import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'User.g.dart';

String? _encode(List<dynamic>? ls) => ls == null ? null : jsonEncode(ls);
List<dynamic> _decode(String? key) => key == null ? null : jsonDecode(key);

@JsonSerializable()
class User {
  String? userId;
  String? username;
  String? password;
  String? email;
  String? dept;
  @JsonKey(toJson: _encode, fromJson: _decode)
  List<dynamic>? userModel;

  User(
      {this.userId,
      this.username,
      this.password,
      this.email,
      this.userModel,
      this.dept});

  /* static Map<String, dynamic> userToMap(User user) => {
        'username': user.username ?? '',
        'password': user.password ?? '',
        'email':user.email??'',
        'dept':user.dept?? '',
        'userModel': jsonEncode(user.userModel)
      };

  static User fromMap(Map<String, dynamic> map) => User(
        userId: map['userId'],
        username: map['username'],
        password: map['password'],
        email: map['email'],
        dept: map['dept'],
        userModel: jsonDecode(map['userModel'])
      );*/

  // Add this factory method to create an instance from a JSON map
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  // Add this method to convert the instance to a JSON map
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  String toString() {
    return 'User{userId: $userId, username: $username, password: $password, email: $email ,dept: $dept userModel: $userModel}';
  }
}
