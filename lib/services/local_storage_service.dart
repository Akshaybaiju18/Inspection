import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/inspection_report.dart';
import '../models/user_profile.dart';

class LocalStorageService {
  static const String _reportsFileName = 'inspection_reports.json';
  static const String _profileFileName = 'user_profile.json';

  /// Get local file handle for specified filename.
  Future<File> _getFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  /// Load user profile from local JSON file.
  Future<UserProfile?> loadUserProfile() async {
    try {
      final file = await _getFile(_profileFileName);
      if (!await file.exists()) {
        return null;
      }
      final jsonString = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final profile = UserProfile.fromJson(jsonMap);
      return profile.isComplete ? profile : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user profile: $e');
      }
      return null;
    }
  }

  /// Save user profile to local JSON file.
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final file = await _getFile(_profileFileName);
      final jsonString = jsonEncode(profile.toJson());
      await file.writeAsString(jsonString);
      if (kDebugMode) {
        print('User profile saved successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user profile: $e');
      }
      rethrow;
    }
  }

  /// Load inspection reports from local storage.
  Future<List<InspectionReport>> loadReports() async {
    try {
      final file = await _getFile(_reportsFileName);
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
      return [];
    }
  }

  /// Save the list of inspection reports to local storage.
  Future<void> saveReports(List<InspectionReport> reports) async {
    try {
      final file = await _getFile(_reportsFileName);
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
      rethrow;
    }
  }
}
