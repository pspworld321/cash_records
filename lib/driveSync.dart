import 'dart:io';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import 'global.dart';
import 'main.dart';

class DriveSync {
  final _scopes = ['https://www.googleapis.com/auth/drive.appdata', 'https://www.googleapis.com/auth/userinfo.email'];

  var backupName = "cashRecordsBackup";

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  Future<void> handleSignInSilently() async {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account != null) {
        debugPrint('handleGoogleSignIn: onCurrentUserChanged');
        signInInit(account);
      }
    });
    await _googleSignIn.signInSilently();
  }

  Future<void> signInInit(GoogleSignInAccount? account) async {
    if (account == null) return;
    // print(account!.email);
    MyHomePageState.email = account.email;
    await Global.settingsBox.put('userEmail', account.email);

    final bool isAuthorized = await _googleSignIn.requestScopes(_scopes);
    if (isAuthorized) {
      Global.authClient = await _googleSignIn.authenticatedClient();
      Global.authDrive = ga.DriveApi(Global.authClient);
      checkForBackup();
      Global.loggedIn = true;
      MyHomePageState.backupNotifier.value++;
    }
  }

  Future<void> handleSignIn() async {
    try {
      await _googleSignIn.signIn();
      if (_googleSignIn.currentUser != null) {
        // print(_googleSignIn.currentUser!.email);
        signInInit(_googleSignIn.currentUser);
      }
    } catch (error) {
      print(error); // ignore: avoid_print
    }
  }

  Future<void> handleSignOut() async {
    await _googleSignIn.disconnect();
    await Global.settingsBox.delete('userEmail');
    await Future.delayed(Duration(milliseconds: 100));
    Global.loggedIn = false;
    MyHomePageState.backupNotifier.value++;
  }

  uploadBackup() async {
    MyHomePageState.uploadingBackup = true;
    MyHomePageState.backupNotifier.value++;
    print('upload backup');
    await handleSignInSilently();
    var encoder = ZipFileEncoder();
    var zipPath = await Global.getDataDirectoryPath() + '/$backupName.zip';
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
           and trashed = false and name = "$backupName"''';
      ga.FileList listMap =
      await Global.authDrive.files.list(spaces: 'appDataFolder', q: query, orderBy: 'modifiedTime', $fields: 'files(id,name,modifiedTime)');
      ga.File responseFile = new ga.File();
      ga.File fileToUpload = ga.File();
      fileToUpload.name = '$backupName';
      fileToUpload.mimeType = 'application/zip';

      File zipFile = File(zipPath);
      if (listMap.files != null && listMap.files!.length > 0) {
        responseFile = await Global.authDrive.files.update(fileToUpload, listMap.files![listMap.files!.length - 1].id.toString(),
            addParents: 'appDataFolder', uploadMedia: ga.Media(zipFile.openRead(), await File(zipPath).length()), $fields: 'modifiedTime,id');
      } else if (listMap.files != null && listMap.files!.length == 0) {
        fileToUpload.parents = ['appDataFolder'];
        responseFile = await Global.authDrive.files
            .create(fileToUpload, uploadMedia: ga.Media(zipFile.openRead(), await File(zipPath).length()), $fields: 'modifiedTime,id');
      }
      print(responseFile.id);
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

  restoreDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext cntxt6) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text('Current data (if any) will be replaced by backup restore...'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(cntxt6).pop();
                },
                child: Text('Cancel')),
            TextButton(
              child: Text('Restore'),
              onPressed: () async {
                var cntxt;
                Navigator.of(cntxt6).pop();
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (BuildContext cntxt12) {
                    cntxt = cntxt12;
                    return Dialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: EdgeInsets.fromLTRB(20, 30, 20, 20),
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator(),
                          ),
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Restoring Backup'),
                          )
                        ],
                      ),
                    );
                  },
                );
                await restoreBackup(cntxt);
                Navigator.of(cntxt).pop();
              },
            )
          ],
        );
      },
    );
  }

  restoreBackup(cntxt) async {
    print('restore : ');

    await handleSignInSilently();
    //check for backup to restore
    try {
      var query = '''mimeType = "application/zip"
           and trashed = false and name = "$backupName"''';
      ga.FileList listMap =
      await Global.authDrive.files.list(spaces: 'appDataFolder', q: query, orderBy: 'modifiedTime', $fields: 'files(id,name,modifiedTime)');
      print(listMap.files);
      if (listMap.files != null && listMap.files!.length > 0) {
        ga.Media file = (await Global.authDrive.files
            .get(listMap.files![listMap.files!.length - 1].id.toString(), downloadOptions: ga.DownloadOptions.fullMedia)) as ga.Media;
        List<int> dataStore = [];
        file.stream.listen((data) {
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
          // showToast('Backup restored!');
          // Future.delayed(Duration(microseconds: 100));
          runApp(MyApp());

          // print('result from driveSync : ${MyHomePageState.restoreBackupResult}');
          // MyHomePageState.backupNotifier.value++;
        });
      } else {
        print('no backup found');
        // MyHomePageState.restoreBackupResult ='No backup found';
        // showToast('No backup found');
      }
    } catch (e, s) {
      print('error restoring backup');
      print(e.toString() + s.toString());
      // MyHomePageState.restoreBackupResult ='Error restoring backup';
      // showToast('Error restoring backup');
    }
  }

  checkForBackup() async {
    Global.checkingBackup = true;
    MyHomePageState.backupNotifier.value++;
    print('checkForBackup : ');
    //check for backup and get date
    try {
      var query = '''mimeType = "application/zip"
           and trashed = false and name = "$backupName"''';
      ga.FileList listMap =
      await Global.authDrive.files.list(spaces: 'appDataFolder', q: query, orderBy: 'modifiedTime', $fields: 'files(id,name,modifiedTime)');
      print(listMap.files);
      if (listMap.files != null && listMap.files!.length > 0) {
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
      print(e.toString() + s.toString());
      //return 'Error';
    }

    Global.checkingBackup = false;
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
