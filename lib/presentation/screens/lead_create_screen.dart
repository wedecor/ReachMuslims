import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/user.dart';
import '../providers/lead_create_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_list_provider.dart';
import '../../core/utils/region_based_phone_formatter.dart';

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

    // Check if user is authenticated
    if (!authState.isAuthenticated || authState.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Lead')),
        body: const Center(
          child: Text('Please log in to create leads.'),
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
                  hintText: createState.region == UserRegion.usa 
                      ? '(XXX) XXX-XXXX' 
                      : 'XXXX-XXXXXX',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  RegionBasedPhoneFormatter(createState.region),
                ],
                validator: (value) {
                  return PhoneNumberValidator.validate(value, createState.region);
                },
                onChanged: (value) {
                  // Store only digits in the provider
                  final digitsOnly = PhoneNumberValidator.getDigitsOnly(value);
                  ref.read(leadCreateProvider.notifier).setPhone(digitsOnly);
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
                    // Update phone field formatting when region changes
                    final currentPhone = _phoneController.text;
                    if (currentPhone.isNotEmpty) {
                      final digitsOnly = PhoneNumberValidator.getDigitsOnly(currentPhone);
                      final formatter = RegionBasedPhoneFormatter(region);
                      final formatted = formatter.formatEditUpdate(
                        TextEditingValue(text: currentPhone),
                        TextEditingValue(text: digitsOnly),
                      );
                      _phoneController.value = formatted;
                    }
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
              // Assigned To dropdown (optional)
              _buildAssignedUserDropdown(createState),
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

  Widget _buildAssignedUserDropdown(LeadCreateState createState) {
    // Use all active users to support cross-region assignment
    final userListState = ref.watch(allActiveUsersProvider);

    return DropdownButtonFormField<String?>(
      value: createState.assignedTo,
      decoration: InputDecoration(
        labelText: 'Assigned To (optional)',
        hintText: 'Select user from any region',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Unassigned'),
        ),
        if (userListState.isLoading)
          const DropdownMenuItem<String>(
            value: 'loading',
            enabled: false,
            child: Text('Loading users...'),
          )
        else
          ...userListState.users.map((user) {
            // Show user name with region in parentheses
            final regionLabel = user.region != null 
                ? ' (${user.region!.name.toUpperCase()})' 
                : '';
            return DropdownMenuItem<String>(
              value: user.uid,
              child: Text('${user.name}$regionLabel'),
            );
          }),
      ],
      onChanged: (userId) {
        if (userId == null) {
          ref.read(leadCreateProvider.notifier).setAssignedTo(null, null);
        } else {
          final selectedUser = userListState.users.firstWhere(
            (u) => u.uid == userId,
            orElse: () => throw Exception('User not found'),
          );
          ref.read(leadCreateProvider.notifier).setAssignedTo(
                selectedUser.uid,
                selectedUser.name,
              );
        }
      },
    );
  }
}

