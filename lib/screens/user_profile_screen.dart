import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/local_storage_service.dart';

class UserProfileScreen extends StatefulWidget {
  final UserProfile? existingProfile;
  final bool isInitialSetup;
  final LocalStorageService? storageService;

  const UserProfileScreen({
    super.key,
    this.existingProfile,
    this.isInitialSetup = false,
    this.storageService,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _employeeCodeController;
  late final LocalStorageService _storageService;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? LocalStorageService();
    _nameController = TextEditingController(text: widget.existingProfile?.name ?? '');
    _employeeCodeController = TextEditingController(text: widget.existingProfile?.employeeCode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final profile = UserProfile(
        name: _nameController.text.trim(),
        employeeCode: _employeeCodeController.text.trim(),
      );

      try {
        await _storageService.saveUserProfile(profile);
        if (mounted) {
          Navigator.pop(context, profile);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save profile: ${e.toString()}'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingProfile != null && !widget.isInitialSetup;

    return PopScope(
      canPop: !widget.isInitialSetup,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing ? 'Edit User Details' : 'Inspector Registration',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: !widget.isInitialSetup,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(100),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_circle_outlined,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    widget.isInitialSetup
                        ? 'Welcome! Please enter your inspector profile details before continuing.'
                        : 'Update your official name and employee identification code.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Full Name Field
                  Text(
                    'Inspector Name',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline),
                      hintText: 'Enter your full name (e.g. John Doe)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Employee Code Field
                  Text(
                    'Employee Code',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _employeeCodeController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge_outlined),
                      hintText: 'Enter Employee Code (e.g. EMP-1042)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your employee code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),

                  // Save / Continue Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(widget.isInitialSetup ? Icons.arrow_forward : Icons.check_circle_outline),
                              const SizedBox(width: 10),
                              Text(
                                widget.isInitialSetup ? 'Save & Continue' : 'Save Details',
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
      ),
    );
  }
}
