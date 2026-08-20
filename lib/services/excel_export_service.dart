import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/inspection_report.dart';

class ExcelExportService {
  /// Generate an Excel sheet containing inspection reports,
  /// save it to the specified directory with a unique date-based filename,
  /// and return the absolute file path.
  Future<String> exportToExcel(
    List<InspectionReport> reports, {
    String? targetDirectoryPath,
  }) async {
    // 1. Create a new Excel workbook
    final excel = Excel.createExcel();
    
    // 2. Setup standard sheet name
    const String sheetName = 'Inspection Reports';
    final Sheet sheetObject = excel[sheetName];
    
    // Set default sheet and clean up Sheet1
    excel.setDefaultSheet(sheetName);
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // 3. Setup styling
    final CellStyle headerStyle = CellStyle(
      bold: true,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final CellStyle dataStyle = CellStyle(
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      textWrapping: TextWrapping.WrapText,
    );

    // 4. Write Header Row (Row 0)
    final headers = ['Inspector Name', 'Employee Code', 'Region', 'Serial No.', 'Report'];
    for (int col = 0; col < headers.length; col++) {
      final cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // 5. Write Data Rows (Row 1 onwards)
    for (int row = 0; row < reports.length; row++) {
      final report = reports[row];
      final rowData = [
        report.officerName,
        report.employeeCode,
        report.region,
        report.serialNo,
        report.report,
      ];
      final rowIndex = row + 1;

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
        cell.value = TextCellValue(rowData[col]);
        cell.cellStyle = dataStyle;
      }
    }

    // 6. Set reasonable column widths
    sheetObject.setColumnWidth(0, 22.0); // Inspector Name
    sheetObject.setColumnWidth(1, 16.0); // Employee Code
    sheetObject.setColumnWidth(2, 15.0); // Region
    sheetObject.setColumnWidth(3, 15.0); // Serial No.
    sheetObject.setColumnWidth(4, 60.0); // Report (wrapped)

    // 7. Resolve target directory
    final String resolvedDirPath;
    if (targetDirectoryPath != null && targetDirectoryPath.trim().isNotEmpty) {
      resolvedDirPath = targetDirectoryPath.trim();
    } else {
      final tempDir = await getTemporaryDirectory();
      resolvedDirPath = tempDir.path;
    }

    final targetDir = Directory(resolvedDirPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // 8. Generate a unique name for local storage
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final dateStr = '$year-$month-$day'; // YYYY-MM-DD

    final baseName = 'Inspection_Report_$dateStr';
    const ext = '.xlsx';

    String fileName = '$baseName$ext';
    File file = File('${targetDir.path}/$fileName');
    int counter = 1;

    // Handle duplicates
    while (await file.exists()) {
      final suffix = counter.toString().padLeft(2, '0');
      fileName = '${baseName}_$suffix$ext';
      file = File('${targetDir.path}/$fileName');
      counter++;
    }

    // 9. Save the bytes to the target file
    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Failed to generate Excel file bytes.');
    }

    await file.writeAsBytes(fileBytes, flush: true);
    return file.path;
  }
}
