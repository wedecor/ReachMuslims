import 'package:intl/intl.dart';
import '../../domain/models/lead.dart';

/// Service for exporting leads to CSV format
class CsvExportService {
  /// Converts a list of leads to CSV format
  /// Returns CSV string with headers and data rows
  static String exportLeadsToCsv(List<Lead> leads) {
    final buffer = StringBuffer();

    // CSV Headers
    buffer.writeln('Name,Phone,Location,Status,Priority,Last Contacted,Created At,Assigned To,Region');

    // CSV Data Rows
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (final lead in leads) {
      // Escape commas and quotes in CSV values
      final name = _escapeCsvField(lead.name);
      final phone = _escapeCsvField(lead.phone);
      final location = _escapeCsvField(lead.location ?? '');
      final status = _escapeCsvField(lead.status.displayName);
      final priority = lead.isPriority ? 'Yes' : 'No';
      final lastContacted = lead.lastContactedAt != null
          ? dateFormat.format(lead.lastContactedAt!)
          : '';
      final createdAt = dateFormat.format(lead.createdAt);
      final assignedTo = _escapeCsvField(lead.assignedToName ?? '');
      final region = _escapeCsvField(lead.region.name.toUpperCase());

      buffer.writeln('$name,$phone,$location,$status,$priority,$lastContacted,$createdAt,$assignedTo,$region');
    }

    return buffer.toString();
  }

  /// Escapes CSV field values (handles commas, quotes, newlines)
  static String _escapeCsvField(String value) {
    if (value.isEmpty) {
      return '';
    }

    // If value contains comma, quote, or newline, wrap in quotes and escape quotes
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }

    return value;
  }

  /// Generates filename with current date
  static String generateFilename() {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy_MM_dd');
    return 'reach_muslim_leads_${dateFormat.format(now)}.csv';
  }
}

