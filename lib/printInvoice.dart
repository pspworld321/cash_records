import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Currency.dart';
import 'global.dart';

class PrintInvoice extends material.StatefulWidget {
  var data;

  PrintInvoice(this.data);

  @override
  material.State<material.StatefulWidget> createState() {
    return _PrintInvoiceState(data);
  }
}

class _PrintInvoiceState extends material.State<PrintInvoice> {
  var data;

  _PrintInvoiceState(this.data);

  Document pdf = Document();

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      appBar: material.AppBar(
        title: material.Text('Print Invoice'),
      ),
      body: PdfPreview(
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        actions: [],
        initialPageFormat: PdfPageFormat.a4,
        maxPageWidth: 800,
        build: (format) => reportView(context),
      ),
    );
  }

  FutureOr<Uint8List> reportView(context) async {
    var fontSize0 = 9.0;
    var fontSize1 = 10.0;
    var fontSize2 = 10.0;
    var fontSize3 = 11.0;
    var fontSize4 = 13.0;
    var fontSize5 = 14.0;
    var fontSizeLarge = 30.0;

    final font = await rootBundle.load("assets/notosans-regular.ttf");
    final ttf = Font.ttf(font);
    final fontBold = await rootBundle.load("assets/notosans-bold.ttf");
    final ttfBold = Font.ttf(fontBold);
    final fontItalic = await rootBundle.load("assets/notosans-italic.ttf");
    final ttfItalic = Font.ttf(fontItalic);
    final fontBoldItalic = await rootBundle.load("assets/notosans-boldItalic.ttf");
    final ttfBoldItalic = Font.ttf(fontBoldItalic);
    final ThemeData theme = ThemeData.withFont(
      base: ttf,
      bold: ttfBold,
      italic: ttfItalic,
      boldItalic: ttfBoldItalic,
    );

    try {
      pdf.addPage(MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4.copyWith(
            marginLeft: 50,
            marginRight: 50,
            marginTop: 50,
            marginBottom: 50,
          ),
          crossAxisAlignment: CrossAxisAlignment.start,
          header: (Context context) {
            return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Flex(
                  direction: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(flex: 1,child:   Text(
                  Global.brandInfoBox.get('brandName') ?? '',
                  style: TextStyle(
                    fontSize: 30,
                    color: PdfColors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                  Expanded(flex: 0,child: Text(
                  'Invoice\n' +
                      data['Date'].toString() +
                      ', ' +
                      (data['id'] != null ? Global.getTimeFromMillisEpoch(data['id']) + ' ' : ''),
                  style: TextStyle(
                    fontSize: 15,
                    color: PdfColors.black,
                  ),textAlign: TextAlign.right
                ))
              ]),
              Container(height: 2, color: PdfColors.black)
            ]);
          },
          footer: (Context context) {
            return Container(
                color: PdfColors.blue50,
                padding: EdgeInsets.all(15),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Global.brandInfoBox.get('brandMob') != null && Global.brandInfoBox.get('brandMob') != ''
                        ? Text('Mob. : ' + Global.brandInfoBox.get('brandMob') + '    ')
                        : Container(height: 0, width: 0),
                    Global.brandInfoBox.get('brandEmail') != null && Global.brandInfoBox.get('brandEmail') != ''
                        ? Text('Email : ' + Global.brandInfoBox.get('brandEmail'))
                        : Container(height: 0, width: 0)
                  ]),
                  Row(children: [
                    Global.brandInfoBox.get('brandRegName') != null && Global.brandInfoBox.get('brandRegName') != ''
                        ? Text(Global.brandInfoBox.get('brandRegName') + ' : ')
                        : Container(height: 0, width: 0),
                    Global.brandInfoBox.get('brandRegNo') != null && Global.brandInfoBox.get('brandRegNo') != ''
                        ? Text(Global.brandInfoBox.get('brandRegNo'))
                        : Container(height: 0, width: 0)
                  ]),
                  Global.brandInfoBox.get('brandAddress') != null && Global.brandInfoBox.get('brandAddress') != ''
                      ? Text('Address : ' + Global.brandInfoBox.get('brandAddress'))
                      : Container(height: 0, width: 0),
                  Global.brandInfoBox.get('brandDetails') != null && Global.brandInfoBox.get('brandDetails') != ''
                      ? Text( Global.brandInfoBox.get('brandDetails'))
                      : Container(height: 0, width: 0),
                ]));
          },
          build: (Context context) => <Widget>[
                Container(
                  // width: 100,
                  margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.start,
                        children: [
                          Text( data['Item'].toString().capitalizeFirstofEach + ' ',
                            style: TextStyle(
                                // fontWeight:
                                //     FontWeight.w600,
                                fontSize: 20,
                                color: PdfColors.black),
                          ),
                          data['Field'].toString() == Global.fieldsForm[0] ||
                                  data['Field'].toString() == Global.fieldsForm[1]
                              ? Text(data['Category'].toString().capitalizeFirstofEach,
                                  style: TextStyle(fontSize: 18, color: PdfColors.black))
                              : Container(
                                  height: 0,
                                ),
                        ],
                      ),
                      Padding(
                          padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
                          child: Text('To ' + data['Customer'].toString().capitalizeFirstofEach,
                              style: TextStyle(fontSize: 16, color: PdfColors.black))),
                      Flex(
                        direction: Axis.horizontal,
                        children: [
                          Expanded(
                              flex: 1,
                              child: Wrap(children: [
                                Text(
                                  'Qty. ' + data['Quantity'].toString(),
                                  style: TextStyle(color: PdfColors.black, fontSize: 15),
                                ),
                                Text(
                                  ' * ',
                                  style: TextStyle(color: PdfColors.black, fontSize: 15),
                                ),
                                Text(
                                  '${CurrencyData.code[Global.settingsBox.get('currencyIndex')]} ' +
                                      data['Price per Unit'].toString(),
                                  style: TextStyle(color: PdfColors.black, fontSize: 15),
                                ),
                                if (data['Field'].toString() == Global.fieldsForm[0])
                                  Padding(
                                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                      child: Text(
                                        '  ' + '${getTaxString(data).replaceAll(',', ' ')}' + ' =  ',
                                        style: TextStyle(color: PdfColors.black, fontSize: 15),
                                        // textAlign: TextAlign.end,
                                      )),
                              ])),
                          Expanded(
                              flex: 0,
                              child: Text(
                                '${CurrencyData.code[Global.settingsBox.get('currencyIndex')]} ' +
                                    data['Amount'].toString(),
                                style: TextStyle(fontWeight: FontWeight.bold, color: PdfColors.black, fontSize: 20),
                              ))
                        ],
                      ),
                      Container(margin: EdgeInsets.fromLTRB(0, 10, 0, 0), height: 1, color: PdfColors.blueAccent)
                    ],
                  ),
                ),
              ]));
    } catch (e, s) {
      print(e);
      print(s);
    }

    return pdf.save();
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
}
//@todo pdf not loading if all fields are empty
//@todo apna wala share button with msg, sub, file name
