import 'dart:io';

import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:googleapis_auth/auth_io.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import 'global.dart';
import 'main.dart';

class DriveSync {
  var authDrive;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.appdata',
      'https://www.googleapis.com/auth/userinfo.email',
    ],
  );

  authenticateDrive() async {
    try {
      GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        var authClient = await _googleSignIn.authenticatedClient();
        if (authClient != null) {
          authDrive = ga.DriveApi(authClient);
          MyHomePageState.email = account.email;
          await Global.settingsBox.put('userEmail', account.email);
          checkForBackup();
          Global.loggedIn = true;
          MyHomePageState.backupNotifier.value++;
        }
      }
    } catch (error) {
      print(error);
    }
  }

  refreshTheToken() async {
    // google_sign_in handles token refresh automatically
  }

  authenticate() async {
    bool isSigned = await _googleSignIn.isSignedIn();
    if (isSigned) {
      // Must call signInSilently to restore session state fully
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account != null) {
        var authClient = await _googleSignIn.authenticatedClient();
        if (authClient != null) {
          authDrive = ga.DriveApi(authClient);
          Global.loggedIn = true;
        } else {
          await authenticateDrive();
        }
      } else {
        await authenticateDrive();
      }
    } else {
      await authenticateDrive();
    }
  }

  uploadBackup() async {
    MyHomePageState.uploadingBackup = true;
    MyHomePageState.backupNotifier.value++;
    print('upload backup');
    await authenticate();
    if (authDrive == null) {
        MyHomePageState.uploadingBackup = false;
        MyHomePageState.backupNotifier.value++;
        return;
    }
    var encoder = ZipFileEncoder();
    var zipPath = await Global.getDataDirectoryPath() + '/cashRecordsBackup.zip';
    encoder.create(zipPath);
    Directory dir = Directory(await Global.getDataDirectoryPath() + '/');
    List files = await dir.list().toList();
    for (var file in files) {
      if (file.path.contains('.hive') && !file.path.contains('settings.hive')) {
        print(file.path);
        encoder.addFile(file as File);
      }
    }
    encoder.close();
    try {
      var query = '''mimeType = "application/zip"
           and trashed = false and name = "cashRecordsBackup"''';
      ga.FileList listMap =
          await authDrive.files.list(spaces: 'appDataFolder', q: query, orderBy: 'modifiedTime', $fields: 'files(id,name,modifiedTime)');
     late ga.File responseFile;
      ga.File fileToUpload = ga.File();
      fileToUpload.name = 'cashRecordsBackup';
      fileToUpload.mimeType = 'application/zip';

      File zipFile = File(zipPath);
      if (listMap.files != null && listMap.files!.isNotEmpty) {
        responseFile = await authDrive.files.update(fileToUpload, listMap.files![listMap.files!.length - 1].id.toString(),
            addParents: 'appDataFolder', uploadMedia: ga.Media(zipFile.openRead(), await File(zipPath).length()), $fields: 'modifiedTime,id');
      } else if (listMap.files != null && listMap.files!.isEmpty) {
        fileToUpload.parents = ['appDataFolder'];
        responseFile = await authDrive.files
            .create(fileToUpload, uploadMedia: ga.Media(zipFile.openRead(), await File(zipPath).length()), $fields: 'modifiedTime,id');
      }
      print(responseFile.id.toString());
      if (responseFile.id != null) {
        await Global.settingsBox.put('backupDate', responseFile.modifiedTime!.toLocal());
      }
      print('Backup Uploaded');
      // showToast('Backup Uploaded');
      MyHomePageState.uploadingBackup = false;
      MyHomePageState.backupNotifier.value++;
    } catch (e, s) {
      //showToast('error uploading backup');
      print('error uploading backup');
      print(e.toString() + s.toString());
    }
  }

  restoreBackup() async {
    print('restore : ');
    await authenticate();
    if (authDrive == null) {
      Navigator.of(MyHomePageState.cntxtOfRestoreProgressDialog).pop();
      showToast('Authentication failed',context: MyHomePageState.ctx);
      return;
    }
    //check for backup to restore
    try {
      var query = '''mimeType = "application/zip"
           and trashed = false and name = "cashRecordsBackup"''';
      ga.FileList listMap =
          await authDrive.files.list(spaces: 'appDataFolder', q: query, orderBy: 'modifiedTime', $fields: 'files(id,name,modifiedTime)');
      print(listMap.files);
      if (listMap.files != null && listMap.files!.isNotEmpty) {
        ga.Media? file = (await authDrive.files.get(listMap.files![listMap.files!.length - 1].id.toString(), downloadOptions: ga.DownloadOptions.fullMedia)) as ga.Media?;
        List<int> dataStore = [];
        file!.stream.listen((data) {
          dataStore.insertAll(dataStore.length, data);
        }, onDone: () async {
          // print('onDone : restoreBackup');
          var pth = await Global.getDataDirectoryPath() + '/';
          final archive = ZipDecoder().decodeBytes(dataStore);
          // Extract the contents of the Zip archive to disk.
          for (final file in archive) {
            final filename = file.name;
            final data = file.content as List<int>;
            File(pth + filename)
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          }
          print('done restoring backup');
          await Hive.close();
          Global.settingsBox = await Hive.openBox('settings');
          Global.brandInfoBox = await Hive.openBox('brandInfoBox');
          Navigator.of(MyHomePageState.cntxtOfRestoreProgressDialog).pop();
          runApp(MyApp());

          // print('result from driveSync : ${MyHomePageState.restoreBackupResult}');
          // showToast('Backup restored!');
          // MyHomePageState.backupNotifier.value++;
        });
      } else {
        print('no backup found');
        // MyHomePageState.restoreBackupResult ='No backup found';
        Navigator.of(MyHomePageState.cntxtOfRestoreProgressDialog).pop();
        showToast('No backup found',context: MyHomePageState.ctx);
      }
    } catch (e, s) {
      print('error restoring backup');
      // MyHomePageState.restoreBackupResult ='Error restoring backup';
      Navigator.of(MyHomePageState.cntxtOfRestoreProgressDialog).pop();
      showToast('Error restoring backup',context: MyHomePageState.ctx);
      print(e.toString() + s.toString());
    }
  }

  checkForBackup() async {
    Global.checkingBackup = true;
    MyHomePageState.backupNotifier.value++;
    print('checkForBackup : ');
    if (authDrive == null) {
      Global.checkingBackup = false;
      MyHomePageState.backupNotifier.value++;
      return;
    }
    //check for backup and get date
    try {
      var query = '''mimeType = "application/zip"
           and trashed = false and name = "cashRecordsBackup"''';
      ga.FileList listMap =
          await authDrive.files.list(spaces: 'appDataFolder', q: query, orderBy: 'modifiedTime', $fields: 'files(id,name,modifiedTime)');
      print(listMap.files);
      if (listMap.files != null && listMap.files!.isNotEmpty) {
        final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');
        String lastBackup = formatter.format(listMap.files![listMap.files!.length - 1].modifiedTime!.toLocal());
        print('backup found');
        print(lastBackup);
        await Global.settingsBox.put('backupDate', listMap.files![listMap.files!.length - 1].modifiedTime!.toLocal());
        // return lastBackup;
      } else {
        print('no backup found');
        // return 'Never';
      }
    } catch (e, s) {
      print('error checking backup');
      //return 'Error';
    }

    Global.checkingBackup = false;
    MyHomePageState.backupNotifier.value++;
  }

  saveCredentials(AccessToken token, String refreshToken) async {
    // google_sign_in handles this automatically
  }

  getCredentials() async {
    if (await _googleSignIn.isSignedIn()) {
      return {'signed_in': true};
    }
    return null;
  }

  clearCredentials() async {
    await _googleSignIn.disconnect();
    await Future.delayed(Duration(milliseconds: 100));
    Global.loggedIn = false;
    MyHomePageState.backupNotifier.value++;
  }

  Future<void> backupAtAppClose() async {
    if (Global.loggedIn) {
      var intervalIndex = await Global.settingsBox.get('backupInterval');
      var backupDate = await Global.settingsBox.get('backupDate');
      if (Global.listBackupInterval[intervalIndex] == Global.listBackupInterval[0]) {
        if (backupDate == null || DateTime.now().difference(backupDate).inHours > 24) {
          uploadBackup();
        }
      }

      if (Global.listBackupInterval[intervalIndex] == Global.listBackupInterval[1]) {
        if (backupDate == null || DateTime.now().difference(backupDate).inHours > 24 * 7) {
          uploadBackup();
        }
      }

      if (Global.listBackupInterval[intervalIndex] == Global.listBackupInterval[2]) {
        uploadBackup();
      }
    }
  }
}
