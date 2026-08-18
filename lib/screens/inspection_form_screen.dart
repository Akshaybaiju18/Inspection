import 'dart:math';
import 'package:flutter/material.dart';
import '../models/inspection_report.dart';
import '../models/user_profile.dart';

class InspectionFormScreen extends StatefulWidget {
  final InspectionReport? report;
  final UserProfile? userProfile;

  const InspectionFormScreen({
    super.key,
    this.report,
    this.userProfile,
  });

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedRegion;
  late TextEditingController _serialNoController;
  late TextEditingController _reportController;

  final List<String> _regions = ['Cherthala', 'Ernakulam'];

  @override
  void initState() {
    super.initState();
    // Pre-fill values if we are editing an existing report
    _selectedRegion = widget.report?.region;
    _serialNoController = TextEditingController(text: widget.report?.serialNo ?? '');
    _reportController = TextEditingController(text: widget.report?.report ?? '');
  }

  @override
  void dispose() {
    _serialNoController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final officerName = widget.report?.officerName.isNotEmpty == true
          ? widget.report!.officerName
          : (widget.userProfile?.name ?? '');

      final employeeCode = widget.report?.employeeCode.isNotEmpty == true
          ? widget.report!.employeeCode
          : (widget.userProfile?.employeeCode ?? '');

      // Create new report or update existing
      final savedReport = InspectionReport(
        id: widget.report?.id ?? DateTime.now().microsecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
        region: _selectedRegion!,
        serialNo: _serialNoController.text.trim(),
        report: _reportController.text.trim(),
        officerName: officerName,
        employeeCode: employeeCode,
      );

      // Pop back to home screen returning the report
      Navigator.pop(context, savedReport);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.report != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Report' : 'New Report',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header details
                Text(
                  isEditing ? 'Modify report details below' : 'Enter inspection details below',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                const SizedBox(height: 24),

                // Region Dropdown
                Text(
                  'Region',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRegion,
                  hint: const Text('Select Region'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                  ),
                  items: _regions.map((region) {
                    return DropdownMenuItem<String>(
                      value: region,
                      child: Text(region),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a region';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Serial No Input
                Text(
                  'Serial No.',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _serialNoController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.tag),
                    hintText: 'Enter Serial No. (e.g. 001, A-102)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a serial number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Report Input
                Text(
                  'Report Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reportController,
                  maxLines: null,
                  minLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Type your detailed inspection report here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the report text';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // Save Button
                ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_outlined),
                      const SizedBox(width: 10),
                      Text(
                        isEditing ? 'Save Edits' : 'Save Report',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
