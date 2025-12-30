import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/scheduled_followup_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/models/scheduled_followup.dart';
import '../../domain/repositories/lead_repository.dart';
import '../providers/lead_list_provider.dart';
import 'lead_detail_screen.dart';
import '../../domain/models/lead.dart';

class MyTasksScreen extends ConsumerWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated || authState.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Tasks')),
        body: const Center(
          child: Text('Please log in to view your tasks'),
        ),
      );
    }

    final userId = authState.user!.uid;
    final tasksState = ref.watch(userTasksProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(userTasksProvider(userId).notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(context, ref, tasksState, userId),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    UserTasksState tasksState,
    String userId,
  ) {
    if (tasksState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasksState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error: ${tasksState.error!.message}',
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(userTasksProvider(userId).notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (tasksState.pendingTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No pending follow-ups',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All your scheduled follow-ups are completed',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group tasks by date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final overdueTasks = <ScheduledFollowUp>[];
    final todayTasks = <ScheduledFollowUp>[];
    final upcomingTasks = <ScheduledFollowUp>[];

    for (final task in tasksState.pendingTasks) {
      final taskDate = DateTime(task.scheduledAt.year, task.scheduledAt.month, task.scheduledAt.day);
      if (task.scheduledAt.isBefore(now)) {
        overdueTasks.add(task);
      } else if (taskDate == today) {
        todayTasks.add(task);
      } else {
        upcomingTasks.add(task);
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(userTasksProvider(userId).notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (overdueTasks.isNotEmpty) ...[
            _buildSectionHeader('Overdue', Colors.orange),
            const SizedBox(height: 8),
            ...overdueTasks.map((task) => _buildTaskItem(context, ref, task)),
            const SizedBox(height: 24),
          ],
          if (todayTasks.isNotEmpty) ...[
            _buildSectionHeader('Today', Colors.blue),
            const SizedBox(height: 8),
            ...todayTasks.map((task) => _buildTaskItem(context, ref, task)),
            const SizedBox(height: 24),
          ],
          if (upcomingTasks.isNotEmpty) ...[
            _buildSectionHeader('Upcoming', Colors.grey),
            const SizedBox(height: 8),
            ...upcomingTasks.map((task) => _buildTaskItem(context, ref, task)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    // Get a darker shade of the color
    final darkerColor = Color.fromRGBO(
      (color.red * 0.7).round().clamp(0, 255),
      (color.green * 0.7).round().clamp(0, 255),
      (color.blue * 0.7).round().clamp(0, 255),
      1.0,
    );
    
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkerColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, ScheduledFollowUp task) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final now = DateTime.now();
    final isOverdue = task.scheduledAt.isBefore(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isOverdue ? 4 : 1,
      color: isOverdue ? Colors.orange[50] : null,
      child: ListTile(
        leading: Icon(
          isOverdue ? Icons.warning : Icons.schedule,
          color: isOverdue ? Colors.orange : Colors.blue,
        ),
        title: Text(
          dateFormat.format(task.scheduledAt),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOverdue ? Colors.orange[900] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.note != null && task.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(task.note!),
              ),
            FutureBuilder<Lead?>(
              future: _getLeadForTask(ref, task.leadId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Lead: ${snapshot.data!.name}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              color: Colors.blue,
              onPressed: () async {
                final lead = await _getLeadForTask(ref, task.leadId);
                if (lead != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeadDetailScreen(lead: lead),
                    ),
                  );
                }
              },
              tooltip: 'View Lead',
            ),
            IconButton(
              icon: const Icon(Icons.check, size: 20),
              color: Colors.green,
              onPressed: () async {
                final userId = ref.read(authProvider).user?.uid;
                if (userId == null) return;

                final repository = ref.read(scheduledFollowUpRepositoryProvider);
                try {
                  await repository.markAsCompleted(task.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Marked as completed'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await ref.read(userTasksProvider(userId).notifier).refresh();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              tooltip: 'Mark as completed',
            ),
          ],
        ),
        onTap: () async {
          final lead = await _getLeadForTask(ref, task.leadId);
          if (lead != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeadDetailScreen(lead: lead),
              ),
            );
          }
        },
      ),
    );
  }

  Future<Lead?> _getLeadForTask(WidgetRef ref, String leadId) async {
    try {
      final leadRepository = ref.read(leadRepositoryProvider);
      return await leadRepository.getLeadById(leadId);
    } catch (e) {
      return null;
    }
  }
}

