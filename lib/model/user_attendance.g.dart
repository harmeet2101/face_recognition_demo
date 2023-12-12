// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAttendance _$UserAttendanceFromJson(Map<String, dynamic> json) =>
    UserAttendance(
      attendanceId: json['attendanceId'] as String?,
      clockInTime: json['in_time'] as String?,
      clockOutTime: json['out_time'] as String?,
      checkInStatus: json['check_in_status'] as int? ?? 0,
      checkOutStatus: json['check_out_status'] as int? ?? 0,
      checkInDate: json['check_in_date'] as String?,
      checkOutDate: json['check_out_date'] as String?,
      userId: json['userId'] as String?,
    )
      ..checkInAddress = json['in_address'] as String?
      ..checkOutAddress = json['out_address'] as String?;

Map<String, dynamic> _$UserAttendanceToJson(UserAttendance instance) {
  final val = <String, dynamic>{
    'attendanceId': instance.attendanceId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('in_time', instance.clockInTime);
  writeNotNull('out_time', instance.clockOutTime);
  val['check_in_status'] = instance.checkInStatus;
  val['check_out_status'] = instance.checkOutStatus;
  writeNotNull('check_in_date', instance.checkInDate);
  writeNotNull('check_out_date', instance.checkOutDate);
  val['userId'] = instance.userId;
  val['in_address'] = instance.checkInAddress;
  val['out_address'] = instance.checkOutAddress;
  return val;
}
