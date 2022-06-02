import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'driveSync.dart';

class Backup extends StatefulWidget {
  @override
  BackupState createState() => BackupState();
}

class BackupState extends State<Backup> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Backup'),
        ),
        body: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(30),
              child: Text(
                'Please sign in with google account to backup your data on Google Drive.',
                style: TextStyle(fontSize: 17),
                textAlign: TextAlign.center,
              ),
            ),
            GestureDetector(
                onTap: () {
                  var driveSync = DriveSync();
                  driveSync.authenticate();
                },
                child: Container(
                  padding: EdgeInsets.all(0),
                  color: Colors.blue,
                  width: 230,
                  alignment: Alignment.centerLeft,
                  child: ListTile(
                    contentPadding: EdgeInsets.fromLTRB(3, 0, 0, 0),
                    leading: Image.asset(
                      'assets/GLogo.jpg',
                      height: 50,
                      width: 50,
                    ),
                    title: Text('Sign In with Google', style: TextStyle(fontSize: 17, color: Colors.white)),
                  ),
                )),
            Container(
              height: 200,
            )
          ],
        ))

        // Flex(
        //   direction: Axis.vertical,
        //   children: [
        //     Expanded(
        //       flex: 1,
        //       child: ,
        //     )
        //   ],
        // ),
        );
  }
}
