import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vownote/models/booking.dart';

class PdfGenerator {
  static Future<void> generateMonthlyReport(
    String monthName,
    List<Booking> bookings, {
    bool isDarkMode = false,
  }) async {
    final pdf = pw.Document();

    // Premium Theme (Gold & Dark)
    final goldColor = PdfColor.fromInt(0xFFD4AF37);
    final backgroundColor = isDarkMode
        ? PdfColor.fromInt(0xFF000000)
        : PdfColors.white;
    final cardColor = isDarkMode
        ? PdfColor.fromInt(0xFF1C1C1E)
        : PdfColor.fromInt(0xFFF2F2F7);
    final primaryTextColor = isDarkMode
        ? PdfColors.white
        : PdfColor.fromInt(0xFF1C1C1E);
    final secondaryTextColor = isDarkMode
        ? PdfColors.grey400
        : PdfColors.grey700;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.interRegular(),
          bold: await PdfGoogleFonts.interBold(),
          italic: await PdfGoogleFonts.interItalic(),
        ),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VowNote',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: goldColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.Container(
                      height: 2,
                      width: 40,
                      color: goldColor,
                      margin: const pw.EdgeInsets.only(top: 2, bottom: 4),
                    ),
                    pw.Text(
                      'PRO LUXE EDITION',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: secondaryTextColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      monthName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    pw.Text(
                      'Booking Summary Report',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.only(top: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Generated via VowNote Professional v1.0',
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey500,
                      ),
                    ),
                    pw.UrlLink(
                      child: pw.Text(
                        'github.com/kiran-embedded/-vownote-app',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.blue,
                        ),
                      ),
                      destination:
                          'https://github.com/kiran-embedded/-vownote-app',
                    ),
                  ],
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                ),
                pw.Text(
                  '© 2026 kiran-embedded | Professional Version',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Analytics Dashboard
            pw.Row(
              children: [
                _buildModernStat(
                  'BOOKINGS',
                  '${bookings.length}',
                  goldColor,
                  isDarkMode,
                ),
                pw.SizedBox(width: 15),
                _buildModernStat(
                  'TOTAL VALUE',
                  'Rs. ${_calculateTotal(bookings)}',
                  PdfColors.green800,
                  isDarkMode,
                ),
                pw.SizedBox(width: 15),
                _buildModernStat(
                  'DUE BALANCE',
                  'Rs. ${_calculatePending(bookings)}',
                  PdfColors.red800,
                  isDarkMode,
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Table Header
            pw.Container(
              decoration: pw.BoxDecoration(
                color: goldColor,
                borderRadius: const pw.BorderRadius.vertical(
                  top: pw.Radius.circular(4),
                ),
              ),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: _thinHeader('DATE')),
                  pw.Expanded(flex: 4, child: _thinHeader('COUPLE DETAILS')),
                  pw.Expanded(
                    flex: 4,
                    child: _thinHeader('LOCATION & CONTACT'),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: _thinHeader(
                      'FINANCIALS',
                      align: pw.Alignment.centerRight,
                    ),
                  ),
                ],
              ),
            ),

            // Luxury List
            ...bookings.asMap().entries.map((entry) {
              final b = entry.value;
              final useBg = entry.key % 2 != 0;
              return pw.Container(
                decoration: pw.BoxDecoration(
                  color: useBg ? cardColor : backgroundColor,
                ),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // DATES
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: b.eventDates
                            .map(
                              (d) => pw.Text(
                                DateFormat('dd MMM').format(d),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    // COUPLE
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            b.brideName,
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          if (b.groomName.isNotEmpty)
                            pw.Text(
                              'w/ ${b.groomName}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: secondaryTextColor,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // CONTACT
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            b.phoneNumber,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            b.address,
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // FINANCIALS
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Total: Rs. ${b.totalAmount.toStringAsFixed(0)}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: primaryTextColor,
                            ),
                          ),
                          pw.Text(
                            'Paid: Rs. ${b.receivedAmount.toStringAsFixed(0)}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.green700,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (b.pendingAmount > 0)
                            pw.Text(
                              'Due: Rs. ${b.pendingAmount.toStringAsFixed(0)}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.red700,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          if (b.isCompleted)
                            pw.Container(
                              margin: const pw.EdgeInsets.only(top: 4),
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.grey200,
                                borderRadius: pw.BorderRadius.all(
                                  pw.Radius.circular(2),
                                ),
                              ),
                              child: pw.Text(
                                'COMPLETED',
                                style: pw.TextStyle(
                                  fontSize: 6,
                                  color: PdfColors.grey700,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // Summary Table Bottom
            pw.Container(height: 1, color: goldColor),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      "${output.path}/VowNote_${monthName.replaceAll(' ', '_')}.pdf",
    );
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Monthly Booking Report - $monthName');
  }

  static pw.Widget _thinHeader(
    String text, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 8,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static pw.Widget _buildModernStat(
    String title,
    String value,
    PdfColor accent,
    bool isDarkMode,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: isDarkMode
              ? PdfColor.fromInt(0xFF1C1C1E)
              : PdfColor.fromInt(0xFFF2F2F7),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border(left: pw.BorderSide(color: accent, width: 4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey500,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _calculateTotal(List<Booking> bookings) {
    double total = bookings.fold(0, (sum, item) => sum + item.totalAmount);
    return NumberFormat('#,##,###').format(total);
  }

  static String _calculatePending(List<Booking> bookings) {
    double total = bookings.fold(0, (sum, item) => sum + item.pendingAmount);
    return NumberFormat('#,##,###').format(total);
  }
}
