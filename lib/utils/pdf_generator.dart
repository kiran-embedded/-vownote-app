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

    // Theme Colors
    final baseColor = PdfColors.amber800;
    final accentColor = PdfColors.amber100;
    final textColor = isDarkMode ? PdfColors.white : PdfColors.black;
    final rowEvenColor = isDarkMode ? PdfColors.grey900 : PdfColors.white;
    final rowOddColor = isDarkMode
        ? PdfColors.grey800
        : accentColor; // Darker table rows for dark mode

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.interRegular(),
          bold: await PdfGoogleFonts.interBold(),
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: baseColor, width: 2),
                ),
              ),
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'VowNote',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: baseColor,
                        ),
                      ),
                      pw.Text(
                        'Professional Wedding Management',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: isDarkMode
                              ? PdfColors.grey400
                              : PdfColors.grey700,
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
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      pw.Text(
                        'Monthly Report',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? PdfColors.grey400
                              : PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Statistics Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(
                  'Total Bookings',
                  '${bookings.length}',
                  baseColor,
                  isDarkMode,
                ),
                _buildStatCard(
                  'Total Revenue',
                  'Rs. ${_calculateTotal(bookings)}',
                  PdfColors.green700,
                  isDarkMode,
                ),
                _buildStatCard(
                  'Pending',
                  'Rs. ${_calculatePending(bookings)}',
                  PdfColors.red700,
                  isDarkMode,
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Table
            pw.Table(
              border: null,
              columnWidths: {
                0: const pw.FixedColumnWidth(40), // Date
                1: const pw.FlexColumnWidth(3), // Details
                2: const pw.FlexColumnWidth(3), // Address
                3: const pw.FlexColumnWidth(2), // Financials
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: baseColor),
                  children: [
                    _buildHeaderCell('Date'),
                    _buildHeaderCell('Couple'),
                    _buildHeaderCell('Address / Contact'),
                    _buildHeaderCell('Financials'),
                  ],
                ),
                // Data Rows
                ...bookings.asMap().entries.map((entry) {
                  final index = entry.key;
                  final b = entry.value;
                  final isEven = index % 2 == 0;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? rowEvenColor : rowOddColor,
                    ),
                    children: [
                      // Date with ALL dates
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.topLeft,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            ...b.eventDates.map(
                              (date) => pw.Text(
                                DateFormat('dd MMM').format(date),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Couple Details
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              b.brideName,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            if (b.groomName.isNotEmpty)
                              pw.Text(
                                "w/ ${b.groomName}",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: isDarkMode
                                      ? PdfColors.grey400
                                      : PdfColors.grey700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Address / Contact
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              b.phoneNumber,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              b.address,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: isDarkMode
                                    ? PdfColors.grey400
                                    : PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Financials
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              "Tot: ${b.totalAmount.toStringAsFixed(0)}",
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: textColor,
                              ),
                            ),
                            pw.Text(
                              "Rec: ${b.receivedAmount.toStringAsFixed(0)}",
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.green700,
                              ),
                            ),
                            if (b.pendingAmount > 0)
                              pw.Text(
                                "Due: ${b.pendingAmount.toStringAsFixed(0)}",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Divider(
              color: isDarkMode ? PdfColors.grey700 : PdfColors.grey300,
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated via VowNote Professional',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: isDarkMode ? PdfColors.grey500 : PdfColors.grey500,
                  ),
                ),
                pw.UrlLink(
                  child: pw.Text(
                    'https://github.com/kiran-embedded',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.blue,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  destination: 'https://github.com/kiran-embedded',
                ),
              ],
            ),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Professional Version (c) 2026 kiran-embedded',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: isDarkMode ? PdfColors.grey600 : PdfColors.grey400,
                ),
              ),
            ),
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

  static pw.Widget _buildStatCard(
    String title,
    String value,
    PdfColor color,
    bool isDarkMode,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: isDarkMode ? PdfColors.grey900 : PdfColors.white,
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      width: 150,
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              color: isDarkMode ? PdfColors.grey400 : PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  static String _calculateTotal(List<Booking> bookings) {
    double total = bookings.fold(0, (sum, item) => sum + item.totalAmount);
    return total.toStringAsFixed(0);
  }

  static String _calculatePending(List<Booking> bookings) {
    double total = bookings.fold(0, (sum, item) => sum + item.pendingAmount);
    return total.toStringAsFixed(0);
  }
}
