import 'package:json_annotation/json_annotation.dart';

part 'user_attendance.g.dart';

@JsonSerializable()
class UserAttendance {
  @JsonKey(name: 'attendanceId')
  String? attendanceId;

  @JsonKey(name: 'in_time', includeIfNull: false)
  String? clockInTime;

  @JsonKey(name: 'out_time', includeIfNull: false)
  String? clockOutTime;

  @JsonKey(name: 'check_in_status', defaultValue: 0)
  int? checkInStatus;

  @JsonKey(name: 'check_out_status', defaultValue: 0)
  int? checkOutStatus;

  @JsonKey(name: 'check_in_date', includeIfNull: false)
  String? checkInDate;

  @JsonKey(name: 'check_out_date', includeIfNull: false)
  String? checkOutDate;

  @JsonKey(name: 'userId')
  String? userId;

  @JsonKey(name: 'in_address')
  String? checkInAddress;
  @JsonKey(name: 'out_address')
  String? checkOutAddress;

  UserAttendance(
      {required this.attendanceId,
      this.clockInTime,
      this.clockOutTime,
      this.checkInStatus,
      this.checkOutStatus,
      this.checkInDate,
      this.checkOutDate,
      required this.userId});

  // Add this factory method to create an instance from a JSON map
  factory UserAttendance.fromJson(Map<String, dynamic> json) =>
      _$UserAttendanceFromJson(json);

  // Add this method to convert the instance to a JSON map
  Map<String, dynamic> toJson() => _$UserAttendanceToJson(this);

  @override
  String toString() {
    return 'UserAttendance{attendanceId: $attendanceId, clockInTime: $clockInTime, clockOutTime: $clockOutTime, checkInStatus: $checkInStatus, checkOutStatus: $checkOutStatus, checkInDate: $checkInDate, checkOutDate: $checkOutDate, userId: $userId, checkInAddress: $checkInAddress, checkOutAddress: $checkOutAddress}';
  }
}
