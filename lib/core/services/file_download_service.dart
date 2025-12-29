import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Service for downloading/sharing files across platforms
class FileDownloadService {
  /// Downloads or shares a CSV file
  /// Web: Uses share_plus (opens share dialog or downloads)
  /// Mobile: Shares file via system share dialog
  static Future<void> downloadCsv({
    required String csvContent,
    required String filename,
  }) async {
    try {
      if (kIsWeb) {
        // Web: Create XFile from data and share
        final bytes = utf8.encode(csvContent);
        final file = XFile.fromData(
          bytes,
          mimeType: 'text/csv',
          name: filename,
        );
        await Share.shareXFiles([file], text: 'Lead export', subject: filename);
      } else {
        // Mobile: Save to temp file and share
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsString(csvContent, encoding: utf8);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Lead export',
          subject: filename,
        );
      }
    } catch (e) {
      throw Exception('Failed to export file: $e');
    }
  }
}

