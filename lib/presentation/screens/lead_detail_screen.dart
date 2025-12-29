import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/follow_up.dart';
import '../providers/follow_up_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lead_assignment_provider.dart';
import '../providers/user_list_provider.dart';
import '../providers/lead_list_provider.dart';
import '../widgets/priority_star_toggle.dart';
import '../widgets/last_contacted_indicator.dart';
import '../widgets/follow_up_timeline_widget.dart';

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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final followUpListState = ref.watch(followUpListProvider(widget.lead.id));
    final addFollowUpState = ref.watch(addFollowUpProvider(widget.lead.id));
    final authState = ref.watch(authProvider);
    final leadListState = ref.watch(leadListProvider);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    
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
                  Text('Phone: ${currentLead.phone}'),
                  if (currentLead.location != null)
                    Text('Location: ${currentLead.location}'),
                  Text('Status: ${currentLead.status.displayName}'),
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
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add a follow-up note...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: addFollowUpState.isLoading ? null : _handleAddFollowUp,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: addFollowUpState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Add Follow-Up'),
                    ),
                  ),
                  if (addFollowUpState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        addFollowUpState.error!.message,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          // Follow-Up History Timeline (Read-only)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Follow-up History',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FollowUpTimelineWidget(leadId: widget.lead.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAssignmentDropdown(BuildContext context, AuthState authState) {
    final assignmentState = ref.watch(leadAssignmentProvider(widget.lead.id));
    final userListState = ref.watch(userListProvider(widget.lead.region));
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
        DropdownButtonFormField<String?>(
          value: currentAssignedUserId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                return DropdownMenuItem<String>(
                  value: user.uid,
                  child: Text(user.name),
                );
              }),
          ],
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

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(newUserId != null
                            ? 'Lead assigned successfully'
                            : 'Lead unassigned successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Refresh lead list to get updated lead
                    ref.read(leadListProvider.notifier).refresh();
                  } else if (mounted) {
                    final error = ref.read(leadAssignmentProvider(widget.lead.id)).error;
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${error.message}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
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
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

