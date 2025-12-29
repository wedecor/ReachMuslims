import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../providers/lead_list_provider.dart';
import '../providers/lead_filter_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/status_dropdown.dart';
import '../widgets/status_badge.dart';
import '../widgets/lead_filter_panel.dart';
import '../widgets/priority_star_toggle.dart';
import '../widgets/compact_last_contacted.dart';
import '../widgets/lead_card_action_buttons.dart';
import 'lead_create_screen.dart';
import 'lead_detail_screen.dart';
import 'package:intl/intl.dart';

class LeadListScreen extends ConsumerStatefulWidget {
  const LeadListScreen({super.key});

  @override
  ConsumerState<LeadListScreen> createState() => _LeadListScreenState();
}

class _LeadListScreenState extends ConsumerState<LeadListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leadListProvider.notifier).loadLeads(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(leadListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final leadListState = ref.watch(leadListProvider);
    final filterState = ref.watch(leadFilterProvider);
    final isAdmin = authState.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeadCreateScreen(),
                  ),
                ).then((_) {
                  // Refresh list after creating lead
                  ref.read(leadListProvider.notifier).refresh();
                });
              },
              tooltip: 'Create Lead',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(leadFilterProvider.notifier).setSearchQuery(null);
                          ref.read(leadListProvider.notifier).refresh();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                ref.read(leadFilterProvider.notifier).setSearchQuery(value.isEmpty ? null : value);
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    ref.read(leadListProvider.notifier).refresh();
                  }
                });
              },
            ),
          ),
          // Advanced Filters Panel
          const LeadFilterPanel(),
          // Lead list
          Expanded(
            child: _buildLeadList(leadListState),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadList(LeadListState state) {
    if (state.isLoading && state.leads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error!.message}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(leadListProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.leads.isEmpty) {
      return const Center(
        child: Text('No leads found'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(leadListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.leads.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.leads.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final lead = state.leads[index];
          return _buildLeadItem(lead);
        },
      ),
    );
  }

  Widget _buildLeadItem(Lead lead) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeadDetailScreen(lead: lead),
              ),
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error opening lead: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Star icon (left) + Lead Name (bold) + Status badge (right)
              Row(
                children: [
                  PriorityStarToggle(lead: lead),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lead.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: lead.status),
                ],
              ),
              const SizedBox(height: 8),
              // Middle row: Phone number (subtle)
              Text(
                lead.phone,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              // Last contacted indicator
              const SizedBox(height: 8),
              CompactLastContacted(leadId: lead.id),
              // Bottom action section: Large Call and WhatsApp buttons
              const SizedBox(height: 12),
              LeadCardActionButtons(lead: lead),
            ],
          ),
        ),
      ),
    );
  }
}

