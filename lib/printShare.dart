// import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:math';

import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import 'adsUnits.dart';
import 'global.dart';

class PrintShare extends material.StatelessWidget {
  PrintShare();

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      appBar: material.AppBar(
        title: material.Text("Print or Share"),
        // actions: [
        //   MoveWindow(
        //     child: material.Container(
        //       decoration: material.BoxDecoration(color: material.Colors.green),
        //       width: material.MediaQuery.of(context).size.width - 350,
        //       padding: material.EdgeInsets.all(10),
        //     ),
        //   ),
        //  // WindowButtons()
        // ],
      ),
      body: PdfPreview(
        initialPageFormat: PdfPageFormat.a4,
        maxPageWidth: 800,
        build: (format) => reportView(context),
      ),
    );
  }
}

FutureOr<Uint8List> reportView(context) async {
  List list = Global.filteredList;
  final Document pdf = Document();

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

  pdf.addPage(MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: 19,
        marginRight: 19,
        marginTop: 19,
        marginBottom: 19,
      ),
      crossAxisAlignment: CrossAxisAlignment.start,
      footer: (Context context) {
        return Container(
            alignment: Alignment.centerRight,
            margin: const EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: Text('Page ${context.pageNumber} of ${context.pagesCount}',
                style: Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black)));
      },
      build: (Context context) => <Widget>[
            Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                      child: Text(
                        Global.brandInfoBox.get('brandName') ?? '',
                        style: TextStyle(
                          fontSize: 30,
                          color: PdfColors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                  Padding(
                      padding: EdgeInsets.fromLTRB(10, 0, 0, 5),
                      child: Text(
                        'Records',
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 1,
                          color: PdfColors.black,
                        ),
                      )),
                  Spacer(),
                  Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                      child: Text('     From: ' + Global.fromDate + '  To: ' + Global.toDate))
                ],
              ),
              Container(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                  margin: EdgeInsets.fromLTRB(10, 20, 0, 15),
                  decoration: BoxDecoration(
                      border: Border(
                    bottom: BorderSide(
                      color: PdfColors.black,
                      width: 0.1,
                    ),
                  )),
                  child: Row(children: [
                    Padding(
                        padding: EdgeInsets.fromLTRB(0, 2, 0, 0),
                        child: Text('Total In : ',
                            style: TextStyle(
                                //  fontWeight:
                                // FontWeight.w500,
                                fontSize: 11))),
                    Text(((Global.inAmount * pow(10.0, 2)).round().toDouble() / pow(10.0, 2)).toString() + '   ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: PdfColors.green)),
                    Padding(
                        padding: EdgeInsets.fromLTRB(0, 2, 0, 0),
                        child: Text('Total Out : ',
                            style: TextStyle(
                                //  fontWeight:
                                // FontWeight.w500,
                                fontSize: 11))),
                    Text(((Global.outAmount * pow(10.0, 2)).round().toDouble() / pow(10.0, 2)).toString() + '   ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: PdfColors.red)),
                    Padding(
                        padding: EdgeInsets.fromLTRB(0, 2, 0, 0),
                        child: Text('Total Profit : ',
                            style: TextStyle(
                                //  fontWeight:
                                // FontWeight.w500,
                                fontSize: 11))),
                    Text(((Global.totalAmount * pow(10.0, 2)).round().toDouble() / pow(10.0, 2)).toString() + '      ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: PdfColors.blue))
                  ])),
              for (int i = list.length - 1; i >= 0; i--)
                Container(
                    margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    decoration: BoxDecoration(
                        color: (i.isEven ? PdfColor(0.95, 0.95, 0.95) : PdfColors.white),
                        border: Border(
                          bottom: BorderSide(
                            color: PdfColors.black,
                            width: 0.1,
                          ),
                        )),
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (i + 1).toString() + '. ',
                              style: TextStyle(fontWeight: FontWeight.bold, color: PdfColors.blue),
                            ),
                            Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(list[i]['Date'].toString() + '  '),
                                        Text(list[i]['Field'].toString() + '  '),
                                        Text(
                                          list[i]['Item'].toString().toUpperCase(),
                                          style: TextStyle(fontWeight: FontWeight.bold, color: PdfColors.blue),
                                        ),
                                        list[i]['Field'].toString() == Global.fieldsForm[0] ||
                                                list[i]['Field'].toString() == Global.fieldsForm[1]
                                            ? Text(' ' + list[i]['Category'], style: TextStyle(color: PdfColors.black))
                                            : Text(''),
                                      ]),
                                  list[i]['Field'].toString() == Global.fieldsForm[0] ||
                                          list[i]['Field'].toString() == Global.fieldsForm[1]
                                      ? Text(
                                          (list[i]['Customer'] != null && list[i]['Customer'] != ''
                                                  ? ('To ' + list[i]['Customer'])
                                                  : list[i]['Seller'] != null && list[i]['Seller'] != ''
                                                      ? ('From ' + list[i]['Seller'])
                                                      : '') +
                                              '  ',
                                          style: TextStyle(fontSize: 10, color: PdfColors.black))
                                      : Text(''),
                                  list[i]['Field'].toString() == Global.fieldsForm[0] ||
                                          list[i]['Field'].toString() == Global.fieldsForm[1]
                                      ? Wrap(
                                          children: [
                                            Text(
                                              'Qty. ' + list[i]['Quantity'].toString(),
                                              style: TextStyle(fontSize: 11, color: PdfColors.black),
                                            ),
                                            Text(
                                              ' * ',
                                              style: TextStyle(fontSize: 11, color: PdfColors.black),
                                            ),
                                            Text(
                                              list[i]['Price per Unit'].toString(),
                                              style: TextStyle(fontSize: 11, color: PdfColors.black),
                                            ),
                                            Text(
                                              (list[i]['Field'].toString() == Global.fieldsForm[0]
                                                  ? '  ' + getTaxString(list[i]).replaceAll(',', ' ')
                                                  : ''),
                                              style: TextStyle(fontSize: 11, color: PdfColors.black),
                                            )
                                          ],
                                        )
                                      : Text(''),
                                ]),
                            Spacer(),
                            list[i]['Field'].toString() == Global.fieldsForm[0]
                                ? Text(
                                    '+' + list[i]['Amount'].toString(),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: PdfColors.green),
                                  )
                                : Text(
                                    '-' + list[i]['Amount'].toString(),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: PdfColors.red),
                                  ),
                          ],
                        ))
                    //Spacer()
                    )
            ]),
          ]));
  //save PDF

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
