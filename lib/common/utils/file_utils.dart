import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../model/User.dart';

class FileUtils {
  static Future<File?> saveCapturedImage(String? path) async {
    if (path == null) return null;

    File imageFile = File(path);
    final currentMoment = DateTime.now();
    String stamp =
        '${currentMoment.year}${currentMoment.month}${currentMoment.day}_${currentMoment.hour}${currentMoment.minute}${currentMoment.second}';
    final directory = await getApplicationDocumentsDirectory();

    final fileFormat = imageFile.path.split('.').last;
    await imageFile.copy('${directory.path}/IMG_$stamp.$fileFormat');

    return imageFile;
  }

  static Future<bool> saveFile(User? user) async {
    if (user == null) return false;

    try {
      final directory = await getApplicationDocumentsDirectory();

      File file = File('${directory.path}/temp/user.txt');

      final encodedContent = jsonEncode({'user': user},
          toEncodable: (Object? value) => value is User
              ? value.toJson()
              : throw UnsupportedError('Cannot convert to JSON: $value'));
      file.writeAsString(encodedContent);

      return true;
    } on Exception catch (e) {
      print('Error while writing file $e');
      return false;
    }
  }
}
