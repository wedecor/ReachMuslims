import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/user.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({
    super.key,
    this.expense,
  });

  @override
  ConsumerState<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState
    extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPlatform;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  UserRegion _selectedRegion = UserRegion.india;

  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final expense = widget.expense!;
      _selectedPlatform = expense.platform;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _descriptionController.text = expense.description ?? '';
      _categoryController.text = expense.category ?? '';
      _selectedDate = expense.date;
      _selectedRegion = expense.region;
    } else {
      // Get user's region from auth state if available
      final authState = ref.read(authProvider);
      if (authState.user?.region != null) {
        _selectedRegion = authState.user!.region!;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String get _currency {
    return _selectedRegion == UserRegion.usa ? 'USD' : 'INR';
  }

  String get _currencySymbol {
    return _selectedRegion == UserRegion.usa ? '\$' : '₹';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_selectedPlatform == null || _selectedPlatform!.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a platform'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid amount'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    final expense = Expense(
      id: widget.expense?.id ?? '',
      platform: _selectedPlatform!,
      amount: amount,
      currency: _currency,
      date: _selectedDate,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      createdBy: user.uid,
      region: _selectedRegion,
      createdAt: widget.expense?.createdAt ?? now,
      updatedAt: now,
    );

    bool success = false;
    if (isEditing) {
      success = await ref.read(expenseUpdateProvider.notifier).updateExpense(expense);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense updated successfully'),
            ),
          );
          Navigator.pop(context, true);
        } else {
          final error = ref.read(expenseUpdateProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error?.message ?? 'Failed to update expense'}'),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
          );
        }
      }
    } else {
      // Use empty ID - Firestore will auto-generate it
      final expenseWithId = Expense(
        id: '', // Will be auto-generated by Firestore
        platform: expense.platform,
        amount: expense.amount,
        currency: expense.currency,
        date: expense.date,
        description: expense.description,
        category: expense.category,
        createdBy: expense.createdBy,
        region: expense.region,
        createdAt: expense.createdAt,
        updatedAt: expense.updatedAt,
      );

      success = await ref.read(expenseCreateProvider.notifier).createExpense(expenseWithId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense created successfully'),
            ),
          );
          Navigator.pop(context, true);
        } else {
          final error = ref.read(expenseCreateProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error?.message ?? 'Failed to create expense'}'),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = isEditing
        ? ref.watch(expenseUpdateProvider).isLoading
        : ref.watch(expenseCreateProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (isLoading)
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
              icon: const Icon(Icons.check),
              onPressed: _saveExpense,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Platform Field (Dropdown with common platforms)
            DropdownButtonFormField<String>(
              value: _selectedPlatform,
              decoration: const InputDecoration(
                labelText: 'Platform *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Facebook',
                  child: Text('Facebook'),
                ),
                DropdownMenuItem(
                  value: 'Google Ads',
                  child: Text('Google Ads'),
                ),
                DropdownMenuItem(
                  value: 'Instagram',
                  child: Text('Instagram'),
                ),
                DropdownMenuItem(
                  value: 'LinkedIn',
                  child: Text('LinkedIn'),
                ),
                DropdownMenuItem(
                  value: 'TikTok',
                  child: Text('TikTok'),
                ),
                DropdownMenuItem(
                  value: 'Twitter/X',
                  child: Text('Twitter/X'),
                ),
                DropdownMenuItem(
                  value: 'YouTube',
                  child: Text('YouTube'),
                ),
                DropdownMenuItem(
                  value: 'WhatsApp Business',
                  child: Text('WhatsApp Business'),
                ),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Platform is required';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _selectedPlatform = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Region Dropdown (affects currency)
            DropdownButtonFormField<UserRegion>(
              value: _selectedRegion,
              decoration: const InputDecoration(
                labelText: 'Region *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: UserRegion.india,
                  child: Text('India (INR ₹)'),
                ),
                DropdownMenuItem(
                  value: UserRegion.usa,
                  child: Text('USA (USD \$)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRegion = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Amount Field
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount *',
                hintText: '0.00',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money_outlined),
                prefixText: '$_currencySymbol ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Amount is required';
                }
                final amount = double.tryParse(value.trim());
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date Picker
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Field (Optional)
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add any additional notes...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Category Field (Optional)
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category (Optional)',
                hintText: 'e.g., Advertising, Software, Other',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveExpense,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isEditing ? 'Update Expense' : 'Create Expense',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

