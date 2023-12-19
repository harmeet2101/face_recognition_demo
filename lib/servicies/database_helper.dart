import 'package:face_recognition_demo/model/User.dart';
import 'package:face_recognition_demo/model/user_attendance.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

class DatebaseHelper {
  final String _dbName = 'ml.db';
  final int _dbVersion = 3;

  final String _dbUsersTable = 'users';
  final String _dbColumnUserId = 'userId';
  final String _dbColumnName = 'username';
  final String _dbColumnPassword = 'password';
  final String _dbColumnEmail = 'email';
  final String _dbColumnDept = 'dept';
  final String _dbColumnUserModel = 'userModel';

  final String _dbAttendanceTable = 'users_attendance';
  final String _dbColumnAttendanceId = 'attendanceId';
  final String _dbColumnClockInTime = 'in_time';
  final String _dbColumnClockOutTime = 'out_time';
  final String _dbColumnClockInDate = 'check_in_date';
  final String _dbColumnClockOutDate = 'check_out_date';
  final String _dbColumnCheckInStatus = 'check_in_status';
  final String _dbColumnCheckOutStatus = 'check_out_status';
  final String _dbColumnInAddress = 'in_address';
  final String _dbColumnOutAddress = 'out_address';

  DatebaseHelper._privateConstructor();
  static final DatebaseHelper instance = DatebaseHelper._privateConstructor();

  late Database _database;
  Future<Database> get database async {
    _database = await initailize();
    return _database;
  }

  Future<Database> initailize() async {
    final directotyPath = await getApplicationDocumentsDirectory();
    final dbPath = join(directotyPath.path, _dbName);
    _database = await openDatabase(dbPath, version: _dbVersion,
        onCreate: (Database db, int ver) {
      createTables(db);
    }, onConfigure: (Database db) {
      db.execute('PRAGMA foreign_keys = ON');
    }, onUpgrade: (Database db, int oldVer, int newVer) {});
    return _database;
  }

  Future<void> createTables(Database db) async {
    await db.execute(
        'create table $_dbUsersTable ($_dbColumnUserId TEXT PRIMARY KEY NOT NULL,$_dbColumnName TEXT NOT NULL,$_dbColumnPassword TEXT NOT NULL,$_dbColumnUserModel TEXT NOT NULL,$_dbColumnEmail TEXT, $_dbColumnDept TEXT)');
    await db.execute(
        'create table $_dbAttendanceTable ($_dbColumnAttendanceId TEXT PRIMARY KEY NOT NULL,'
        '$_dbColumnClockInDate TEXT,'
        '$_dbColumnClockInTime TEXT,'
        '$_dbColumnInAddress TEXT,'
        '$_dbColumnClockOutDate TEXT,'
        '$_dbColumnClockOutTime TEXT,'
        '$_dbColumnOutAddress TEXT,'
        '$_dbColumnCheckInStatus INTEGER ,'
        '$_dbColumnCheckOutStatus INTEGER ,'
        '$_dbColumnUserId TEXT NOT NULL,'
        ' FOREIGN KEY ($_dbColumnUserId) REFERENCES $_dbUsersTable ($_dbColumnUserId))');
  }

  Future<int> insertUser(User user) async {
    final res = await _database.insert(_dbUsersTable, user.toJson());
    print('Res $res');
    return res;
  }

  Future<int> upsertUserAttendance(UserAttendance attendance,
      {required String? currentLocation}) async {
    int res;
    final currentDateTime = DateTime.now();
    final formattedDate = DateFormat('dd-MM-yyyy').format(currentDateTime);
    List<Map<String, dynamic>> rawList = await _database.query(
        _dbAttendanceTable,
        where:
            '$_dbColumnCheckInStatus=? and $_dbColumnCheckOutStatus=? and $_dbColumnClockInDate=? and $_dbColumnUserId=?',
        whereArgs: [1, 0, formattedDate, attendance.userId]);

    final formattedTime =
        DateFormat('hh:mm:ss a').format(currentDateTime); //hh:mm:ss a

    if (rawList.isEmpty) {
      attendance.clockInTime = formattedTime;
      attendance.checkInStatus = 1;
      attendance.checkOutStatus = 0;
      attendance.checkInDate = formattedDate;
      attendance.checkInAddress = currentLocation!;

      return await _database.insert(_dbAttendanceTable, attendance.toJson());
    } else {
      attendance.checkOutDate = formattedDate;
      attendance.clockOutTime = formattedTime;
      attendance.checkOutStatus = 1;

      attendance.checkInStatus = 1;
      attendance.clockInTime = rawList[0][_dbColumnClockInTime];
      attendance.checkInDate = rawList[0][_dbColumnClockInDate];

      attendance.checkOutAddress = currentLocation!;
      attendance.checkInAddress = rawList[0][_dbColumnInAddress];
      attendance.attendanceId = rawList[0][_dbColumnAttendanceId];

      return await _database.update(_dbAttendanceTable, attendance.toJson(),
          where: '$_dbColumnAttendanceId=?',
          whereArgs: [rawList[0][_dbColumnAttendanceId]]);
    }
  }

  Future<List<User>> getAllUsers() async {
    List<Map<String, dynamic>> rawList = await _database.query(_dbUsersTable);
    return rawList.map((user) => User.fromJson(user)).toList();
  }

  Future<int?> getUserAttendance(String? userId) async {
    if (userId == null) return null;

    final res = await _database.query(
      _dbAttendanceTable,
      where: 'check_out_status =? and '
          'check_in_status =? and userId =?',
      whereArgs: [0, 1, userId],
    );

    final status = UserAttendance.fromJson(res.lastWhere(
        (element) => element[_dbColumnCheckOutStatus] == 0,
        orElse: () => {}));
    return status.attendanceId == null ? 0 : 1;
  }

  Future<UserAttendance?> getUserAttendance2(String? userId) async {
    if (userId == null) return null;

    final res = await _database.query(
      _dbAttendanceTable,
      where: 'check_out_status =? and '
          'check_in_status =? and userId =?',
      whereArgs: [0, 1, userId],
    );

    return UserAttendance.fromJson(res.lastWhere(
        (element) => element[_dbColumnCheckOutStatus] == 0,
        orElse: () => {}));
  }

  Future<List<UserAttendance>?> getUserWholeAttendance(String? userId) async {
    if (userId == null) return null;

    final res = await _database.query(
      _dbAttendanceTable,
      where: 'userId =?',
      whereArgs: [userId],
    );

    return res
        .map((attendance) => UserAttendance.fromJson(attendance))
        .toList();
  }

  Future<User?> getUser(String userId) async {
    List<Map<String, dynamic>> rawList = await _database
        .query(_dbUsersTable, where: '$_dbColumnUserId=?', whereArgs: [userId]);

    return User.fromJson(rawList[0]);
  }

  Future<bool>? removeUser(String userId) async {
    final res = await _database.delete(_dbUsersTable,
        where: '$_dbColumnUserId=?', whereArgs: [userId]);
    return res > 0 ? true : false;
  }

  Future<bool>? removeAllUsers() async {
    return await _database.rawDelete('delete from $_dbUsersTable') > 0
        ? true
        : false;
  }

  Future<void> get dispose async => await _database.close();
}
