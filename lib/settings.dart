
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'adsUnits.dart';
import 'global.dart';

class Data extends StatefulWidget {
  @override
  DataState createState() => new DataState();
}

class DataState extends State<Data> {
  static var ctx;

  TextEditingController controller = TextEditingController();
  TextEditingController suggestionDataController = TextEditingController();

  var numberSettingsDropDown = new ValueNotifier(0);
  var numberSettingsList = new ValueNotifier(0);

  String selectedField = Global.suggestionsFilesList[0];

  ScrollController settingsDataListScrollController = new ScrollController();
  ScrollController scrollController = new ScrollController();

  final _formKey = GlobalKey<FormState>();

  static var bannerNotifier = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    ctx = context;
    return Scaffold(
        backgroundColor: Global.backgroundColor,
        appBar: AppBar(title: Text('Suggestions List')),
        body: Container(
            child: ValueListenableBuilder(
                valueListenable: numberSettingsDropDown,
                builder: (BuildContext context, int value, Widget? child) {
                  List? list = [];
                  return Container(
                      padding: EdgeInsets.fromLTRB(20, 0, 10, 0),
                      // height: height - 50,
                      child: Flex(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        direction: Axis.vertical,
                        children: [

                          Expanded(
                              flex: 0,
                              child: Form(
                                  key: _formKey,
                                  child: Row(
                                children: [
                                  Container(
                                  padding: EdgeInsets.fromLTRB(0, 22, 10, 0),
                                // height: height - 50,
                                child: DropdownButton(
                                  style: TextStyle(
                                      fontSize: 17,
                                      letterSpacing: 1,
                                      color: Color.fromARGB(1000, 87, 87, 87),
                                      fontWeight: FontWeight.bold),
                                  value: selectedField,
                                  // underline: Container(),
                                  onChanged: (newValue) async {
                                    selectedField = newValue.toString();
                                    numberSettingsDropDown.value++;
                                  },
                                  items: Global.suggestionsFilesList.map((location) {
                                    return DropdownMenuItem(
                                      child: new Text(
                                        location.toString().replaceAll('_', ' ').toUpperCase(),
                                      ),
                                      value: location,
                                    );
                                  }).toList(),
                                )),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                                      // height: height - 50,
                                      child: TextFormField(
                                      onEditingComplete: () async {
                                        if (_formKey.currentState!.validate()) {
                                          await Global.submitSuggData(
                                              suggestionDataController.text.trim().toUpperCase(), selectedField);
                                          suggestionDataController.clear();
                                          numberSettingsList.value++;
                                        }
                                      },
                                      validator: (value) {
                                        if (list!.contains(value!.trim().toUpperCase())) {
                                          return 'Already exists';
                                        }
                                        if (value.trim() == '') {
                                          return 'Cannot be empty';
                                        }
                                        return null;
                                      },
                                      controller: suggestionDataController,
                                      decoration: InputDecoration(
                                        fillColor: Colors.white,
                                        labelText: selectedField.toString().toUpperCase(),
                                      ),
                                    )),
                                  ),
                                  Padding(
                                      padding: EdgeInsets.fromLTRB(10, 20, 0, 0),
                                      child: ElevatedButton(
                                          child: Padding(
                                            padding: EdgeInsets.all(7),
                                            child: Text("Add"),
                                          ),
                                          style: ButtonStyle(),
                                          onPressed: () async {
                                            if (_formKey.currentState!.validate()) {
                                              await Global.submitSuggData(
                                                  suggestionDataController.text.trim(), selectedField);
                                              suggestionDataController.clear();
                                              numberSettingsList.value++;
                                            }
                                          })),
                                ],
                              ))),
                          Expanded(
                              flex: 1,
                              child: ValueListenableBuilder(
                                  valueListenable: numberSettingsList,
                                  builder: (BuildContext context, int value, Widget? child) {
                                    return FutureBuilder(
                                        future: Global.suggestionFilter('', selectedField),
                                        builder: (context, snapshot) {

                                          if (snapshot.data != null) {
                                            list = snapshot.data as List?;
                                          }
                                          return snapshot.data != null
                                              ? Container(
                                                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                                                  height: MediaQuery.of(context).size.height - 240,
                                                  child: Scrollbar(
                                                    thickness: 10,
                                                    isAlwaysShown: true,
                                                    controller: settingsDataListScrollController,
                                                    child: ListView(
                                                      // shrinkWrap: true,
                                                      // reverse: true,
                                                      controller: settingsDataListScrollController,
                                                      children: [
                                                        for (int i = list!.length - 1; i >= 0; i--)
                                                          Card(
                                                            margin: EdgeInsets.fromLTRB(0, 10, 15, 0),
                                                            child: Padding(
                                                                padding: EdgeInsets.fromLTRB(15, 10, 5, 10),
                                                                child: Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child: Text(
                                                                        list![i],
                                                                        style: TextStyle(fontSize: 15),
                                                                      ),
                                                                    ),
                                                                    Spacer(),
                                                                    MouseRegion(
                                                                        cursor: SystemMouseCursors.click,
                                                                        child: GestureDetector(
                                                                            onTap: () {
                                                                              showDialog(
                                                                                context: context,
                                                                                builder: (BuildContext cntxt) {
                                                                                  return AlertDialog(
                                                                                    title: Text("Alert"),
                                                                                    content: Text(
                                                                                        "Sure to delete this Entry"),
                                                                                    actions: [
                                                                                      TextButton(
                                                                                        child: Text("No"),
                                                                                        onPressed: () {
                                                                                          Navigator.of(cntxt).pop();
                                                                                        },
                                                                                      ),
                                                                                      TextButton(
                                                                                        child: Text("Yes"),
                                                                                        onPressed: () async {
                                                                                          Global.deleteSuggData(
                                                                                              selectedField,
                                                                                              list![i],
                                                                                              i);

                                                                                          numberSettingsList.value++;

                                                                                          Navigator.of(cntxt).pop();
                                                                                        },
                                                                                      ),
                                                                                    ],
                                                                                  );
                                                                                },
                                                                              );
                                                                            },
                                                                            child: Padding(
                                                                                padding:
                                                                                    EdgeInsets.fromLTRB(10, 0, 5, 0),
                                                                                child: Tooltip(
                                                                                  message: 'Delete',
                                                                                  child: Icon(Icons.delete,
                                                                                      color: Colors.blue, size: 30),
                                                                                )))),
                                                                  ],
                                                                )),
                                                          )
                                                      ],
                                                    ),
                                                  ))
                                              : Container(
                                                  height: 0,
                                                  width: 0,
                                                );
                                        });
                                  })),
                          Expanded(
                              flex: 0,
                              child: Container(
                              padding: EdgeInsets.all(10),
                              // height: height - 50,
                              child:  AdsUnits.googleBannerAd3(),
                              )),
                        ],
                      ));
                })));
  }
}
