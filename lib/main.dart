import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/local_storage_service.dart';
import 'services/excel_export_service.dart';

void main() {
  runApp(const InspectionReportApp());
}

class InspectionReportApp extends StatelessWidget {
  final LocalStorageService? storageService;
  final ExcelExportService? excelService;

  const InspectionReportApp({
    super.key,
    this.storageService,
    this.excelService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspection Reports',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Elegant Navy Slate
          brightness: Brightness.light,
        ),
        // Typography and spacing styling
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 2,
          scrolledUnderElevation: 3,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 2,
        ),
      ),
      themeMode: ThemeMode.system, // Auto dark/light depending on system settings
      home: HomeScreen(
        storageService: storageService,
        excelService: excelService,
      ),
    );
  }
}
