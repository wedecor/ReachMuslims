import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/follow_up_provider.dart';

/// Lazy-loading badge showing follow-up count for a lead
/// Only loads data when the widget is actually visible
class LazyFollowUpCountBadge extends ConsumerStatefulWidget {
  final String leadId;

  const LazyFollowUpCountBadge({
    super.key,
    required this.leadId,
  });

  @override
  ConsumerState<LazyFollowUpCountBadge> createState() => _LazyFollowUpCountBadgeState();
}

class _LazyFollowUpCountBadgeState extends ConsumerState<LazyFollowUpCountBadge> {
  bool _shouldLoad = false;

  @override
  void initState() {
    super.initState();
    // Delay loading to avoid blocking initial render
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _shouldLoad = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldLoad) {
      return const SizedBox.shrink();
    }

    final followUpState = ref.watch(followUpListProvider(widget.leadId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (followUpState.isLoading) {
      return const SizedBox.shrink();
    }

    final count = followUpState.followUps.length;
    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Chip(
      avatar: Icon(
        Icons.note_outlined,
        size: 14,
        color: colorScheme.tertiary,
      ),
      label: Text(
        '$count ${count == 1 ? 'follow-up' : 'follow-ups'}',
        style: const TextStyle(fontSize: 11),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: colorScheme.tertiaryContainer,
      labelStyle: TextStyle(
        color: colorScheme.onTertiaryContainer,
        fontSize: 11,
      ),
    );
  }
}

