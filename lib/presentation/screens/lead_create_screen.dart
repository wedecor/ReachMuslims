import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/user.dart';
import '../providers/lead_create_provider.dart';
import '../providers/auth_provider.dart';

class LeadCreateScreen extends ConsumerStatefulWidget {
  const LeadCreateScreen({super.key});

  @override
  ConsumerState<LeadCreateScreen> createState() => _LeadCreateScreenState();
}

class _LeadCreateScreenState extends ConsumerState<LeadCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final createState = ref.read(leadCreateProvider);
    if (!createState.isValid) {
      return;
    }

    final createdLead = await ref.read(leadCreateProvider.notifier).createLead();

    if (createdLead != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lead created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, createdLead);
    } else if (mounted) {
      final error = ref.read(leadCreateProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(leadCreateProvider);
    final authState = ref.watch(authProvider);

    // Check if user is admin
    if (!authState.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Lead')),
        body: const Center(
          child: Text('Access denied. Admin only.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lead'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
                onChanged: (value) {
                  ref.read(leadCreateProvider.notifier).setName(value);
                },
              ),
              const SizedBox(height: 16),
              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone is required';
                  }
                  final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                  if (digitsOnly.length < 10) {
                    return 'Please enter a valid phone number (at least 10 digits)';
                  }
                  return null;
                },
                onChanged: (value) {
                  ref.read(leadCreateProvider.notifier).setPhone(value);
                },
              ),
              const SizedBox(height: 16),
              // Location field
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  ref.read(leadCreateProvider.notifier).setLocation(value.isEmpty ? null : value);
                },
              ),
              const SizedBox(height: 16),
              // Region dropdown
              DropdownButtonFormField<UserRegion>(
                value: createState.region,
                decoration: InputDecoration(
                  labelText: 'Region *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: UserRegion.values.map((region) {
                  return DropdownMenuItem<UserRegion>(
                    value: region,
                    child: Text(region.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (region) {
                  if (region != null) {
                    ref.read(leadCreateProvider.notifier).setRegion(region);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Status dropdown
              DropdownButtonFormField<LeadStatus>(
                value: createState.status,
                decoration: InputDecoration(
                  labelText: 'Status *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: LeadStatus.values.map((status) {
                  return DropdownMenuItem<LeadStatus>(
                    value: status,
                    child: Text(status.displayName),
                  );
                }).toList(),
                onChanged: (status) {
                  if (status != null) {
                    ref.read(leadCreateProvider.notifier).setStatus(status);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Assigned To field (optional)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Assigned To (User UID, optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  ref.read(leadCreateProvider.notifier).setAssignedTo(value.isEmpty ? null : value);
                },
              ),
              const SizedBox(height: 32),
              // Error message
              if (createState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    createState.error!.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Submit button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: createState.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: createState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Lead',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

