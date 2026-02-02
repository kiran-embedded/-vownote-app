import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:vownote/services/business_service.dart';

class PdfGenerator {
  static Future<void> generateMonthlyReport(
    String monthKey,
    List<Booking> bookings, {
    bool isDarkMode = false,
  }) async {
    // Get current business config
    final config = BusinessService().config;

    await _generateReport(
      monthKey,
      bookings,
      isDarkMode,
      'Monthly ${config.pdfTitle}',
    );
  }

  static Future<void> generateGlobalReport(
    List<Booking> bookings, {
    bool isDarkMode = false,
  }) async {
    // Get current business config
    final config = BusinessService().config;

    await _generateReport(
      'Global Report',
      bookings,
      isDarkMode,
      'All-Time ${config.pdfTitle}',
    );
  }

  static Future<void> _generateReport(
    String title,
    List<Booking> bookings,
    bool isDarkMode,
    String subTitle,
  ) async {
    final pdf = pw.Document();
    final prefs = await SharedPreferences.getInstance();

    // Load Settings
    final showMoney = prefs.getBool('show_money_in_pdf') ?? true;
    final showNames = prefs.getBool('show_names_in_export') ?? true;
    final showPhone = prefs.getBool('show_phone_in_export') ?? true;
    final showAddress = prefs.getBool('show_address_in_export') ?? true;
    final showDiary = prefs.getBool('show_diary_in_export') ?? true;

    // Determine font based on language/content
    late pw.Font appFont;
    final lang = LocalizationService().currentLanguage;

    try {
      if (lang == 'ml') {
        appFont = await PdfGoogleFonts.notoSansMalayalamRegular();
      } else if (lang == 'hi') {
        appFont = await PdfGoogleFonts.notoSansDevanagariRegular();
      } else if (lang == 'ta') {
        appFont = await PdfGoogleFonts.notoSansTamilRegular();
      } else if (lang == 'ar') {
        appFont = await PdfGoogleFonts.notoSansArabicRegular();
      } else {
        // Default to Noto Sans for Latin-based languages (En, Es, Fr, De, Id, Pt)
        appFont = await PdfGoogleFonts.notoSansRegular();
      }
    } catch (e) {
      debugPrint('Font loading failed: $e');
      appFont = pw.Font.helvetica();
    }

    // Set the theme
    final myTheme = pw.ThemeData.withFont(base: appFont, bold: appFont);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: myTheme,
        textDirection: pw.TextDirection.ltr,
        build: (context) => [
          _buildHeader(title, subTitle, isDarkMode, appFont),
          pw.SizedBox(height: 20),
          _buildTable(
            bookings,
            showMoney,
            showNames,
            showPhone,
            showAddress,
            showDiary,
            appFont,
          ),
          pw.SizedBox(height: 30),
          if (showMoney) _buildSummary(bookings, appFont),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName = "VowNote_Report_${title.replaceAll(' ', '_')}.pdf";
    final file = File("${output.path}/$fileName");

    // Save PDF without blocking too much if possible
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'VowNote Report: $title');
  }

  static pw.Widget _buildHeader(
    String title,
    String subTitle,
    bool isDarkMode,
    pw.Font font,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'VOWNOTE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber,
                font: font,
              ),
            ),
            pw.Text(
              subTitle,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey,
                font: font,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                font: font,
              ),
            ),
            pw.Text(
              DateFormat('dd MMM yyyy').format(DateTime.now()),
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey,
                font: font,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTable(
    List<Booking> bookings,
    bool showMoney,
    bool showNames,
    bool showPhone,
    bool showAddress,
    bool showDiary,
    pw.Font font,
  ) {
    // Get current business config
    final config = BusinessService().config;

    final headers = [
      if (showDiary) tr('diary_ref'),
      if (showNames) config.customerLabel, // Dynamic Customer Label
      if (config.showClientFields) config.client1Label, // Dynamic Client 1
      if (config.showClientFields) config.client2Label, // Dynamic Client 2
      if (showPhone) tr('phone'),
      if (showAddress) tr('address'),
      config.eventLabelSingular, // Dynamic Event Label
      if (showMoney) tr('total'),
      if (showMoney) tr('adv_received'),
      if (showMoney) tr('due'),
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: bookings.map((b) {
        return [
          if (showDiary) b.displayIdentity,
          if (showNames) b.customerName,
          if (config.showClientFields) b.brideName, // Client 1
          if (config.showClientFields) b.groomName, // Client 2
          if (showPhone) b.phoneNumber,
          if (showAddress) b.address,
          b.eventDates.map((d) => DateFormat('dd/MM').format(d)).join('\n'),
          if (showMoney) '₹${b.totalAmount.toStringAsFixed(0)}',
          if (showMoney) '₹${b.advanceReceived.toStringAsFixed(0)}',
          if (showMoney) '₹${b.pendingAmount.toStringAsFixed(0)}',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 9,
        font: font,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.amber),
      cellStyle: pw.TextStyle(fontSize: 8, font: font),
      cellHeight: 25,
      cellAlignments: {
        for (var i = 0; i < headers.length; i++) i: pw.Alignment.center,
        if (showNames)
          headers.indexOf(config.customerLabel): pw.Alignment.centerLeft,
        if (showAddress)
          headers.indexOf(tr('address')): pw.Alignment.centerLeft,
        if (showMoney) headers.indexOf(tr('total')): pw.Alignment.centerRight,
        if (showMoney)
          headers.indexOf(tr('adv_received')): pw.Alignment.centerRight,
        if (showMoney) headers.indexOf(tr('due')): pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildSummary(List<Booking> bookings, pw.Font font) {
    double total = 0;
    double received = 0;
    double advReceived = 0;
    for (var b in bookings) {
      total += b.totalAmount;
      received += b.receivedAmount;
      advReceived += b.advanceReceived;
    }

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildSummaryRow(tr('total'), total, font),
          _buildSummaryRow(tr('adv_received'), advReceived, font),
          _buildSummaryRow(tr('received'), received, font),
          pw.Divider(),
          _buildSummaryRow(tr('due'), total - received, font, isBold: true),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    double amount,
    pw.Font font, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : null,
              font: font,
            ),
          ),
          pw.Text(
            '₹${amount.toStringAsFixed(0)}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : null,
              font: font,
            ),
          ),
        ],
      ),
    );
  }
}
