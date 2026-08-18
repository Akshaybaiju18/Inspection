import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inspection_report.dart';
import '../models/user_profile.dart';
import '../services/local_storage_service.dart';
import '../services/excel_export_service.dart';
import 'inspection_form_screen.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final LocalStorageService? storageService;
  final ExcelExportService? excelService;

  const HomeScreen({
    super.key,
    this.storageService,
    this.excelService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LocalStorageService _storageService;
  late final ExcelExportService _excelService;

  UserProfile? _userProfile;
  List<InspectionReport> _reports = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? LocalStorageService();
    _excelService = widget.excelService ?? ExcelExportService();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final profile = await _storageService.loadUserProfile();
      final reports = await _storageService.loadReports();

      setState(() {
        _userProfile = profile;
        _reports = reports;
      });

      // If user profile is missing, force profile registration on first launch
      if (profile == null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _promptInitialProfileSetup();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load local data.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _promptInitialProfileSetup() async {
    final newProfile = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          isInitialSetup: true,
          storageService: _storageService,
        ),
      ),
    );

    if (newProfile != null && mounted) {
      setState(() {
        _userProfile = newProfile;
      });
      _showSuccessSnackBar('Welcome, ${newProfile.name}!');
    }
  }

  Future<void> _editUserProfile() async {
    final updatedProfile = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          existingProfile: _userProfile,
          storageService: _storageService,
        ),
      ),
    );

    if (updatedProfile != null && mounted) {
      setState(() {
        _userProfile = updatedProfile;
      });
      _showSuccessSnackBar('Profile updated successfully.');
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final reports = await _storageService.loadReports();
      setState(() {
        _reports = reports;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load saved reports.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewReport() async {
    if (_userProfile == null) {
      await _promptInitialProfileSetup();
      if (_userProfile == null) return;
    }

    if (!mounted) return;

    final result = await Navigator.push<InspectionReport>(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionFormScreen(
          userProfile: _userProfile,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _reports.add(result);
      });
      await _saveReportsToStorage();
      _showSuccessSnackBar('Report saved successfully.');
    }
  }

  Future<void> _editReport(InspectionReport report) async {
    final result = await Navigator.push<InspectionReport>(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionFormScreen(
          report: report,
          userProfile: _userProfile,
        ),
      ),
    );

    if (result != null) {
      final index = _reports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        setState(() {
          _reports[index] = result;
        });
        await _saveReportsToStorage();
        _showSuccessSnackBar('Report updated successfully.');
      }
    }
  }

  Future<void> _deleteReport(InspectionReport report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _reports.removeWhere((r) => r.id == report.id);
      });
      await _saveReportsToStorage();
      _showSuccessSnackBar('Report deleted successfully.');
    }
  }

  Future<void> _saveReportsToStorage() async {
    try {
      await _storageService.saveReports(_reports);
    } catch (e) {
      _showErrorSnackBar('Failed to save data to storage.');
    }
  }

  Future<void> _exportToExcel() async {
    if (_reports.isEmpty) {
      _showErrorSnackBar('No reports available to export.');
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final filePath = await _excelService.exportToExcel(_reports);
      
      // Notify user of generation success
      _showSuccessSnackBar('Excel export generated successfully.');

      // Launch share sheet
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Inspection Reports Export',
      );

      if (result.status == ShareResultStatus.dismissed) {
        debugPrint('Share sheet was dismissed.');
      }
    } catch (e) {
      _showErrorSnackBar('Excel generation or sharing failed: ${e.toString()}');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inspection Reports',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (_userProfile != null)
              Text(
                'Inspector: ${_userProfile!.name} (${_userProfile!.employeeCode})',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(180),
                ),
              ),
          ],
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'User Profile',
            onPressed: _editUserProfile,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Reports',
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? _buildEmptyState(theme)
              : _buildReportList(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isExporting ? null : _addNewReport,
        label: const Text('New Report'),
        icon: const Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      bottomNavigationBar: _reports.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportToExcel,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.file_download_outlined),
                  label: Text(
                    _isExporting ? 'Generating Excel...' : 'Export to Excel',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 80,
              color: theme.colorScheme.primary.withAlpha(102),
            ),
            const SizedBox(height: 20),
            Text(
              'No inspection reports yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Create your first inspection report using the button below.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        final isCherthala = report.region.toLowerCase() == 'cherthala';

        return Card(
          key: ValueKey(report.id),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(128),
            ),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                // Region Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCherthala
                        ? Colors.teal.shade50
                        : Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCherthala
                          ? Colors.teal.shade200
                          : Colors.deepPurple.shade200,
                    ),
                  ),
                  child: Text(
                    report.region,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCherthala
                          ? Colors.teal.shade800
                          : Colors.deepPurple.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Serial No.
                Expanded(
                  child: Text(
                    'Serial No: ${report.serialNo}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                report.report,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(204),
                ),
              ),
            ),
            childrenPadding: const EdgeInsets.all(16.0),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(),
              if (report.officerName.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Inspector: ${report.officerName} (${report.employeeCode})',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              // Detailed report view
              Text(
                'Full Report:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                report.report,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _editReport(report),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => _deleteReport(report),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
