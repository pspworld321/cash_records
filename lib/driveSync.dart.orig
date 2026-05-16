import 'dart:convert';
import 'dart:io';
import 'package:flutter_web_browser/flutter_web_browser.dart';

import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:googleapis_auth/auth_io.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:googleapis/people/v1.dart' as ppl;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'global.dart';
import 'main.dart';

class DriveSync {
  var _clientId = "543807404983-d6c8gh2qpfk10tlf8ucnrl2md8ue7nci.apps.googleusercontent.com";
  var _scopes = ['https://www.googleapis.com/auth/drive.appdata', 'https://www.googleapis.com/auth/userinfo.email'];
  var  authDrive;

  // final InAppBrowser browser = new InAppBrowser();

  //Get Authenticated Http Client
  authenticateDrive() async {
    //Get Credentials
    var credentials = await getCredentials();
    if (credentials == null) {
      //Needs user authentication
      var authClient = await clientViaUserConsent(ClientId(_clientId, ''), _scopes, (url) async {
        //Open Url in Browser
        if (Platform.isAndroid) {
          // var options = InAppBrowserClassOptions(
          //     crossPlatform: InAppBrowserOptions(hideUrlBar: false),
          //     inAppWebViewGroupOptions: InAppWebViewGroupOptions(crossPlatform: InAppWebViewOptions(javaScriptEnabled: true)));
          // browser.openUrlRequest(urlRequest: URLRequest(url: Uri.parse(url)), options: options);

          FlutterWebBrowser.openWebPage(
              url: url,
              customTabsOptions: CustomTabsOptions(
                toolbarColor: Colors.lime,
              ));
        } else {
          launch(url);
        }
      });

      try {
        var url = Uri.parse('https://www.googleapis.com/oauth2/v1/userinfo?access_token=${authClient.credentials.accessToken.data}');
        var response = await http.get(url);
        Map responseMap = jsonDecode(response.body);
        MyHomePageState.email = responseMap['email'];
        await Global.settingsBox.put('userEmail', responseMap['email']);
        print(responseMap);
      } catch (e, s) {
        print(e);
        print(s);
      }

      authDrive = ga.DriveApi(authClient);
      await saveCredentials(authClient.credentials.accessToken, authClient.credentials.refreshToken.toString());
      checkForBackup();
      Global.loggedIn = true;
      MyHomePageState.backupNotifier.value++;
    } else {
      //Already authenticated
      await refreshTheToken();
      DateTime? dt = DateTime.tryParse(credentials["expiry"]);
      var authClient = authenticatedClient(
          http.Client(),
          AccessCredentials(AccessToken(credentials["type"], credentials['access_token'], dt!),
              credentials["refreshToken"], _scopes));

      authDrive = ga.DriveApi(authClient);
    }
  }

  refreshTheToken() async {
    var credentials = await Global.settingsBox.get('credentials');
    String refreshToken = credentials['refreshToken'];
    var url = Uri.parse('https://accounts.google.com/o/oauth2/token?client_id=$_clientId&refresh_token=$refreshToken&grant_type=refresh_token');
    var response = await http.post(url);
    Map responseMap = jsonDecode(response.body);
    //
    if (responseMap['access_token'] != null) {
      credentials['time_saved_at'] = DateTime.now().millisecondsSinceEpoch;
      credentials['access_token'] = responseMap['access_token'];
      await Global.settingsBox.put('credentials', credentials);
    } else {
      //print('error in refreshing token');
    }
    return responseMap;
  }

  authenticate() async {
    Map credentials = (await getCredentials()) ?? {};
    if (credentials == {} || authDrive == null || (DateTime.now().millisecondsSinceEpoch - credentials['time_saved_at']) > 3500000) {
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
          await authDrive.files.list(spaces: 'appDataFolder', q: query, orderBy: 'modifiedTime', $fields: 'files(id,name,modifiedTime)');
     late ga.File responseFile;
      ga.File fileToUpload = ga.File();
      fileToUpload.name = 'cashRecordsBackup';
      fileToUpload.mimeType = 'application/zip';

      File zipFile = File(zipPath);
      if (listMap.files != null && listMap.files!.length > 0) {
        responseFile = await authDrive.files.update(fileToUpload, listMap.files![listMap.files!.length - 1].id.toString(),
            addParents: 'appDataFolder', uploadMedia: ga.Media(zipFile.openRead(), await File(zipPath).length()), $fields: 'modifiedTime,id');
      } else if (listMap.files != null && listMap.files!.length == 0) {
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
    //check for backup to restore
    try {
      var query = '''mimeType = "application/zip"
           and trashed = false and name = "cashRecordsBackup"''';
      ga.FileList listMap =
          await authDrive.files.list(spaces: 'appDataFolder', q: query, orderBy: 'modifiedTime', $fields: 'files(id,name,modifiedTime)');
      print(listMap.files);
      if (listMap.files != null && listMap.files!.length > 0) {
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
    //check for backup and get date
    try {
      var query = '''mimeType = "application/zip"
           and trashed = false and name = "cashRecordsBackup"''';
      ga.FileList listMap =
          await authDrive.files.list(spaces: 'appDataFolder', q: query, orderBy: 'modifiedTime', $fields: 'files(id,name,modifiedTime)');
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
      //return 'Error';
    }

    Global.checkingBackup = false;
    MyHomePageState.backupNotifier.value++;
  }

  saveCredentials(AccessToken token, String refreshToken) async {
    await Global.settingsBox.put('credentials', {
      "type": token.type,
      'access_token': token.data,
      "expiry": token.expiry.toString(),
      "refreshToken": refreshToken,
      'time_saved_at': DateTime.now().millisecondsSinceEpoch
    });
    //browser.close();
  }

  getCredentials() async {
    var result = await Global.settingsBox.get('credentials');
    if (result == null || result.length == 0 || result['refreshToken'] == '' || result['refreshToken'] == null) {
      return null;
    }
    return result;
  }

  clearCredentials() async {
    await Global.settingsBox.delete('credentials');
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
