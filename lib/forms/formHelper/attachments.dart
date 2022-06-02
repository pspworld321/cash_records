import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class Attachments {
  static save(formContext, attachmentsMapsList, numberAttachList) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    final file = File(result!.files.single.path!);
    if (file != null) {
      //  print(result.path);

      showDialog(
        context: formContext,
        builder: (BuildContext cntxt) {
          TextEditingController attachNameController = TextEditingController();
          final attFormKey = GlobalKey<FormState>();
          return AlertDialog(
            backgroundColor: Colors.blueGrey.shade50,
            title: Text("Name this file"),
            content: Form(
                key: attFormKey,
                child: TextFormField(onFieldSubmitted: (v){
                  nameSubmit(attFormKey,attachNameController,attachmentsMapsList,numberAttachList,cntxt,file);

                },
                  validator: (value) {
                    if (value!.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  controller: attachNameController,
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    labelText: 'Name',
                  ),
                )),
            actions: [
              TextButton(
                child: Text("Discard"),
                onPressed: () {
                  Navigator.of(cntxt).pop();
                },
              ),
              TextButton(
                child: Text("Add"),
                onPressed: () async {
               nameSubmit(attFormKey,attachNameController,attachmentsMapsList,numberAttachList,cntxt,file);
                },
              ),
            ],
          );
        },
      );
    }
  }

  static AttachWidget(formContext, attachmentsMapsList, numberAttachList) {
    return Padding(
        padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Tooltip(
              message: 'Attach files',
              child: IconButton(
                  onPressed: () async {
                    Attachments.save(formContext, attachmentsMapsList, numberAttachList);
                  },
                  icon: Padding(padding: EdgeInsets.fromLTRB(5, 0, 5, 0), child: Icon(Icons.attach_file, size: 25))),
            )));
  }

  static void nameSubmit
      (attFormKey,attachNameController,attachmentsMapsList,numberAttachList,cntxt,file) {
    if (attFormKey.currentState.validate()) {
      if (attachNameController.text.trim() != '') {
        attachmentsMapsList
            .add({'attId': DateTime.now().millisecondsSinceEpoch, 'name': attachNameController.text.trim(), 'file': file});
      }
      print(attachmentsMapsList);
      numberAttachList.value++;
      attachNameController.clear();
      Navigator.of(cntxt).pop();
    }
  }
}
