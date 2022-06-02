import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:open_file/open_file.dart';
import 'package:cash_records/Currency.dart';
import 'package:cash_records/driveSync.dart';
import 'package:cash_records/printInvoice.dart';
import 'package:cash_records/settings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'adsUnits.dart';
import 'formPage.dart';
import 'global.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'printShare.dart';
import 'package:share/share.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Hive.init(await Global.getDataDirectoryPath());
  Global.settingsBox = await Hive.openBox('settings');
  Global.brandInfoBox = await Hive.openBox('brandInfoBox');
  // Global.settingsBox.put('dataConverted', null);
  var driveSync = DriveSync();
  var cred = await driveSync.getCredentials();
  if (cred != null) {
    Global.loggedIn = true;
  }
  if (Global.settingsBox.get('backupInterval') == null) {
    await Global.settingsBox.put('backupInterval', 3);
  }
  if (Global.settingsBox.get('ratePopCounter') == null) {
    await Global.settingsBox.put('ratePopCounter', 0);
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cash Records',
      theme: ThemeData(
        primarySwatch: Colors.lime,
      ),
      home: WillPopScope(
          child: MyHomePage(),
          onWillPop: () async {
            // if (Global.settingsBox.get('ratePopDone') == null) {
            //   if (Global.settingsBox.get('ratePopCounter') != 10) {
            //      Global.settingsBox.put('ratePopCounter', Global.settingsBox.get('ratePopCounter') + 1);
            //      MoveToBackground.moveTaskToBack();
            //      //print('on pop');
            //      var driveSync = DriveSync();
            //      driveSync.backupAtAppClose();
            //      return false;
            //   } else {
            //      Global.settingsBox.put('ratePopCounter', 0);
            //    await showDialog(
            //       context: context,
            //       builder: (BuildContext cntxt) {
            //         return AlertDialog(
            //           title: Text('Rate this App'),
            //           content: Text('If you like this app, please take a little bit of your time to review it !\n'
            //               'It really helps us to make it better for you and it shouldn\'t take you more than one minute.'),
            //           actions: [
            //             TextButton(
            //                 onPressed: () {
            //                   launch('https://play.google.com/store/apps/details?id=com.totp.cash_records');
            //                   Global.settingsBox.put('ratePopDone', true);
            //                   Navigator.pop(cntxt);
            //                 },
            //                 child: Text('Rate')),
            //             TextButton(
            //                 onPressed: () async {
            //                   Global.settingsBox.put('ratePopDone', true);
            //                   Navigator.pop(cntxt);
            //                 },
            //                 child: Text('No Thanks')),
            //             TextButton(
            //                 onPressed: () async {
            //                   await Global.settingsBox.put('ratePopCounter', Global.settingsBox.get('ratePopCounter') + 1);
            //                   Navigator.pop(cntxt);
            //                 },
            //                 child: Text('Later'))
            //           ],
            //         );
            //       },
            //     );
            //      MoveToBackground.moveTaskToBack();
            //      //print('on pop');
            //      var driveSync = DriveSync();
            //      driveSync.backupAtAppClose();
            //      return false;
            //   }
            // }else{
            //   MoveToBackground.moveTaskToBack();
            //   //print('on pop');
            //   var driveSync = DriveSync();
            //   driveSync.backupAtAppClose();
            //   return false;
            // }

            MoveToBackground.moveTaskToBack();
            //print('on pop');
            var driveSync = DriveSync();
            driveSync.backupAtAppClose();
            return false;
          }),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  static var ctx;
  static var cntxtOfRestoreProgressDialog;
  var currencySelected = '[INR] India';
  var currencyIndex = 45;
  bool settingsButtonClicked = false;
  static bool uploadingBackup = false;
  static var restoreBackupResult = '';
  double height = 0.0;
  double width = 0.0;
  var numberContent = new ValueNotifier(0);
  var numberForm = new ValueNotifier(0);
  var notifierAttachList = new ValueNotifier(0);
  var numberSettingsDropDown = new ValueNotifier(0);
  var numberSettingsList = new ValueNotifier(0);
  static var brandNotifier = new ValueNotifier(0);
  static var backupNotifier = new ValueNotifier(0);
  String _selectedFieldContent = Global.fieldsContent[0];

  late StreamSubscription<dynamic> _subscription;

  TextEditingController searchController = TextEditingController();

  TextEditingController dateFromController = TextEditingController();
  TextEditingController dateToController = TextEditingController();

  TextEditingController suggestionDataController = TextEditingController();
  TextEditingController attachNameController = TextEditingController();

  ScrollController formsScrollController = new ScrollController();
  ScrollController settingsDataListScrollController = new ScrollController();
  ScrollController contentScrollController = new ScrollController();
  ScrollController attachListScrollController = new ScrollController();

  static ValueNotifier<int> bannerNotifier = ValueNotifier<int>(0);

  int allDataLength = 0;

  static var email = '';

  // void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
  //   purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
  //     if (purchaseDetails.status == PurchaseStatus.pending) {
  //      // _showPendingUI();
  //     } else {
  //       if (purchaseDetails.status == PurchaseStatus.error) {
  //        // _handleError(purchaseDetails.error!);
  //       } else if (purchaseDetails.status == PurchaseStatus.purchased ||
  //           purchaseDetails.status == PurchaseStatus.restored) {
  //         bool valid = await _verifyPurchase(purchaseDetails);
  //         if (valid) {
  //           _deliverProduct(purchaseDetails);
  //         } else {
  //           _handleInvalidPurchase(purchaseDetails);
  //         }
  //       }
  //       if (purchaseDetails.pendingCompletePurchase) {
  //         await InAppPurchase.instance
  //             .completePurchase(purchaseDetails);
  //       }
  //     }
  //   });
  // }

  @override
  void initState() {
    // final Stream purchaseUpdated =
    //     InAppPurchase.instance.purchaseStream;
    // _subscription = purchaseUpdated.listen((purchaseDetailsList) {
    //   _listenToPurchaseUpdated(purchaseDetailsList);
    // }, onDone: () {
    //   _subscription.cancel();
    // }, onError: (error) {
    //   // handle error here.
    // });

    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    AdsUnits.loadAds();
    resetFilter();
  }

  @override
  void dispose() {
    _subscription.cancel();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AdsUnits.loadInterAd();
      MyHomePageState.bannerNotifier.value++;
      FormPageState.bannerNotifier.value++;
    }
  }

  resetFilter() {
    DateTime toDate = DateTime.now();
    String toString = toDate.day.toString() + "/" + toDate.month.toString() + "/" + toDate.year.toString();
    DateTime fromDate = toDate.subtract(Duration(days: 30));
    String fromString = fromDate.day.toString() + "/" + fromDate.month.toString() + "/" + fromDate.year.toString();
    dateFromController.text = fromString;
    dateToController.text = toString;
    _selectedFieldContent = Global.fieldsContent[0];
    numberContent.value++;
  }

  @override
  Widget build(BuildContext context) {
    ctx = context;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.lime, // navigation bar color
      statusBarColor: Colors.lime, // status bar color
    ));
    if (Global.settingsBox.get('currencyIndex') == null) {
      return Scaffold(
        body: firstTimeScreen(context),
      );
    } else {
      return Scaffold(
          backgroundColor: Global.backgroundColor,
          appBar: AppBar(
            leading: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                    message: 'Menu',
                    child: TextButton(
                        onPressed: () {
                          menuDialog(context);
                        },
                        child: Padding(
                            padding: EdgeInsets.fromLTRB(15, 2, 0, 0),
                            child: Icon(
                              Icons.menu,
                              size: 25,
                              color: Colors.black,
                            ))))),
            title: Text('Cash Records'),
            actions: [
              MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                      message: 'Filter',
                      child: GestureDetector(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: Icon(
                            Icons.filter_list,
                            size: 25,
                          ),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext cntxt) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                title: Text("Filter Records"),
                                content: Wrap(
                                  children: [
                                    ValueListenableBuilder(
                                        valueListenable: numberContent,
                                        builder: (BuildContext context, int value, Widget? child) {
                                          return Container(
                                            padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                            child: DropdownButton(
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Color.fromARGB(1000, 51, 51, 51),
                                                  fontWeight: FontWeight.w600),
                                              value: _selectedFieldContent,
                                              underline: Container(),
                                              onChanged: (newValue) {
                                                _selectedFieldContent = newValue.toString();
                                                numberContent.value++;
                                              },
                                              items: Global.fieldsContent.map((location) {
                                                return DropdownMenuItem(
                                                  child: new Text(
                                                    location.toString().toUpperCase(),
                                                  ),
                                                  value: location,
                                                );
                                              }).toList(),
                                            ),
                                          );
                                        }),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                              //  width: 50,
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
                                            controller: dateFromController,
                                            decoration: InputDecoration(
                                              fillColor: Colors.white,
                                              labelText: 'From',
                                              hintText: "dd/mm/yyyy",
                                            ),
                                          )),
                                        ),
                                        IconButton(
                                            padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                                            icon: Icon(
                                              Icons.date_range_sharp,
                                              size: 40,
                                            ),
                                            onPressed: () async {
                                              DateTime? date = DateTime(1900);
                                              date = await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime(DateTime.now().year + 1));

                                              if (date != null) {
                                                dateFromController.text = date.day.toString() +
                                                    '/' +
                                                    date.month.toString() +
                                                    '/' +
                                                    date.year.toString();
                                                numberContent.value++;
                                              }
                                            }),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                              // width: 50,
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
                                            controller: dateToController,
                                            decoration: InputDecoration(
                                              fillColor: Colors.white,
                                              labelText: 'To',
                                              hintText: "dd/mm/yyyy",
                                            ),
                                          )),
                                        ),
                                        IconButton(
                                            padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                                            icon: Icon(
                                              Icons.date_range_sharp,
                                              size: 40,
                                            ),
                                            onPressed: () async {
                                              DateTime? date = DateTime(1900);
                                              date = await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime(DateTime.now().year + 1));

                                              dateToController.text = date!.day.toString() +
                                                  '/' +
                                                  date.month.toString() +
                                                  '/' +
                                                  date.year.toString();
                                              numberContent.value++;
                                            }),
                                      ],
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    child: Text("Reset",style: TextStyle(color: Global.iconColor)),
                                    onPressed: () {
                                      resetFilter();
                                    },
                                  ),
                                  TextButton(
                                    child: Text("OK",style: TextStyle(color: Global.iconColor)),
                                    onPressed: () {
                                      Navigator.of(cntxt).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      )))
            ],
          ),
          floatingActionButton: Row(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(32, 0, 0, 0),
                child: FloatingActionButton.extended(
                  heroTag: '1',
                  backgroundColor: Colors.lightGreen,
                  label: Icon(Icons.download_rounded,color: Colors.white,),
                  onPressed: () {
                    Global.selectedFormField = Global.fieldsForm[0];
                    Navigator.push(context, MaterialPageRoute(builder: (context) => FormPage(null))).then((value) {
                      setState(() {});
                      AdsUnits.showInterAd();
                    });
                  },
                ),
              ),
              Spacer(),
              FloatingActionButton.extended(
                heroTag: '2',
                backgroundColor: Colors.redAccent,
                label: Icon(Icons.upload_rounded,color: Colors.white,),
                onPressed: () {
                  Global.selectedFormField = Global.fieldsForm[1];
                  Navigator.push(context, MaterialPageRoute(builder: (context) => FormPage(null))).then((value) {
                    setState(() {});
                    AdsUnits.showInterAd();
                  });
                },
              ),
            ],
          ),
          body: Container(
              child: Flex(
            direction: Axis.vertical,
            children: [
              Expanded(
                flex: 0,
                child: Container(
                    height: 60,
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: TextFormField(
                      onChanged: (text) {
                        numberContent.value++;
                      },
                      controller: searchController,
                      decoration: InputDecoration(
                        suffix: GestureDetector(
                          onTap: () {
                            searchController.clear();
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.lime,
                          ),
                        ),
                        fillColor: Colors.white,
                        labelText: 'Search',
                      ),
                    )),
              ),
              Expanded(
                  flex: 1,
                  child: ValueListenableBuilder(
                      valueListenable: numberContent,
                      builder: (BuildContext context, int value, Widget? child) {
                        return FutureBuilder(
                            future: _inFutureList(),
                            builder: (BuildContext context, AsyncSnapshot snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(
                                    child: Column(
                                  children: [Container(height: 200), CircularProgressIndicator()],
                                ));
                              } else {
                                // //print(snapshot.data);
                                List list = snapshot.data[0];
                                //print(snapshot.data[0]);
                                return Flex(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  direction: Axis.vertical,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    //totals widget
                                    if (list.isNotEmpty) Expanded(flex: 0, child: totalsWidget(snapshot)),
                                    Expanded(
                                        flex: 1,
                                        child: list.isNotEmpty
                                            ? Container(
                                                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                                child: ListView(
                                                  // controller:
                                                  //     contentScrollController,
                                                  shrinkWrap: true,
                                                  children: [
                                                    for (int i = list.length - 1; i >= 0; i--)
                                                      i != list.length - 5
                                                          ? listCard(context, list[i], i)
                                                          : Column(
                                                              children: [
                                                                listCard(context, list[i], i),
                                                                Container(
                                                                  height: 5,
                                                                ),
                                                                AdsUnits.googleBannerAd1()
                                                              ],
                                                            ),
                                                    if (list.length < 5)
                                                      Column(
                                                        children: [
                                                          Container(
                                                            height: 20,
                                                          ),
                                                          AdsUnits.googleBannerAd1()
                                                        ],
                                                      ),
                                                    Container(
                                                      height: 70,
                                                    )
                                                  ],
                                                ))
                                            : Center(
                                                child: Column(
                                                children: [
                                                  Container(height: 40),
                                                  Text(
                                                      (searchController.text.trim() != '' && allDataLength != 0)
                                                          ? 'No search result'
                                                          : (allDataLength == 0)
                                                              ? 'Please Add Some Data'
                                                              : 'No Records for this date range',
                                                      style: TextStyle(fontSize: 23)),
                                                  Container(height: 50),
                                                  AdsUnits.googleBannerAd1()
                                                ],
                                              )))
                                  ],
                                );
                              }
                            });
                      }))
            ],
          )));
    }
  }

  menuDialog(context) {
    ValueNotifier cNotifier = ValueNotifier(0);
    showDialog(
      context: context,
      builder: (BuildContext cntxt) {
        return Dialog(
            insetPadding: EdgeInsets.fromLTRB(30, 50, 30, 30),
            backgroundColor: Colors.white,
            child: ListView(
              shrinkWrap: true,
              children: [
                Container(
                  color: Colors.lime,
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'Settings',
                    style: TextStyle(color: Colors.black, fontSize: 25, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.start,
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: cNotifier,
                  builder: (BuildContext context, value, Widget? child) {
                    return ListTile(
                      leading: Padding(
                          padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
                          child: Icon(
                            Icons.credit_card,
                            color: Global.iconColor,
                            size: 30,
                          )),
                      title: Text(
                        'Currency',
                        style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w400),
                      ),
                      subtitle: Text(CurrencyData.symbol[Global.settingsBox.get('currencyIndex')] +
                          '  ' +
                          CurrencyData.currency[Global.settingsBox.get('currencyIndex')] +
                          '  ' +
                          CurrencyData.country[Global.settingsBox.get('currencyIndex')]),
                      onTap: () {
                        Navigator.pop(cntxt);
                        showDialog(
                          context: context,
                          builder: (BuildContext cntxt1) {
                            return Dialog(
                              backgroundColor: Colors.white,
                              insetPadding: MediaQuery.of(context).orientation == Orientation.portrait
                                  ? EdgeInsets.fromLTRB(35, MediaQuery.of(context).size.height / 3, 35, 20)
                                  : EdgeInsets.fromLTRB(35, 20, 35, 20),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    Padding(
                                        padding: EdgeInsets.fromLTRB(15, 20, 20, 5),
                                        child: Text(
                                          'Choose Currency',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                        )),
                                    for (int i = 0; i < CurrencyData.currency.length; i++)
                                      ListTile(
                                        title: Text(
                                          CurrencyData.country[i].toString(),
                                          style: TextStyle(color: Global.iconColor, fontSize: 18),
                                        ),
                                        subtitle: Text(CurrencyData.currency[i].toString() +
                                            '  ' +
                                            CurrencyData.symbol[i].toString()),
                                        onTap: () async {
                                          await Global.settingsBox.put('currencyIndex', i);
                                          Navigator.pop(cntxt1);
                                          cNotifier.value++;
                                          setState(() {});
                                        },
                                      )
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: Padding(
                      padding: EdgeInsets.fromLTRB(4, 5, 0, 0),
                      child: Icon(
                        Icons.view_list_outlined,
                        color: Global.iconColor,
                        size: 34,
                      )),
                  title: Text(
                    'Suggestion Data',
                    style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  subtitle: Text('Edit Suggestions Lists'),
                  onTap: () {
                    Navigator.pop(cntxt);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Data())).then((value) {
                      setState(() {});
                      AdsUnits.showInterAd();
                    });
                  },
                ),
                ListTile(
                  leading: Padding(
                      padding: EdgeInsets.fromLTRB(4, 5, 0, 0),
                      child: Icon(
                        Icons.add_to_drive,
                        color: Global.iconColor,
                        size: 30,
                      )),
                  title: Text(
                    'Backup & Restore',
                    style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  subtitle: Text('Save Backup on Google Drive'),
                  onTap: () async {
                    Navigator.of(cntxt).pop();
                    backupDialog();
                  },
                ),
                Container(
                    decoration: BoxDecoration(
                        //  color: Colors.green,
                        borderRadius:
                            BorderRadius.only(bottomLeft: Radius.circular(4.0), bottomRight: Radius.circular(4.0))),
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                        child: Row(
                          children: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(cntxt);
                                  launch("https://play.google.com/store/apps/developer?id=TOTP");
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.apps,
                                      size: 28,
                                      color: Global.iconColor,
                                    ),
                                    Padding(
                                        padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
                                        child: Text(
                                          'More Apps',
                                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                                        ))
                                  ],
                                )),
                            Spacer(),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(cntxt);
                                  //  final InAppReview inAppReview = InAppReview.instance;

                                  // if (await inAppReview.isAvailable()) {
                                  // inAppReview.requestReview();
                                  // } else {
                                  launch("https://play.google.com/store/apps/details?id=com.totp.cash_records");
                                  // }
                                  // inAppReview.openStoreListing();
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 28,
                                      color: Global.iconColor,
                                    ),
                                    Padding(
                                        padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
                                        child: Text(
                                          'Rate this app',
                                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                                        ))
                                  ],
                                )),
                            Spacer(),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(cntxt);
                                  Share.share(
                                      'Hey! Checkout this App.\Cash Records - A simple and tiny app to keep records of daily credit and debit for your money.\n\n'
                                      'https://play.google.com/store/apps/details?id=com.totp.cash_records',
                                      subject: 'Cash Records');
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.share,
                                      size: 27,
                                      color: Global.iconColor,
                                    ),
                                    Padding(
                                        padding: EdgeInsets.fromLTRB(0, 6, 0, 0),
                                        child: Text(
                                          'Share this App',
                                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                                        ))
                                  ],
                                )),
                          ],
                        ))),
              ],
            ));
      },
    );
  }

  backupDialog() async {
    var driveSync = DriveSync();
    showDialog(
        builder: (BuildContext cntxt2) {
          return Dialog(
            backgroundColor: Colors.white,
            child: ValueListenableBuilder(
              valueListenable: backupNotifier,
              builder: (BuildContext context, value, Widget? child) {
                if (Global.loggedIn) {
                  if (Global.settingsBox.get('userEmail') != null) {
                    email = Global.settingsBox.get('userEmail');
                  }

                  var lastBackup = '';
                  if (Global.settingsBox.get('backupDate') != null) {
                    final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');
                    lastBackup = formatter.format(Global.settingsBox.get('backupDate'));
                  } else {
                    lastBackup = Global.checkingBackup ? 'Checking for Backup' : 'Never';
                  }

                  GlobalKey _toolTipKey = GlobalKey();
                  bool toolTipVisible = false;

                  return Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: Padding(
                                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                                  child: uploadingBackup
                                      ? Container(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                          ),
                                        )
                                      : Icon(
                                          Icons.backup,
                                          color: Global.iconColor,
                                        )),
                              title: Text(uploadingBackup ? 'Uploading Backup..' : 'Backup Now',
                                  style: TextStyle(fontSize: 17)),
                              subtitle: Text('Last : ' + lastBackup, style: TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                onPressed: () {
                                  final dynamic tooltip = _toolTipKey.currentState;
                                  if (!toolTipVisible) {
                                    tooltip.ensureTooltipVisible();
                                    toolTipVisible = true;
                                  } else {
                                    tooltip.deactivate();
                                    toolTipVisible = false;
                                  }
                                },
                                icon: Tooltip(
                                    padding: EdgeInsets.all(20),
                                    margin: EdgeInsets.fromLTRB(50, 0, 50, 10),
                                    showDuration: Duration(seconds: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.9),
                                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                                    ),
                                    textStyle: TextStyle(color: Colors.white),
                                    preferBelow: true,
                                    verticalOffset: 20,
                                    key: _toolTipKey,
                                    message:
                                        'Attachments are not included in backup.The feature will be available in next app update!!',
                                    child: Icon(Icons.info_outline)),
                              ),
                              onTap: () async {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext cntxt3) {
                                    return AlertDialog(
                                      title: Text('Alert'),
                                      content: Text('Previous backup (if any) will be replaced by new backup...'),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(cntxt3).pop();
                                            },
                                            child: Text('Cancel',style: TextStyle(color: Global.iconColor),)),
                                        TextButton(
                                            onPressed: () async {
                                              Navigator.of(cntxt3).pop();
                                              if (!uploadingBackup) {
                                                driveSync.uploadBackup();
                                              }
                                            },
                                            child: Text('Backup',style: TextStyle(color: Global.iconColor)))
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.settings_backup_restore,
                                color: Global.iconColor,
                              ),
                              title: Text('Restore Backup', style: TextStyle(fontSize: 17)),
                              onTap: () async {
                                if (lastBackup == 'Never') {
                                  showToast('No Backup!', context: ctx);
                                } else if (lastBackup == 'Checking for Backup') {
                                  showToast('Checking for Backup!', context: ctx);
                                } else {
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
                                              child: Text('Cancel',style: TextStyle(color: Global.iconColor))),
                                          TextButton(
                                              onPressed: () async {
                                                Navigator.of(cntxt6).pop();
                                                Navigator.of(cntxt2).pop();
                                                showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (BuildContext cntxt) {
                                                    cntxtOfRestoreProgressDialog = cntxt;
                                                    return WillPopScope(
                                                        child: Dialog(
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
                                                        ),
                                                        onWillPop: () async {
                                                          return false;
                                                        });
                                                  },
                                                );
                                              },
                                              child: Text('Restore',style: TextStyle(color: Global.iconColor)))
                                        ],
                                      );
                                    },
                                  );

                                  driveSync.restoreBackup();
                                }
                              },
                            ),
                            ListTile(
                              leading: Padding(
                                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                                  child: Icon(
                                    Icons.access_time_outlined,
                                    color: Global.iconColor,
                                  )),
                              title: Text(
                                'Auto Backup',
                                style: TextStyle(fontSize: 17),
                              ),
                              subtitle: Text(Global.listBackupInterval[Global.settingsBox.get('backupInterval')],
                                  style: TextStyle(fontSize: 13)),
                              onTap: () async {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext cntxt) {
                                      GlobalKey _toolTipKey = GlobalKey();
                                      bool toolTipVisible = false;
                                      return Dialog(
                                        backgroundColor: Colors.white,
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: [
                                            for (int i = 0; i < Global.listBackupInterval.length; i++)
                                              i == 2
                                                  ? ListTile(
                                                      title: Text(Global.listBackupInterval[i]),
                                                      subtitle: Text(
                                                        '(Uses more internet data)',
                                                        style: TextStyle(fontSize: 12),
                                                      ),
                                                      trailing: IconButton(
                                                        onPressed: () {
                                                          final dynamic tooltip = _toolTipKey.currentState;
                                                          if (!toolTipVisible) {
                                                            tooltip.ensureTooltipVisible();
                                                            toolTipVisible = true;
                                                          } else {
                                                            tooltip.deactivate();
                                                            toolTipVisible = false;
                                                          }
                                                        },
                                                        icon: Tooltip(
                                                            padding: EdgeInsets.all(20),
                                                            margin: EdgeInsets.fromLTRB(50, 0, 50, 10),
                                                            showDuration: Duration(seconds: 10),
                                                            decoration: BoxDecoration(
                                                              color: Colors.blue.withOpacity(0.9),
                                                              borderRadius: const BorderRadius.all(Radius.circular(4)),
                                                            ),
                                                            textStyle: TextStyle(color: Colors.white),
                                                            preferBelow: true,
                                                            verticalOffset: 20,
                                                            key: _toolTipKey,
                                                            message:
                                                                'Use this option if you do not have concern about internet '
                                                                'data because this option may use more data if you open and close the app many times. '
                                                                'If you really are not concern about data, we recommend you to use this option.',
                                                            child: Icon(Icons.info_outline)),
                                                      ),
                                                      onTap: () {
                                                        Global.settingsBox.put('backupInterval', i);
                                                        backupNotifier.value++;
                                                        Navigator.pop(cntxt);
                                                      },
                                                    )
                                                  : ListTile(
                                                      title: Text(Global.listBackupInterval[i]),
                                                      onTap: () {
                                                        Global.settingsBox.put('backupInterval', i);
                                                        backupNotifier.value++;
                                                        Navigator.pop(cntxt);
                                                      },
                                                    )
                                          ],
                                        ),
                                      );
                                    });

                                if (Global.listBackupInterval[Global.settingsBox.get('backupInterval')] == 'Never') {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext cntxt6) {
                                      return AlertDialog(
                                        title: Text('Alert'),
                                        content:
                                            Text('Enabling Auto Backup option will replace previous backup if any...'),
                                        actions: [
                                          TextButton(
                                              onPressed: () async {
                                                Navigator.of(cntxt6).pop();
                                              },
                                              child: Text('OK',style: TextStyle(color: Global.iconColor)))
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                            ListTile(
                              leading: Padding(
                                padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                                child: Icon(
                                  Icons.logout,
                                  color: Global.iconColor,
                                ),
                              ),
                              title: Text('Sign Out of Google', style: TextStyle(fontSize: 17)),
                              subtitle: Text(email, style: TextStyle(fontSize: 12)),
                              onTap: () async {
                                driveSync.clearCredentials();
                              },
                            ),
                          ]));
                } else {
                  return Column(
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
                          onTap: () async {
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
                        height: 30,
                      )
                    ],
                  );
                }
              },
            ),
          );
        },
        context: context);
  }

  firstTimeScreen(context) {
    return Container(
      decoration: BoxDecoration(color: Colors.lime),
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/iconNew.png',
            height: 200,
            width: 200,
          ),
          Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: Text(
                'Welcome!',
                textAlign: TextAlign.center,
                style: GoogleFonts.adventPro(
                    textStyle:
                        TextStyle(color: Colors.green, fontSize: 30, fontWeight: FontWeight.w600)),
              )),
          Padding(
              padding: EdgeInsets.fromLTRB(30, 0, 30, 60),
              child: Text(
                'Thank you for choosing Cash Records.',
                textAlign: TextAlign.center,
                style: GoogleFonts.adventPro(
                    textStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500)),
              )),
          Padding(
              padding: EdgeInsets.fromLTRB(0, 7, 0, 20),
              child: Text(
                'Please choose your Currency',
                style: GoogleFonts.adventPro(
                    textStyle:
                        TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.w500)),
              )),
          ElevatedButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: Text(
                currencySelected,
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext cntxt) {
                  return Dialog(
                    backgroundColor: Colors.white,
                    child: ListView.builder(
                      itemCount: CurrencyData.currency.length,
                      shrinkWrap: true,
                      itemExtent: 60,
                      itemBuilder: (BuildContext context, int i) {
                        return ListTile(
                          title: Text(
                            CurrencyData.country[i].toString(),
                            style: TextStyle(color: Colors.black, fontSize: 18),
                          ),
                          subtitle:
                              Text(CurrencyData.currency[i].toString() + '  ' + CurrencyData.symbol[i].toString()),
                          onTap: () async {
                            currencySelected =
                                '[' + CurrencyData.code[i].toString() + '] ' + CurrencyData.country[i].toString();
                            currencyIndex = i;
                            //  await Global.settingsBox.put('currencyIndex', i);
                            Navigator.pop(cntxt);
                            setState(() {});
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          Padding(
              padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
              child: Text(
                CurrencyData.symbol[currencyIndex],
                style: TextStyle(color: Colors.green, fontSize: 40, fontWeight: FontWeight.w500),
              )),
          Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: TextButton(
                  style: ButtonStyle(
                      elevation: MaterialStateProperty.all<double>(5.0),
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.limeAccent),
                      foregroundColor: MaterialStateProperty.all<Color>(Colors.white)),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 6, 10, 7),
                    child: Text(
                      'Done',
                      style: GoogleFonts.adventPro(
                          textStyle: TextStyle(
                              color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  onPressed: () async {
                    await Global.settingsBox.put('currencyIndex', currencyIndex);
                    setState(() {});
                  }))
        ],
      )),
    );
  }

  totalsWidget(snapshot) {
    return Container(
        // height: 40,
        padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
        child: Wrap(
          //direction: Axis.horizontal,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
                  child: Text('Total In :    ',
                      style: TextStyle(
                        fontSize: 13,
                      )),
                ),
                Text(
                    '${CurrencyData.symbol[Global.settingsBox.get('currencyIndex')]} ' +
                        ((snapshot.data[2] * pow(10.0, 2)).round().toDouble() / pow(10.0, 2)).toString() +
                        '    ',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Color.fromARGB(
                            //green
                            1000,
                            63,
                            163,
                            52))),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                    padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
                    child: Text('Total Out :    ',
                        style: TextStyle(
                          fontSize: 13,
                        ))),
                Text(
                    '${CurrencyData.symbol[Global.settingsBox.get('currencyIndex')]} ' +
                        ((snapshot.data[3] * pow(10.0, 2)).round().toDouble() / pow(10.0, 2)).toString() +
                        '    ',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Color.fromARGB(
                            //red
                            1000,
                            222,
                            0,
                            0))),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                    padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
                    child: Text('Balance : ',
                        style: TextStyle(
                          fontSize: 13,
                        ))),
                Text(
                    '${CurrencyData.symbol[Global.settingsBox.get('currencyIndex')]} ' +
                        ((snapshot.data[1] * pow(10.0, 2)).round().toDouble() / pow(10.0, 2)).toString(),
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.blue))
              ],
            )
          ],
        ));
  }

  listCard(context, data, i) {
    return Container(
      // width: 100,
      margin: EdgeInsets.fromLTRB(0, 0, 0, 5),
      child: GestureDetector(
        child: Card(
            margin: EdgeInsets.fromLTRB(10, 5, 10, 0),
            child: Container(
              decoration: BoxDecoration(color: Global.mainCardColor),
              child: Padding(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                        child: Row(
                          children: [
                            Text(
                              (i + 1).toString() + '. ',
                              style: TextStyle(
                                  fontSize: 13,
                                  // fontWeight:
                                  //     FontWeight.w600,
                                  color: Colors.blue),
                            ),
                            Text(
                              data['Field'].toString().toUpperCase(),
                              style: TextStyle(fontSize: 13, color: Colors.blue
                                  // fontWeight:
                                  //     FontWeight.w600,
                                  ),
                            ),
                            Spacer(),
                            data['Note'].toString().trim() != '' && data['Note'] != null
                                ? Padding(
                                    padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
                                    child: Icon(Icons.sticky_note_2_outlined, size: 14))
                                : Container(
                                    height: 0,
                                  ),
                            data['attachments'] == null || data['attachments'].length == 0
                                ? Container(
                                    height: 0,
                                  )
                                : Padding(
                                    padding: EdgeInsets.fromLTRB(0, 1, 5, 0), child: Icon(Icons.attach_file, size: 13)),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                              child: Text(
                                data['Date'].toString() +
                                    ', ' +
                                    (data['id'] != null ? Global.getTimeFromMillisEpoch(data['id']) + ' ' : ''),
                                style: TextStyle(fontSize: 13, color: Colors.black54
                                    // fontWeight:
                                    //     FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        )),
                    Row(
                      children: [
                        Expanded(
                            child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  data['Item'].toString().capitalizeFirstofEach + ' ',
                                  style: TextStyle(
                                      // fontWeight:
                                      //     FontWeight.w600,
                                      fontSize: 18,
                                      color: Colors.black),
                                ))),
                        Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              '${CurrencyData.symbol[Global.settingsBox.get('currencyIndex')]} ' +
                                  data['Amount'].toString(),
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: data['Field'].toString() == Global.fieldsForm[0]
                                      ? Color.fromARGB(
                                          //green
                                          1000,
                                          63,
                                          163,
                                          52)
                                      : Color.fromARGB(
                                          //red
                                          1000,
                                          222,
                                          0,
                                          0),
                                  fontSize: 18),
                            ))
                      ],
                    )
                  ],
                ),
              ),
            )),
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext cntxt1) {
              return Align(
                  alignment: Alignment.center,
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                          child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      Icons.share,
                                      color: Global.iconColor,
                                    ),
                                    title: Padding(
                                      padding: EdgeInsets.all(0),
                                      child: Text(
                                        'Share',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.of(cntxt1).pop();

                                      shareData(data);
                                    },
                                  ),
                                  data['Note'].toString().trim() != '' && data['Note'] != null
                                      ? ListTile(
                                          leading: Icon(
                                            Icons.sticky_note_2_rounded,
                                            color: Global.iconColor,
                                          ),
                                          title: Padding(
                                            padding: EdgeInsets.all(0),
                                            child: Text(
                                              'Notes',
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.of(cntxt1).pop();
                                            showNotes(data);
                                          },
                                        )
                                      : Container(
                                          height: 0,
                                        ),
                                  data['attachments'] == null || data['attachments'].length == 0
                                      ? Container(
                                          height: 0,
                                        )
                                      : ListTile(
                                          leading: Icon(
                                            Icons.attach_file,
                                            color: Global.iconColor,
                                          ),
                                          title: Padding(
                                            padding: EdgeInsets.all(0),
                                            child: Text(
                                              'Attachments',
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.of(cntxt1).pop();
                                            showAttachments(data);
                                          },
                                        ),
                                  ListTile(
                                    leading: Icon(
                                      Icons.edit,
                                      color: Global.iconColor,
                                    ),
                                    title: Padding(
                                      padding: EdgeInsets.all(0),
                                      child: Text(
                                        'Edit',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    onTap: () {
                                      //@TODO Add functionality to edit the record...
                                      Global.selectedFormField = data['Field'];
                                      Navigator.of(cntxt1).pop();
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => FormPage(data)))
                                          .then((value) {
                                        setState(() {});
                                        AdsUnits.showInterAd();
                                      });
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(
                                      Icons.delete,
                                      color: Global.iconColor,
                                    ),
                                    title: Padding(
                                      padding: EdgeInsets.all(0),
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.of(cntxt1).pop();
                                      deleteEntry(data);
                                    },
                                  )
                                ],
                              )))));
            },
          );
        },
      ),
    );
  }

  getTaxString(data) {
    var taxString = '';
    if (data['taxes'] != null) {
      List taxList = data['taxes'];
      for (int x = 0; x < taxList.length; x++) {
        if (x == taxList.length - 1) {
          taxString = taxString + taxList[x]['percent'] + '% ' + taxList[x]['name'].toUpperCase();
        } else {
          taxString = taxString + taxList[x]['percent'] + '% ' + taxList[x]['name'].toUpperCase() + ', ';
        }
      }
    }
    return taxString;
  }

  shareData(data) async {
    TextEditingController controller = TextEditingController();

    var text = '${data['Item'].toString().capitalizeFirstofEach}\n\n'
            'Amount : ${CurrencyData.code[Global.settingsBox.get('currencyIndex')]} ${data['Amount']}\n\n' +
        '${data['Date']}\n\n${data['Note']}';

    controller.text = text;

    showDialog(
      context: ctx,
      builder: (BuildContext cntxt) {
        return AlertDialog(
          backgroundColor: Colors.white,
          // title: Text(
          //   'Share',
          //   style: TextStyle(color: Colors.lime),
          // ),
          content: TextFormField(
            maxLines: null,
            controller: controller,
          ),
          actions: [
            Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: TextButton(
                  child: Text('Share',style: TextStyle(color: Global.iconColor)),
                  onPressed: () async {
                    Navigator.of(cntxt).pop();
                    await Share.share(controller.text.trim());
                  },
                ))
          ],
        );
      },
    );
  }

  showNotes(data) {
    showDialog(
      context: context,
      builder: (BuildContext cntxt) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Note"),
          content: Text(data['Note'], style: TextStyle(fontSize: 16, color: Colors.black54)),
          actions: [
            TextButton(
              child: Text("OK",style: TextStyle(color: Global.iconColor)),
              onPressed: () {
                Navigator.of(cntxt).pop();
              },
            ),
          ],
        );
      },
    );
  }

  deleteEntry(data) {
    showDialog(
      context: context,
      builder: (BuildContext cntxt2) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Alert"),
          content: Text("Sure to delete this Entry"),
          actions: [
            TextButton(
              child: Text("No",style: TextStyle(color: Global.iconColor)),
              onPressed: () {
                Navigator.of(cntxt2).pop();
              },
            ),
            TextButton(
              child: Text("Yes",style: TextStyle(color: Global.iconColor)),
              onPressed: () async {
                //var directory = await ExtStorage.getExternalStorageDirectory();
                // await File(listPath[i]).delete().then((value) => numberContent.value++);
                var dataBox = await Hive.openBox('dataBox');
                dataBox.delete(data['id'].toString());

                if (data['attachments'] != null && data['attachments'].length != 0) {
                  for (Map attchMap in data['attachments']) {
                    String path = await Global.getDataDirectoryPath() +
                        '/profile0/attachments/' +
                        data['id'].toString() +
                        '/' +
                        attchMap['attId'].toString() +
                        '.' +
                        attchMap['ext'];
                    File(path).delete();
                  }
                }
                Navigator.of(cntxt2).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  showAttachments(data) {
    //print(data['attachments']);
    showDialog(
      context: context,
      builder: (BuildContext cntxt) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Attachments List"),
          content: Container(
              height: 180,
              width: 100,
              child: ValueListenableBuilder(
                  valueListenable: notifierAttachList,
                  builder: (BuildContext context, int value, Widget? child) {
                    return ListView(
                      controller: attachListScrollController,
                      children: [
                        for (Map attchMap in data['attachments'])
                          Card(
                              margin: EdgeInsets.fromLTRB(5, 5, 20, 5),
                              child: Flex(
                                direction: Axis.horizontal,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () async {
                                            String path = await Global.getDataDirectoryPath() +
                                                '/profile0/attachments/' +
                                                data['id'].toString() +
                                                '/' +
                                                attchMap['attId'].toString() +
                                                '.' +
                                                attchMap['ext'];

                                            OpenFile.open(path);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(color: Colors.blue[50]),
                                            child: Padding(
                                              padding: EdgeInsets.fromLTRB(12, 5, 10, 5),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(attchMap['name'].toString().toUpperCase(),
                                                      style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600)),
                                                  Text(
                                                    attchMap['ext'],
                                                    style: TextStyle(color: Colors.grey, fontSize: 14),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        )),
                                  ),
                                  Expanded(
                                    flex: 0,
                                    child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext cntxt) {
                                                  return AlertDialog(
                                                    backgroundColor: Colors.white,
                                                    title: Text("Alert"),
                                                    content: Text("Sure to delete this Entry"),
                                                    actions: [
                                                      TextButton(
                                                        child: Text("No",style: TextStyle(color: Global.iconColor)),
                                                        onPressed: () {
                                                          Navigator.of(cntxt).pop();
                                                        },
                                                      ),
                                                      TextButton(
                                                        child: Text("Yes",style: TextStyle(color: Global.iconColor)),
                                                        onPressed: () async {
                                                          String path = await Global.getDataDirectoryPath() +
                                                              '/profile0/attachments/' +
                                                              data['id'].toString() +
                                                              '/' +
                                                              attchMap['attId'].toString() +
                                                              '.' +
                                                              attchMap['ext'];

                                                          File file = File(path);
                                                          file.delete();

                                                          data['attachments'].remove(attchMap);
                                                          //await File(listPath[i]).writeAsString(jsonEncode(list[i]));
                                                          var dataBox = await Hive.openBox('dataBox');
                                                          dataBox.put(data['id'].toString(), data);
                                                          notifierAttachList.value++;
                                                          numberContent.value++;

                                                          Navigator.of(cntxt).pop();
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: Padding(
                                                padding: EdgeInsets.all(2),
                                                child: Tooltip(
                                                  message: 'Delete',
                                                  child: Icon(Icons.delete, color: Colors.lime, size: 30),
                                                )))),
                                  )
                                ],
                              ))
                      ],
                    );
                  })),
          actions: [
            TextButton(
              child: Text("OK",style: TextStyle(color: Global.iconColor)),
              onPressed: () {
                Navigator.of(cntxt).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _inFutureList() async {
    double totalAmount = 0;
    double inAmount = 0;
    double outAmount = 0;
    List allFiles = [];

    List srchQrys = searchController.text.trim().replaceAll('  ', ' ').split(' ');
    // srchQrys.remove('');
    DateTime fromDate = DateTime.utc(int.parse(dateFromController.text.split('/')[2]),
        int.parse(dateFromController.text.split('/')[1]), int.parse(dateFromController.text.split('/')[0]));
    DateTime toDate = DateTime.utc(int.parse(dateToController.text.split('/')[2]),
        int.parse(dateToController.text.split('/')[1]), int.parse(dateToController.text.split('/')[0]));

    var dataBox = await Hive.openBox('dataBox');
    List allData = dataBox.values.toList();
    allDataLength = allData.length;
    allData.sort((a, b) => DateTime.utc(
            int.parse(a['Date'].split('/')[2]), int.parse(a['Date'].split('/')[1]), int.parse(a['Date'].split('/')[0]))
        .compareTo(DateTime.utc(int.parse(b['Date'].split('/')[2]), int.parse(b['Date'].split('/')[1]),
            int.parse(b['Date'].split('/')[0]))));

    for (int j = 0; j < allData.length; j++) {
      Map fileMap = allData[j];

      DateTime dt = DateTime.utc(int.parse(fileMap['Date'].split('/')[2]), int.parse(fileMap['Date'].split('/')[1]),
          int.parse(fileMap['Date'].split('/')[0]));

      if (_selectedFieldContent.toLowerCase() == fileMap['Field'].toString().toLowerCase()) {
        //IN
        if ((dt.isAfter(fromDate) || dt.isAtSameMomentAs(fromDate)) &&
            (dt.isBefore(toDate) || dt.isAtSameMomentAs(toDate))) {
          // for (String srchQry in srchQrys) {
          if (searchCondition(fileMap, srchQrys)) {
            if (fileMap['Amount'].toString().trim() != "") {
              if (fileMap['Field'] == Global.fieldsForm[0]) {
                totalAmount = totalAmount + double.parse(fileMap['Amount']);
                inAmount = inAmount + double.parse(fileMap['Amount']);
              } else {
                totalAmount = totalAmount - double.parse(fileMap['Amount']);
                outAmount = outAmount + double.parse(fileMap['Amount']);
              }
            }
            //   if (!allFiles.contains(fileMap)) {
            allFiles.add(fileMap);
            //  }
            // break;
          }
          // }
        }
      } else if (_selectedFieldContent == Global.fieldsContent[0]) {
        //All
        if ((dt.isAfter(fromDate) || dt.isAtSameMomentAs(fromDate)) &&
            (dt.isBefore(toDate) || dt.isAtSameMomentAs(toDate))) {
          //  for (String srchQry in srchQrys) {
          if (searchCondition(fileMap, srchQrys)) {
            if (fileMap['Amount'].toString().trim() != "") {
              if (fileMap['Field'] == Global.fieldsForm[0]) {
                totalAmount = totalAmount + double.parse(fileMap['Amount']);
                inAmount = inAmount + double.parse(fileMap['Amount']);
              } else {
                totalAmount = totalAmount - double.parse(fileMap['Amount']);
                outAmount = outAmount + double.parse(fileMap['Amount']);
              }
            }
            if (!allFiles.contains(fileMap)) {
              allFiles.add(fileMap);
            }
            // break;
          }
          // }
        }
      }
    }

    Global.filteredList = allFiles;
    Global.inAmount = inAmount;
    Global.outAmount = outAmount;
    Global.totalAmount = totalAmount;
    Global.fromDate = dateFromController.text;
    Global.toDate = dateToController.text;
    return [allFiles, totalAmount, inAmount, outAmount];
  }

  bool searchCondition(fileMap, srchQrys) {
    if (fileMap.toString().toLowerCase().contains(srchQrys[0].toLowerCase()) &&
        (srchQrys.length >= 2 ? fileMap.toString().toLowerCase().contains(srchQrys[1].toLowerCase()) : true) &&
        (srchQrys.length >= 3 ? fileMap.toString().toLowerCase().contains(srchQrys[2].toLowerCase()) : true) &&
        (srchQrys.length >= 4 ? fileMap.toString().toLowerCase().contains(srchQrys[3].toLowerCase()) : true) &&
        (srchQrys.length >= 5 ? fileMap.toString().toLowerCase().contains(srchQrys[4].toLowerCase()) : true) &&
        (srchQrys.length >= 6 ? fileMap.toString().toLowerCase().contains(srchQrys[5].toLowerCase()) : true)) {
      return true;
    } else {
      return false;
    }
  }
}
