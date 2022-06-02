import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:permission_handler/permission_handler.dart';

class Global {
  static var settingsBox;
  static var brandInfoBox;
  static String selectedFormField = fieldsForm[0];
  static var backgroundColor = Color.fromRGBO( 255, 255, 255, 1.0);
  static var mainCardColor = Color.fromRGBO( 254, 255, 249, 1.0);

  static bool loggedIn = false;

  static bool checkingBackup = false;

  static var iconColor = Color.fromRGBO(164, 167, 34, 1.0);

  static getTimeFromMillisEpoch(epoch) {
    DateTime dtTm = DateTime.fromMillisecondsSinceEpoch(int.parse(epoch));
    return (dtTm.hour.toString() + ':' + dtTm.minute.toString());
  }

  static getDateFromMillisEpoch(epoch) {
    DateTime dtTm = DateTime.fromMillisecondsSinceEpoch(int.parse(epoch));
    return (dtTm.day.toString() + '/' + dtTm.month.toString() + '/' + dtTm.year.toString());
  }

  static getDataDirectoryPath() async {
    if (Platform.isAndroid) {
      var directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } else if (Platform.isWindows) {
      var directory = await getApplicationSupportDirectory();
      return directory.path;
    }
  }

  static convertData() async {
    print('data conversion started');
    try {
      String path = await Global.getDataDirectoryPath() + '/profile0/data/';
      Directory dir = Directory(path);
      bool exists = await dir.exists();

      if (exists) {
        var dataBox = await Hive.openBox('dataBox');
        List dirs = await dir.list().toList();
        List<String> dirPaths = [];
        for (var dir in dirs) {
          dirPaths.add(dir.path);
        }
        dirPaths.sort();
        List allFiles = [];

        for (int i = 0; i < dirPaths.length; i++) {
          List files = await Directory(dirPaths[i]).list().toList();
          List<String> flPths = [];
          for (File f in files) {
            flPths.add(f.path);
          }
          flPths.sort();
          for (int j = 0; j < flPths.length; j++) {
            File file = File(flPths[j]);
            String text = await file.readAsString();
            Map fileMap = jsonDecode(text);
            allFiles.add(fileMap);
            dataBox.put(fileMap['id'], fileMap);
          }
        }

        // suggestions convert
        for (var suggFileName in suggestionsFilesList) {
          var boxS = await Hive.openBox(suggFileName);
          List list = [];
          String path = await getDataDirectoryPath() + '/profile0/suggestionData/$suggFileName.txt';
          File file = File(path);
          bool exists = await file.exists();
          if (exists) {
            list = await file.readAsLines();
            list.remove('');
            for (var sugg in list) {
              await boxS.put(DateTime.now().millisecondsSinceEpoch.toString(), sugg);
              await Future.delayed(Duration(milliseconds: 2));
            }
          }
        }
      }
      await settingsBox.put('dataConverted', true);
    } catch (e, s) {
      print(e);
      print(s);
    }

    print('data converted');
    return 'done';
  }

  static submitSuggData(text, fileName) async {
    if (text.trim() != '') {
      var boxS = await Hive.openBox(fileName);
        await boxS.put(DateTime.now().millisecondsSinceEpoch.toString(), text.trim());
    }
  }

  static suggestionFilter(text, fileName) async {
    var boxS = await Hive.openBox(fileName);
    List list = boxS.values.toList();
    list.removeWhere((element) => !element.toLowerCase().contains(text.toLowerCase()));
    return list;
  }

  static Future<void> deleteSuggData(selectedField, data, index) async {
    var boxS = await Hive.openBox(selectedField);
    Map map = boxS.toMap();
    map.removeWhere((key, value) => value.toLowerCase() == data.toLowerCase());
    await boxS.clear();
    boxS.putAll(map);
  }

  static List filteredList = [];
  static double inAmount = 0;
  static double outAmount = 0;
  static double totalAmount = 0;
  static String fromDate = '';
  static String toDate = '';

  static List suggestionsFilesList = [
    'in',
    'out'
  ];

  static List fieldsForm = ['In', 'Out'];
  static List fieldsIcons = [
    Icons.bar_chart,
    Icons.add_shopping_cart,
    Icons.home_work_rounded,
    Icons.account_box_outlined,
    Icons.workspaces_outline
  ];
  static List fieldsContent = ['ALL', 'IN', 'OUT'];
  static List listBackupInterval = ['Daily', 'Weekly', 'Every time on App Exit', 'Never'];
}

extension CapExtension on String {
  String get inCaps => this.length > 0 ? '${this[0].toUpperCase()}${this.substring(1).toLowerCase()}' : '';

  String get allInCaps => this.toUpperCase();

  String get capitalizeFirstofEach => this.replaceAll(RegExp(' +'), ' ').split(" ").map((str) => str.inCaps).join(" ");
}
