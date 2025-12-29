import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../providers/lead_edit_provider.dart';
import '../providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.lead.name);
    _phoneController = TextEditingController(text: widget.lead.phone);
    _locationController = TextEditingController(text: widget.lead.location ?? '');
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

    final success = await ref.read(leadEditProvider(widget.lead.id).notifier).updateLead(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lead updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = ref.read(leadEditProvider(widget.lead.id)).error;
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
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note: Only name, phone, and location can be edited.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Region, Status, and Assignment cannot be changed here.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
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
                  fillColor: Colors.grey[50],
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
              ),
              const SizedBox(height: 32),
              // Error message
              if (editState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    editState.error!.message,
                    style: const TextStyle(color: Colors.red),
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
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

