import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspection_report/main.dart';
import 'package:inspection_report/models/inspection_report.dart';
import 'package:inspection_report/models/user_profile.dart';
import 'package:inspection_report/services/local_storage_service.dart';

class MockLocalStorageService extends Fake implements LocalStorageService {
  @override
  Future<UserProfile?> loadUserProfile() async {
    return UserProfile(name: 'Test Officer', employeeCode: 'EMP-001');
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    return;
  }

  @override
  Future<List<InspectionReport>> loadReports() async {
    return [];
  }

  @override
  Future<void> saveReports(List<InspectionReport> reports) async {
    return;
  }
}

void main() {
  testWidgets('Smoke test for Inspection Reports App', (WidgetTester tester) async {
    final mockStorage = MockLocalStorageService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      InspectionReportApp(
        storageService: mockStorage,
      ),
    );
    
    // Verify that we initially show a loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the loading future execute (runs microtasks) and rebuild
    await tester.pump();

    // Verify that we start on the home screen showing the app bar title.
    expect(find.text('Inspection Reports'), findsOneWidget);

    // Verify that we display the empty state message.
    expect(find.text('No inspection reports yet'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
