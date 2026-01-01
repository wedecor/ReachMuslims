import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../providers/follow_up_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lead_assignment_provider.dart';
import '../providers/user_list_provider.dart';
import '../providers/lead_list_provider.dart';
import '../providers/lead_delete_provider.dart';
import '../../domain/models/user.dart' as domain;
import '../widgets/priority_star_toggle.dart';
import '../widgets/last_contacted_indicator.dart';
import '../widgets/follow_up_timeline_widget.dart';
import '../widgets/lead_edit_history_timeline_widget.dart';
import '../widgets/status_dropdown.dart';
import '../../core/utils/phone_number_formatter.dart';
import '../providers/scheduled_followup_provider.dart';
import 'lead_edit_screen.dart';
import 'package:intl/intl.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final Lead lead;

  const LeadDetailScreen({
    super.key,
    required this.lead,
  });

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  final _noteController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleAddFollowUp() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      return;
    }

    final success = await ref.read(addFollowUpProvider(widget.lead.id).notifier).addFollowUp(note);

    if (success && mounted) {
      _noteController.clear();
      // Scroll to top to show new follow-up
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else if (mounted) {
      final error = ref.read(addFollowUpProvider(widget.lead.id)).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.message}'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addFollowUpState = ref.watch(addFollowUpProvider(widget.lead.id));
    final authState = ref.watch(authProvider);
    final leadListState = ref.watch(leadListProvider);
    
    // Get updated lead from list if available, otherwise use widget.lead
    Lead currentLead;
    try {
      currentLead = leadListState.leads.firstWhere(
        (l) => l.id == widget.lead.id,
        orElse: () => widget.lead,
      );
    } catch (e) {
      // Fallback to widget.lead if any error occurs
      currentLead = widget.lead;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentLead.name),
        actions: [
          // Edit button - show only if user has permission
          if (_canEditLead(currentLead, authState))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeadEditScreen(lead: currentLead),
                  ),
                );
                // Refresh if lead was updated
                if (result == true && mounted) {
                  ref.read(leadListProvider.notifier).refresh();
                }
              },
              tooltip: 'Edit Lead',
            ),
          // Delete button - Admin only
          if (authState.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _handleDelete(context, currentLead),
              tooltip: 'Delete Lead',
              color: Theme.of(context).colorScheme.error,
            ),
        ],
      ),
      body: Column(
        children: [
          // Lead Details Card
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with priority star
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentLead.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      PriorityStarToggle(lead: currentLead),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Phone: ${PhoneNumberFormatter.formatPhoneNumber(currentLead.phone, region: currentLead.region)}'),
                  if (currentLead.location != null)
                    Text('Location: ${currentLead.location}'),
                  // Source label (read-only)
                  Row(
                    children: [
                      const Text('Source: '),
                      Chip(
                        label: Text(
                          currentLead.source.displayName,
                          style: const TextStyle(fontSize: 12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  // Status dropdown - editable
                  Row(
                    children: [
                      const Text('Status: '),
                      const SizedBox(width: 8),
                      StatusDropdown(lead: currentLead),
                    ],
                  ),
                  Text('Region: ${currentLead.region.name.toUpperCase()}'),
                  const SizedBox(height: 8),
                  // Last contacted indicator
                  LastContactedIndicator(leadId: currentLead.id),
                  const SizedBox(height: 8),
                  // Assignment dropdown (Admin only)
                  if (authState.isAdmin)
                    _buildAssignmentDropdown(context, authState)
                  else if (currentLead.assignedToName != null)
                    Text('Assigned: ${currentLead.assignedToName}'),
                ],
              ),
            ),
          ),
          // Follow-Up Input Section
          if (authState.isAuthenticated && authState.user?.active == true)
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    border: Border(
                      top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                      bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Add a follow-up note...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: addFollowUpState.isLoading ? null : _handleAddFollowUp,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: addFollowUpState.isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                                    ),
                                  )
                                : const Icon(Icons.note_add, size: 18),
                            label: const Text('Add Follow-Up'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: () => _showScheduleFollowUpDialog(context, currentLead.id),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.schedule, size: 18),
                          label: const Text('Schedule'),
                        ),
                      ),
                    ],
                  ),
                      if (addFollowUpState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            addFollowUpState.error!.message,
                            style: TextStyle(color: colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          // History Tabs (Follow-ups and Edit History)
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.history),
                        text: 'Follow-ups',
                      ),
                      Tab(
                        icon: Icon(Icons.edit_note),
                        text: 'Edit History',
                      ),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Follow-Up History Timeline
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: FollowUpTimelineWidget(leadId: widget.lead.id),
                            ),
                          ],
                        ),
                        // Edit History Timeline
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: LeadEditHistoryTimelineWidget(leadId: widget.lead.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  bool _canEditLead(Lead lead, AuthState authState) {
    if (!authState.isAuthenticated || authState.user == null) {
      return false;
    }

    final user = authState.user!;
    // Admin can edit any lead, Sales can edit only assigned leads
    if (user.isAdmin) {
      return true;
    }

    // Sales can edit only if lead is assigned to them
    return lead.assignedTo == user.uid;
  }

  Future<void> _handleDelete(BuildContext context, Lead lead) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lead?'),
        content: const Text(
          'This will remove the lead from active lists. This action can be reversed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final deleteState = ref.read(leadDeleteProvider(lead.id));
    if (deleteState.isLoading) {
      return;
    }

    final success = await ref.read(leadDeleteProvider(lead.id).notifier).deleteLead();

    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lead deleted successfully'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate back to lead list
      Navigator.pop(context);
    } else {
      final error = ref.read(leadDeleteProvider(lead.id)).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.message}'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showScheduleFollowUpDialog(BuildContext context, String leadId) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final noteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Schedule Follow-up'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date picker
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    selectedDate == null
                        ? 'Select date'
                        : DateFormat('MMM dd, yyyy').format(selectedDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                // Time picker
                ListTile(
                  title: const Text('Time'),
                  subtitle: Text(
                    selectedTime == null
                        ? 'Select time'
                        : selectedTime!.format(context),
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Note field
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (selectedDate != null && selectedTime != null)
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedDate != null && selectedTime != null && mounted) {
      final scheduledDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final success = await ref
          .read(scheduledFollowUpListProvider(leadId).notifier)
          .createScheduledFollowUp(
            scheduledAt: scheduledDateTime,
            note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
            createdBy: authState.user!.uid,
          );

      noteController.dispose();

      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Follow-up scheduled successfully'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final error = ref.read(scheduledFollowUpListProvider(leadId)).error;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.message}'),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      noteController.dispose();
    }
  }

  Widget _buildAssignmentDropdown(BuildContext context, AuthState authState) {
    final assignmentState = ref.watch(leadAssignmentProvider(widget.lead.id));
    // Use all active users to support cross-region assignment
    final userListState = ref.watch(allActiveUsersProvider);
    final leadListState = ref.watch(leadListProvider);
    final userRepository = ref.watch(userRepositoryProvider);
    
    // Get updated lead from list if available, otherwise use widget.lead
    Lead currentLead;
    try {
      currentLead = leadListState.leads.firstWhere(
        (l) => l.id == widget.lead.id,
        orElse: () => widget.lead,
      );
    } catch (e) {
      // Fallback to widget.lead if any error occurs
      currentLead = widget.lead;
    }

    // Get current assignment
    final currentAssignedUserId = currentLead.assignedTo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assigned To:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        FutureBuilder<domain.User?>(
          // Fetch assigned user if not in active list
          future: (currentAssignedUserId != null && 
                   !userListState.isLoading &&
                   !userListState.users.any((user) => user.uid == currentAssignedUserId))
              ? userRepository.getUserById(currentAssignedUserId)
              : Future.value(null),
          builder: (context, assignedUserSnapshot) {
            // Recalculate inside builder to get fresh state (avoids stale checks)
            final assignedUserExists = !userListState.isLoading &&
                currentAssignedUserId != null &&
                userListState.users.any((user) => user.uid == currentAssignedUserId);
            
            // Build dropdown items - MUST include currentAssignedUserId if it exists
            final items = <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Unassigned'),
              ),
            ];

            if (userListState.isLoading) {
              items.add(
                const DropdownMenuItem<String>(
                  value: 'loading',
                  enabled: false,
                  child: Text('Loading users...'),
                ),
              );
              // If we have an assigned user but list is loading, add it as placeholder
              if (currentAssignedUserId != null) {
                items.add(
                  DropdownMenuItem<String>(
                    value: currentAssignedUserId,
                    enabled: false,
                    child: Text(
                      currentLead.assignedToName ?? 'Loading...',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }
            } else {
              // Add active users (show region for cross-region support)
              for (final user in userListState.users) {
                final regionLabel = user.region != null 
                    ? ' (${user.region!.name.toUpperCase()})' 
                    : '';
                items.add(
                  DropdownMenuItem<String>(
                    value: user.uid,
                    child: Text('${user.name}$regionLabel'),
                  ),
                );
              }

              // CRITICAL: Add assigned user ONLY if not already in active list
              // This ensures the value always matches an item, and prevents duplicates
              if (currentAssignedUserId != null && !assignedUserExists) {
                if (assignedUserSnapshot.connectionState == ConnectionState.waiting) {
                  // Still loading user data
                  items.add(
                    DropdownMenuItem<String>(
                      value: currentAssignedUserId,
                      enabled: false,
                      child: Text('Loading user...', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                  );
                } else if (assignedUserSnapshot.hasData && assignedUserSnapshot.data != null) {
                  // User found
                  final assignedUser = assignedUserSnapshot.data!;
                  items.add(
                    DropdownMenuItem<String>(
                      value: currentAssignedUserId,
                      enabled: false,
                      child: Text(
                        assignedUser.name,
                        style: TextStyle(
                          color: assignedUser.active 
                              ? Theme.of(context).colorScheme.onSurfaceVariant 
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  );
                } else {
                  // User not found - use name from lead or show "Unknown"
                  items.add(
                    DropdownMenuItem<String>(
                      value: currentAssignedUserId,
                      enabled: false,
                      child: Text(
                        currentLead.assignedToName ?? 'Unknown User',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  );
                }
              }
            }

            // Ensure value matches exactly one item (no duplicates, no missing)
            final matchingCount = items.where((item) => item.value == currentAssignedUserId).length;
            final dropdownValue = (currentAssignedUserId != null && matchingCount == 1)
                ? currentAssignedUserId
                : null;

            return DropdownButtonFormField<String?>(
              initialValue: dropdownValue,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              items: items,
              onChanged: assignmentState.isLoading
                  ? null
                  : (String? newUserId) async {
                      if (newUserId == currentAssignedUserId) return;

                      String? assignedToName;
                      if (newUserId != null) {
                        final selectedUser = userListState.users.firstWhere(
                          (u) => u.uid == newUserId,
                          orElse: () => throw Exception('User not found'),
                        );
                        assignedToName = selectedUser.name;
                      }

                      final success = await ref
                          .read(leadAssignmentProvider(widget.lead.id).notifier)
                          .assignLead(newUserId, assignedToName);

                      if (!mounted) return;
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(newUserId != null
                                ? 'Lead assigned successfully'
                                : 'Lead unassigned successfully'),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        // Refresh lead list to get updated lead
                        ref.read(leadListProvider.notifier).refresh();
                      } else {
                        final error = ref.read(leadAssignmentProvider(widget.lead.id)).error;
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${error.message}'),
                              backgroundColor: Theme.of(context).colorScheme.errorContainer,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
            );
          },
        ),
        if (assignmentState.isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(),
          ),
        if (assignmentState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              assignmentState.error!.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

