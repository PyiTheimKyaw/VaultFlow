import 'package:intl/intl.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_ui/vf_ui.dart';

/// Human-readable byte count (`1.2 MB`).
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = unit == 0 || value >= 100 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

/// `just now`, `5 min ago`, `Yesterday`, or a short date.
String formatRelative(DateTime time, {DateTime? now}) {
  final reference = (now ?? DateTime.now().toUtc()).toUtc();
  final delta = reference.difference(time.toUtc());
  if (delta.inSeconds < 45) return 'just now';
  if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
  if (delta.inHours < 24) return '${delta.inHours} h ago';
  if (delta.inDays == 1) return 'Yesterday';
  if (delta.inDays < 7) return '${delta.inDays} days ago';
  return DateFormat.yMMMd().format(time.toLocal());
}

/// Maps an entity's sync status onto the presentation badge.
SyncBadgeStatus badgeFor(SyncStatus status) => switch (status) {
  SyncStatus.synced => SyncBadgeStatus.synced,
  SyncStatus.pending => SyncBadgeStatus.pending,
  SyncStatus.conflicted => SyncBadgeStatus.conflicted,
};

/// Best-effort MIME type from a file name.
String mimeTypeFor(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return 'application/octet-stream';
  final ext = fileName.substring(dot + 1).toLowerCase();
  return _mimeByExtension[ext] ?? 'application/octet-stream';
}

const _mimeByExtension = <String, String>{
  'txt': 'text/plain',
  'md': 'text/markdown',
  'csv': 'text/csv',
  'json': 'application/json',
  'xml': 'application/xml',
  'html': 'text/html',
  'pdf': 'application/pdf',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'svg': 'image/svg+xml',
  'heic': 'image/heic',
  'mp3': 'audio/mpeg',
  'wav': 'audio/wav',
  'm4a': 'audio/mp4',
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
  'zip': 'application/zip',
  'gz': 'application/gzip',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
};
