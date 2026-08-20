import 'dart:io';
import 'package:file_picker/file_picker.dart';
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

  /// Prompts user to pick a location and name a folder for storing Excel reports.
  Future<String?> _setupExportFolderFlow() async {
    // 1. Pick a base directory using system picker
    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Location for Reports Folder',
    );

    if (selectedDirectory == null || selectedDirectory.trim().isEmpty) {
      return null;
    }

    if (!mounted) return null;

    // 2. Ask user for the folder name
    final folderNameController = TextEditingController(text: 'Inspection Reports');
    final formKey = GlobalKey<FormState>();

    final chosenFolderName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.create_new_folder_outlined),
            SizedBox(width: 10),
            Text('Create Reports Folder'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a folder name to create at the selected location:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        selectedDirectory,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: folderNameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.drive_file_rename_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a folder name';
                  }
                  if (value.contains('/') || value.contains('\\') || value.contains(':')) {
                    return 'Folder name cannot contain special characters / \\ :';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, folderNameController.text.trim());
              }
            },
            child: const Text('Create & Save'),
          ),
        ],
      ),
    );

    if (chosenFolderName == null || chosenFolderName.isEmpty) {
      return null;
    }

    final finalPath = '$selectedDirectory/$chosenFolderName';
    final dir = Directory(finalPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await _storageService.saveExportFolderPath(finalPath);
    return finalPath;
  }

  /// Manage or change the export storage location
  Future<void> _manageStorageLocation() async {
    final currentPath = await _storageService.getExportFolderPath();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_special_outlined),
            SizedBox(width: 10),
            Text('Report Storage Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inspection reports are saved directly to this folder on your device:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withAlpha(120),
                ),
              ),
              child: Text(
                currentPath ?? 'No location configured yet.\nYou will be prompted on your first export.',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final newPath = await _setupExportFolderFlow();
              if (newPath != null) {
                _showSuccessSnackBar('Storage location updated.');
              }
            },
            icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
            label: Text(currentPath == null ? 'Set Location' : 'Change Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToExcel() async {
    if (_reports.isEmpty) {
      _showErrorSnackBar('No reports available to export.');
      return;
    }

    // 1. Get or prompt for storage location
    String? folderPath = await _storageService.getExportFolderPath();
    if (folderPath == null || folderPath.isEmpty) {
      // First time export: prompt user for location & folder name
      folderPath = await _setupExportFolderFlow();
      if (folderPath == null) {
        _showErrorSnackBar('Export cancelled. Storage location is required.');
        return;
      }
    } else {
      // Ensure existing folder path directory exists
      final dir = Directory(folderPath);
      if (!await dir.exists()) {
        try {
          await dir.create(recursive: true);
        } catch (_) {
          folderPath = await _setupExportFolderFlow();
          if (folderPath == null) return;
        }
      }
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final filePath = await _excelService.exportToExcel(
        _reports,
        targetDirectoryPath: folderPath,
      );

      if (!mounted) return;

      // Show success dialog with file path and share option
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
          title: const Text('Report Saved to Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The Excel report has been successfully generated and saved to your phone storage:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  filePath,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await Share.shareXFiles(
                  [XFile(filePath)],
                  text: 'Inspection Reports Export',
                );
              },
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share File'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Excel export failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Options',
            onSelected: (value) {
              if (value == 'profile') {
                _editUserProfile();
              } else if (value == 'storage') {
                _manageStorageLocation();
              } else if (value == 'reload') {
                _loadReports();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.account_circle_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Inspector Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'storage',
                child: Row(
                  children: [
                    Icon(Icons.folder_special_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Storage Location'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'reload',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 10),
                    Text('Reload Reports'),
                  ],
                ),
              ),
            ],
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
                      : const Icon(Icons.save_alt_outlined),
                  label: Text(
                    _isExporting ? 'Saving to Device...' : 'Save to Device Storage (.xlsx)',
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
