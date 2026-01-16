import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/user.dart';
import '../providers/lead_edit_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/region_based_phone_formatter.dart';

class LeadEditScreen extends ConsumerStatefulWidget {
  final Lead lead;

  const LeadEditScreen({
    super.key,
    required this.lead,
  });

  @override
  ConsumerState<LeadEditScreen> createState() => _LeadEditScreenState();
}

class _LeadEditScreenState extends ConsumerState<LeadEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  LeadGender? _selectedGender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.lead.name);
    // Format phone number based on lead's region
    final digitsOnly = widget.lead.phone.replaceAll(RegExp(r'[^\d]'), '');
    final formatter = RegionBasedPhoneFormatter(widget.lead.region);
    final formatted = formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      TextEditingValue(text: digitsOnly),
    );
    _phoneController = TextEditingController(text: formatted.text);
    _locationController = TextEditingController(text: widget.lead.location ?? '');
    // Initialize gender - if unknown, default to null to force selection
    _selectedGender = widget.lead.gender == LeadGender.unknown ? null : widget.lead.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Changes?'),
        content: const Text('Are you sure you want to save these changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    // Extract only digits from formatted phone number
    final phoneDigitsOnly = PhoneNumberValidator.getDigitsOnly(_phoneController.text);
    
    // Validate gender is selected (must be male or female)
    if (_selectedGender == null || _selectedGender == LeadGender.unknown) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gender is required. Please select Male or Female.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }
    
    final success = await ref.read(leadEditProvider(widget.lead.id).notifier).updateLead(
          name: _nameController.text.trim(),
          phone: phoneDigitsOnly,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          gender: _selectedGender!,
        );

    if (!mounted) return;
    
    final colorScheme = Theme.of(context).colorScheme;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lead updated successfully'),
          backgroundColor: colorScheme.primaryContainer,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = ref.read(leadEditProvider(widget.lead.id)).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.message}'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  bool _canEdit() {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      return false;
    }

    final user = authState.user!;
    // Admin can edit any lead, Sales can edit only assigned leads
    if (user.isAdmin) {
      return true;
    }

    // Sales can edit only if lead is assigned to them
    return widget.lead.assignedTo == user.uid;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final editState = ref.watch(leadEditProvider(widget.lead.id));
    final canEdit = _canEdit();

    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Lead'),
        ),
        body: const Center(
          child: Text('You do not have permission to edit this lead.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Lead'),
        actions: [
          if (editState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _handleSave,
              tooltip: 'Save',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Read-only fields info
              Card(
                color: colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note: Name, phone, location, and gender can be edited.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gender is required (must be Male or Female).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Region, Status, and Assignment cannot be changed here.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
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
                  fillColor: colorScheme.surfaceContainerHighest,
                  hintText: widget.lead.region == UserRegion.usa 
                      ? '(XXX) XXX-XXXX' 
                      : 'XXXX-XXXXXX',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  RegionBasedPhoneFormatter(widget.lead.region),
                ],
                validator: (value) {
                  return PhoneNumberValidator.validate(value, widget.lead.region);
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
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 16),
              // Gender dropdown (mandatory - must be Male or Female)
              DropdownButtonFormField<LeadGender>(
                value: _selectedGender,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  helperText: widget.lead.gender == LeadGender.unknown
                      ? 'Please select gender (required)'
                      : null,
                  helperMaxLines: 2,
                ),
                items: [
                  // Only show Male and Female options (not Unknown)
                  DropdownMenuItem<LeadGender>(
                    value: LeadGender.male,
                    child: Text(LeadGender.male.displayName),
                  ),
                  DropdownMenuItem<LeadGender>(
                    value: LeadGender.female,
                    child: Text(LeadGender.female.displayName),
                  ),
                ],
                onChanged: (gender) {
                  setState(() {
                    _selectedGender = gender;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Gender is required (must be Male or Female)';
                  }
                  if (value == LeadGender.unknown) {
                    return 'Gender cannot be Unknown. Please select Male or Female.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // Error message
              if (editState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    editState.error!.message,
                    style: TextStyle(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Save button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: editState.isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: editState.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                          ),
                        )
                      : const Text(
                          'Save Changes',
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

