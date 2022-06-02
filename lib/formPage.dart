import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'adsUnits.dart';
import 'forms/in.dart';
import 'forms/out.dart';
import 'global.dart';

class FormPage extends StatefulWidget {
  var data;

  FormPage(this.data);

  @override
  FormPageState createState() => FormPageState(data);
}

class FormPageState extends State<FormPage> {
  var data;

  FormPageState(this.data);

  var ctx;
  var numberForm = new ValueNotifier(0);
  ScrollController formsScrollController = new ScrollController();

  static ValueNotifier<int> bannerNotifier = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    ctx = context;
    AdsUnits.myBanner2.load();
    return Scaffold(backgroundColor: Global.backgroundColor,
        appBar: AppBar(
          title: Text(Global.selectedFormField),
        ),
        body: Container(
            margin: EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: SingleChildScrollView(
                controller: formsScrollController,
                child: Column(children: [
                  ValueListenableBuilder(
                      valueListenable: numberForm,
                      builder: (BuildContext context, int value, Widget? child) {
                        return  Global.selectedFormField == Global.fieldsForm[0]
                                    ? InForm(context, data)
                                    :  OutForm(context, data);
                      }),
                Container(
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: AdsUnits.googleBannerAd2())
                ]))));
  }
}
