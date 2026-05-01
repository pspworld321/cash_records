import 'dart:io';

import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import 'global.dart';
import 'main.dart';

class DriveSync {
  var _scopes = [ga.DriveApi.driveAppdataScope, 'email'];
  ga.DriveApi? authDrive;

  late GoogleSignIn _googleSignIn;

  DriveSync() {
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
    );
  }

  Future<void> restoreSession() async {
    try {
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account != null) {
        await _setupDriveApi(account);
      }
    } catch (e) {
      print("Error restoring session: $e");
    }
  }

  Future<void> _setupDriveApi(GoogleSignInAccount account) async {
    try {
      var authClient = await _googleSignIn.authenticatedClient();
      if (authClient != null) {
        authDrive = ga.DriveApi(authClient);

        MyHomePageState.email = account.email;
        await Global.settingsBox.put('userEmail', account.email);

        checkForBackup();
        Global.loggedIn = true;
        MyHomePageState.backupNotifier.value++;
      }
    } catch (e) {
      print("Error setting up Drive API: $e");
    }
  }

  authenticateDrive() async {
    try {
      GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        await _setupDriveApi(account);
      }
    } catch (e) {
      print("Error authenticating Drive: $e");
    }
  }

  authenticate() async {
    if (authDrive == null) {
      await authenticateDrive();
    }
  }

  uploadBackup() async {
    MyHomePageState.uploadingBackup = true;
    MyHomePageState.backupNotifier.value++;
    print('upload backup');
    await authenticate();
    var encoder = ZipFileEncoder();
    var zipPath = await Global.getDataDirectoryPath() + '/cashRecordsBackup.zip';
    encoder.create(zipPath);
    Directory dir = Directory(await Global.getDataDirectoryPath() + '/');
    List files = await dir.list().toList();
    files.forEach((file) {
      if (file.path.contains('.hive') && !file.path.contains('settings.hive')) {
        print(file.path);
        encoder.addFile(file);
      }
    });
    encoder.close();
    try {
      var query = '''mimeType = "application/zip"
           and trashed = false and name = "cashRecordsBackup"''';
      ga.FileList listMap =
          await authDrive!.files.list(spaces: 'appDataFolder', q: query, orderBy: 'modifiedTime', $fields: 'files(id,name,modifiedTime)');
     late ga.File responseFile;
      ga.File fileToUpload = ga.File();
      fileToUpload.name = 'cashRecordsBackup';
      fileToUpload.mimeType = 'application/zip';

      File zipFile = File(zipPath);
      if (listMap.files != null && listMap.files!.length > 0) {
        responseFile = await authDrive!.files.update(fileToUpload, listMap.files![listMap.files!.length - 1].id.toString(),
            addParents: 'appDataFolder', uploadMedia: ga.Media(zipFile.openRead(), await File(zipPath).length()), $fields: 'modifiedTime,id');
      } else if (listMap.files != null && listMap.files!.length == 0) {
        fileToUpload.parents = ['appDataFolder'];
        responseFile = await authDrive!.files
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
    //check for backup to restore
    try {
      var query = '''mimeType = "application/zip"
           and trashed = false and name = "cashRecordsBackup"''';
      ga.FileList listMap =
          await authDrive!.files.list(spaces: 'appDataFolder', q: query, orderBy: 'modifiedTime', $fields: 'files(id,name,modifiedTime)');
      print(listMap.files);
      if (listMap.files != null && listMap.files!.isNotEmpty) {
        ga.Media? file = (await authDrive!.files.get(listMap.files!.last.id.toString(), downloadOptions: ga.DownloadOptions.fullMedia)) as ga.Media?;
        List<int> dataStore = [];
        file!.stream.listen((data) {
          dataStore.addAll(data);
        }, onDone: () async {
          var pth = await Global.getDataDirectoryPath() + '/';
          final archive = ZipDecoder().decodeBytes(dataStore);

          List<Future> writeFutures = [];
          for (final file in archive) {
            final filename = file.name;
            final data = file.content as List<int>;

            writeFutures.add(() async {
               var f = File(pth + filename);
               await f.create(recursive: true);
               await f.writeAsBytes(data);
            }());
          }

          await Future.wait(writeFutures);

          print('done restoring backup');
          await Hive.close();
          Global.settingsBox = await Hive.openBox('settings');
          Global.brandInfoBox = await Hive.openBox('brandInfoBox');
          Navigator.of(MyHomePageState.cntxtOfRestoreProgressDialog).pop();
          runApp(MyApp());
        });
      } else {
        print('no backup found');
        Navigator.of(MyHomePageState.cntxtOfRestoreProgressDialog).pop();
        showToast('No backup found',context: MyHomePageState.ctx);
      }
    } catch (e, s) {
      print('error restoring backup');
      Navigator.of(MyHomePageState.cntxtOfRestoreProgressDialog).pop();
      showToast('Error restoring backup',context: MyHomePageState.ctx);
      print(e.toString() + s.toString());
    }
  }

  checkForBackup() async {
    Global.checkingBackup = true;
    MyHomePageState.backupNotifier.value++;
    print('checkForBackup : ');
    //check for backup and get date
    try {
      var query = '''mimeType = "application/zip"
           and trashed = false and name = "cashRecordsBackup"''';
      ga.FileList listMap =
          await authDrive!.files.list(spaces: 'appDataFolder', q: query, orderBy: 'modifiedTime', $fields: 'files(id,name,modifiedTime)');
      print(listMap.files);
      if (listMap.files != null && listMap.files!.length > 0) {
        final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');
        String lastBackup = formatter.format(listMap.files![listMap.files!.length - 1].modifiedTime!.toLocal());
        print('backup found');
        print(lastBackup);
        await Global.settingsBox.put('backupDate', listMap.files![listMap.files!.length - 1].modifiedTime!.toLocal());
      } else {
        print('no backup found');
      }
    } catch (e, s) {
      print('error checking backup');
    }

    Global.checkingBackup = false;
    MyHomePageState.backupNotifier.value++;
  }

  clearCredentials() async {
    await _googleSignIn.signOut();
    await Global.settingsBox.delete('userEmail');
    authDrive = null;
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
