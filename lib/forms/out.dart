import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:cash_records/global.dart';

import 'formHelper/attachments.dart';

class OutForm extends StatelessWidget {
  var formContext;
  var data;

  OutForm(this.formContext, this.data);

  FocusNode focusNode1 = new FocusNode();
  List attachmentsMapsList = [];
  var numberAttachList = new ValueNotifier(0);
  final _formKey = GlobalKey<FormState>();

  TextEditingController dateFormController = TextEditingController();
  TextEditingController itemSalaryController = TextEditingController();
  TextEditingController priceSalaryController = TextEditingController();
  TextEditingController noteSalaryController = TextEditingController();
  TextEditingController attachNameController = TextEditingController();

  loadInitData() async {
    if (data != null) {
      dateFormController.text = data['Date'];
      itemSalaryController.text = data['Item'];
      priceSalaryController.text = data['Amount'];
      noteSalaryController.text = data['Note'];

      for (Map attachMap in data['attachments']) {
        attachmentsMapsList.add({
          'attId': attachMap['attId'],
          'name': attachMap['name'],
          'file': File(await Global.getDataDirectoryPath() +
              '/profile0/attachments/' +
              data['id'].toString() +
              '/' +
              attachMap['attId'].toString() +
              '.' +
              attachMap['ext'])
        });
      }
    } else {
      DateTime t = DateTime.now();
      String date = t.day.toString() + "/" + t.month.toString() + "/" + t.year.toString();
      dateFormController.text = date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadInitData(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState != ConnectionState.waiting) {
          return Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter Date';
                            }
                            if (!RegExp(r'\d{1,2}/\d{1,2}/\d{4}').hasMatch(value)) {
                              return 'Please enter correct Date';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                          controller: dateFormController,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            labelText: 'Date',
                            hintText: "dd/mm/yyyy",
                            //  icon: Icon(Icons.date_range_rounded,
                            //    color: Colors.green),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Show Calender',
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: GestureDetector(
                              child: Icon(
                                Icons.date_range_sharp,
                                size: 40,
                              ),
                              onTap: () async {
                                DateTime? date = DateTime(1900);

                                date = await showDatePicker(
                                    context: formContext,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(DateTime.now().year + 1));

                                dateFormController.text = date!.day.toString() + '/' + date.month.toString() + '/' + date.year.toString();
                              }),
                        ),
                      )
                    ],
                  ),
                  TypeAheadFormField(
                    textFieldConfiguration: TextFieldConfiguration(
                       // autofocus: data != null ? false : true,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        controller: itemSalaryController,
                        decoration: InputDecoration(labelText: 'For')),
                    suggestionsCallback: (pattern) async {
                      return await Global.suggestionFilter(pattern, Global.suggestionsFilesList[1]);
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion.toString()),
                      );
                    },
                    transitionBuilder: (context, suggestionsBox, controller) {
                      return suggestionsBox;
                    },
                    onSuggestionSelected: (suggestion) {
                      itemSalaryController.text = suggestion.toString();
                      focusNode1.requestFocus();
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter Name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter Amount';
                      }
                      return null;
                    },
                    focusNode: focusNode1,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    controller: priceSalaryController,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      labelText: 'Amount',
                      // icon: Icon(Icons.account_box, color: Colors.green),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  TextFormField(
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    controller: noteSalaryController,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      labelText: 'Note',
                    ),
                  ),
                  Container(
                      margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
                      child: ValueListenableBuilder(
                          valueListenable: numberAttachList,
                          builder: (BuildContext context, int value, Widget? child) {
                            return Column(
                              children: [
                                for (Map attch in attachmentsMapsList)
                                  Card(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(10, 5, 0, 5),
                                      child: Row(
                                        children: [
                                          Text(attch['name']),
                                          Spacer(),
                                          MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: Tooltip(
                                                message: 'Remove',
                                                child: GestureDetector(
                                                    onTap: () {
                                                      attachmentsMapsList.remove(attch);
                                                      numberAttachList.value++;
                                                    },
                                                    child: Padding(
                                                        padding: EdgeInsets.fromLTRB(5, 3, 5, 0),
                                                        child: Icon(Icons.delete, size: 18, color: Colors.blue))),
                                              ))
                                        ],
                                      ),
                                    ),
                                  )
                              ],
                            );
                          })),
                  Row(
                    children: [
                      Attachments.AttachWidget(formContext, attachmentsMapsList, numberAttachList),
                      Spacer(),
                      Padding(
                        padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: FloatingActionButton.extended(backgroundColor: Colors.redAccent,
                            elevation: 1,
                            label: Padding(
                                padding: EdgeInsets.all(0),
                                child: Text(
                                  'Submit',
                                  style: TextStyle(fontSize: 15,color: Colors.white),
                                )),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                List listAttch = [];
                                for (Map map in attachmentsMapsList) {
                                  listAttch.add({
                                    'attId': map['attId'],
                                    'name': map['name'],
                                    'ext': map['file'].path.split('.')[map['file'].path.split('.').length - 1]
                                  });
                                }

                                String docId;
                                if (data != null) {
                                  docId = data['id'];
                                } else {
                                  docId = DateTime.now().millisecondsSinceEpoch.toString();
                                }
                                Map dataMap = {
                                  "id": docId,
                                  "Date": dateFormController.text,
                                  "Field": Global.fieldsForm[1],
                                  "Item": itemSalaryController.text,
                                  "Amount": priceSalaryController.text,
                                  "Note": noteSalaryController.text,
                                  "attachments": listAttch
                                };

                                List list0 = await Global.suggestionFilter('', Global.suggestionsFilesList[1]);
                                if (!list0.contains(itemSalaryController.text.trim().toUpperCase())) {
                                  Global.submitSuggData(itemSalaryController.text.trim().toUpperCase(), Global.suggestionsFilesList[1]);
                                }

                                for (Map m in attachmentsMapsList) {
                                  File file = m['file'];
                                  String pth = await Global.getDataDirectoryPath() +
                                      '/profile0/attachments/' +
                                      docId.toString() +
                                      '/' +
                                      m['attId'].toString() +
                                      '.' +
                                      file.path.split('.')[file.path.split('.').length - 1];
                                  if (pth != file.path) {
                                    await File(pth).create(recursive: true).then((value) async => {await file.copy(pth)});
                                  }
                                }

                                var dataBox = await Hive.openBox('dataBox');
                                await dataBox.put(docId, dataMap);

                                itemSalaryController.clear();
                                priceSalaryController.clear();
                                noteSalaryController.clear();
                                attachmentsMapsList = [];
                                numberAttachList.value++;

                                Navigator.pop(formContext);
                              }
                            }),
                      )
                    ],
                  )
                ],
              ));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
