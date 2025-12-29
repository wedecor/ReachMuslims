import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/models/lead.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load stats when screen is first displayed
    // Add a delay to ensure Firebase is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Delay to ensure Firebase and providers are ready
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          try {
            await ref.read(dashboardProvider.notifier).loadStats();
          } catch (e) {
            debugPrint('Error loading dashboard stats: $e');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.isAdmin ?? false;
    final stats = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).refresh();
        },
        child: stats.isLoading && stats.totalLeads == 0
            ? const Center(child: CircularProgressIndicator())
            : stats.error != null && stats.totalLeads == 0
                ? _buildErrorState(context, stats.error!.message)
                : stats.error != null
                    ? Column(
                        children: [
                          _buildErrorBanner(context, stats.error!.message),
                          Expanded(
                            child: _buildDashboardContent(context, stats, isAdmin),
                          ),
                        ],
                      )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Cards
                        _buildOverviewSection(context, stats, isAdmin),
                        const SizedBox(height: 24),
                        // Status Breakdown
                        _buildStatusSection(context, stats),
                        const SizedBox(height: 24),
                        // Region Breakdown (Admin only)
                        if (isAdmin) ...[
                          _buildRegionSection(context, stats),
                          const SizedBox(height: 24),
                        ],
                        // Time-based Stats
                        _buildTimeSection(context, stats),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardStats stats, bool isAdmin) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          _buildOverviewSection(context, stats, isAdmin),
          const SizedBox(height: 24),
          // Status Breakdown
          _buildStatusSection(context, stats),
          const SizedBox(height: 24),
          // Region Breakdown (Admin only)
          if (isAdmin) ...[
            _buildRegionSection(context, stats),
            const SizedBox(height: 24),
          ],
          // Time-based Stats
          _buildTimeSection(context, stats),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Some data may be outdated: $message',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Error loading dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(dashboardProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, DashboardStats stats, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              title: 'Total Leads',
              value: stats.totalLeads.toString(),
              icon: Icons.people_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            _buildStatCard(
              context,
              title: 'Converted',
              value: stats.convertedLeads.toString(),
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context, DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'By Status',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              title: LeadStatus.newLead.displayName,
              value: stats.newLeads.toString(),
              icon: Icons.new_releases_outlined,
              color: Colors.blue,
            ),
            _buildStatCard(
              context,
              title: LeadStatus.inTalk.displayName,
              value: stats.inTalkLeads.toString(),
              icon: Icons.chat_bubble_outline,
              color: Colors.orange,
            ),
            _buildStatCard(
              context,
              title: LeadStatus.converted.displayName,
              value: stats.convertedLeads.toString(),
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
            _buildStatCard(
              context,
              title: LeadStatus.notInterested.displayName,
              value: stats.notInterestedLeads.toString(),
              icon: Icons.cancel_outlined,
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegionSection(BuildContext context, DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'By Region',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              title: 'India',
              value: stats.indiaLeads.toString(),
              icon: Icons.location_on_outlined,
              color: Colors.indigo,
            ),
            _buildStatCard(
              context,
              title: 'USA',
              value: stats.usaLeads.toString(),
              icon: Icons.location_on_outlined,
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSection(BuildContext context, DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              title: 'Today',
              value: stats.leadsToday.toString(),
              icon: Icons.today_outlined,
              color: Colors.purple,
            ),
            _buildStatCard(
              context,
              title: 'This Week',
              value: stats.leadsThisWeek.toString(),
              icon: Icons.calendar_today_outlined,
              color: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

