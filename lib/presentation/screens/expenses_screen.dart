import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/user.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import 'add_edit_expense_screen.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _selectedPlatform;
  UserRegion? _selectedRegion;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseState = ref.watch(expenseListProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Get unique platforms from expenses
    final expensePlatforms = expenseState.expenses
        .map((e) => e.platform)
        .toSet()
        .toList();
    
    // Common platforms to show even when there are no expenses
    final commonPlatforms = [
      'Facebook',
      'Google Ads',
      'Instagram',
      'LinkedIn',
      'TikTok',
      'Twitter/X',
      'YouTube',
      'WhatsApp Business',
    ];
    
    // Combine and deduplicate, with expense platforms taking priority
    final platforms = <String>{
      ...commonPlatforms,
      ...expensePlatforms,
    }.toList()..sort();

    // Calculate summary stats
    final totalAmount = expenseState.expenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    final monthlyTotal = expenseState.expenses
        .where((e) {
          final now = DateTime.now();
          return e.date.year == now.year && e.date.month == now.month;
        })
        .fold<double>(
          0.0,
          (sum, expense) => sum + expense.amount,
        );

    // Group by platform
    final platformTotals = <String, double>{};
    for (final expense in expenseState.expenses) {
      platformTotals[expense.platform] =
          (platformTotals[expense.platform] ?? 0.0) + expense.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(expenseListProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Stats Section
          _buildSummarySection(
            context,
            totalAmount: totalAmount,
            monthlyTotal: monthlyTotal,
            platformTotals: platformTotals,
          ),

          // Filters Section
          _buildFiltersSection(
            context,
            platforms: platforms,
            selectedPlatform: _selectedPlatform,
            selectedRegion: _selectedRegion,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            onPlatformChanged: (platform) {
              setState(() {
                _selectedPlatform = platform;
              });
              ref.read(expenseListProvider.notifier).setPlatformFilter(platform);
            },
            onRegionChanged: (region) {
              setState(() {
                _selectedRegion = region;
              });
              ref.read(expenseListProvider.notifier).setRegionFilter(region);
            },
            onDateRangeChanged: (from, to) {
              setState(() {
                _dateFrom = from;
                _dateTo = to;
              });
              ref.read(expenseListProvider.notifier).setDateRange(from, to);
            },
            onClearFilters: () {
              setState(() {
                _selectedPlatform = null;
                _selectedRegion = null;
                _dateFrom = null;
                _dateTo = null;
              });
              ref.read(expenseListProvider.notifier).clearFilters();
            },
          ),

          // Expenses List
          Expanded(
            child: _buildExpensesList(
              context,
              expenseState,
              user,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditExpenseScreen(),
            ),
          );
          if (result == true) {
            ref.read(expenseListProvider.notifier).refresh();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Expense',
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context, {
    required double totalAmount,
    required double monthlyTotal,
    required Map<String, double> platformTotals,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Total Expenses',
                  amount: totalAmount,
                  icon: Icons.account_balance_wallet_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'This Month',
                  amount: monthlyTotal,
                  icon: Icons.calendar_month_outlined,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine currency from first expense (or default to USD)
    final expenseState = ref.watch(expenseListProvider);
    final currency = expenseState.expenses.isNotEmpty
        ? expenseState.expenses.first.currency
        : 'USD';
    final symbol = currency == 'USD' ? '\$' : '₹';

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            '$symbol${amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(
    BuildContext context, {
    required List<String> platforms,
    required String? selectedPlatform,
    required UserRegion? selectedRegion,
    required DateTime? dateFrom,
    required DateTime? dateTo,
    required ValueChanged<String?> onPlatformChanged,
    required ValueChanged<UserRegion?> onRegionChanged,
    required ValueChanged2<DateTime?, DateTime?> onDateRangeChanged,
    required VoidCallback onClearFilters,
  }) {
    final theme = Theme.of(context);
    final hasFilters = selectedPlatform != null ||
        selectedRegion != null ||
        dateFrom != null ||
        dateTo != null;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filters',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (hasFilters)
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Platform Filter
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: selectedPlatform,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Platform',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Platforms'),
                    ),
                    ...platforms.map((platform) => DropdownMenuItem<String>(
                          value: platform,
                          child: Text(platform),
                        )),
                  ],
                  onChanged: onPlatformChanged,
                ),
              ),

              // Region Filter
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<UserRegion>(
                  value: selectedRegion,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Region',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<UserRegion>(
                      value: null,
                      child: Text('All Regions'),
                    ),
                    const DropdownMenuItem<UserRegion>(
                      value: UserRegion.india,
                      child: Text('India'),
                    ),
                    const DropdownMenuItem<UserRegion>(
                      value: UserRegion.usa,
                      child: Text('USA'),
                    ),
                  ],
                  onChanged: onRegionChanged,
                ),
              ),

              // Date Range Filter
              ElevatedButton.icon(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: dateFrom != null && dateTo != null
                        ? DateTimeRange(start: dateFrom!, end: dateTo!)
                        : null,
                  );

                  if (range != null) {
                    onDateRangeChanged(range.start, range.end);
                  }
                },
                icon: const Icon(Icons.date_range),
                label: Text(
                  dateFrom != null && dateTo != null
                      ? '${DateFormat('MMM dd').format(dateFrom!)} - ${DateFormat('MMM dd').format(dateTo!)}'
                      : 'Date Range',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(
    BuildContext context,
    ExpenseListState state,
    user,
  ) {
    if (state.isLoading && state.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error!.message}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(expenseListProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses found',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first expense',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(expenseListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: state.expenses.length,
        itemBuilder: (context, index) {
          final expense = state.expenses[index];
          return _buildExpenseCard(context, expense, index);
        },
      ),
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    Expense expense,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEven = index % 2 == 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isEven
          ? colorScheme.surface
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.receipt_outlined,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          expense.platform,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              expense.formattedAmount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(expense.date),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (expense.description != null && expense.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                expense.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    expense.region.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                if (expense.category != null && expense.category!.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Chip(
                    label: Text(
                      expense.category!,
                      style: const TextStyle(fontSize: 10),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditExpenseScreen(expense: expense),
                ),
              );
              if (result == true) {
                ref.read(expenseListProvider.notifier).refresh();
              }
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Expense'),
                  content: Text(
                    'Are you sure you want to delete this expense for ${expense.platform}?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final deleteState = ref.read(expenseDeleteProvider);
                final success = await ref
                    .read(expenseDeleteProvider.notifier)
                    .deleteExpense(expense.id);

                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense deleted successfully'),
                      ),
                    );
                    ref.read(expenseListProvider.notifier).refresh();
                  } else {
                    final error = ref.read(expenseDeleteProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${error?.message ?? 'Failed to delete expense'}'),
                        backgroundColor: colorScheme.errorContainer,
                      ),
                    );
                  }
                }
              }
            }
          },
        ),
      ),
    );
  }
}

// Helper typedef for two-parameter callback
typedef ValueChanged2<T, U> = void Function(T value1, U value2);

