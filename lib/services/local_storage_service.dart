import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/inspection_report.dart';

class LocalStorageService {
  static const String _fileName = 'inspection_reports.json';

  /// Get the local file path for storing inspection reports.
  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Load inspection reports from local storage.
  Future<List<InspectionReport>> loadReports() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        if (kDebugMode) {
          print('Local storage file does not exist. Returning empty list.');
        }
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      
      return jsonList
          .map((jsonItem) => InspectionReport.fromJson(jsonItem as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading reports from local storage: $e');
      }
      // Return empty list on failure as per specs (error handling).
      return [];
    }
  }

  /// Save the list of inspection reports to local storage.
  Future<void> saveReports(List<InspectionReport> reports) async {
    try {
      final file = await _getLocalFile();
      final jsonList = reports.map((report) => report.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await file.writeAsString(jsonString);
      if (kDebugMode) {
        print('Saved ${reports.length} reports successfully to local storage.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving reports to local storage: $e');
      }
      rethrow; // Propagate the error so UI/caller can show a user-friendly error message.
    }
  }
}
