import 'package:cloud_firestore/cloud_firestore.dart';

class IssueReportPayload {
  final String title;
  final String description;
  final String type;
  final String priority;
  final String reporterUid;
  final String reporterEmail;
  final String reporterDisplayName;
  final String sourceScreen;
  final String contextType;
  final String? lessonId;
  final String? categoryId;
  final String? signId;
  final String? signLabel;
  final Map<String, dynamic>? metadata;

  const IssueReportPayload({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.reporterUid,
    required this.reporterEmail,
    required this.reporterDisplayName,
    this.sourceScreen = '',
    this.contextType = '',
    this.lessonId,
    this.categoryId,
    this.signId,
    this.signLabel,
    this.metadata,
  });
}

class IssueReportService {
  final FirebaseFirestore _firestore;

  IssueReportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> submit(IssueReportPayload payload) async {
    final title = payload.title.trim();
    final description = payload.description.trim();
    if (title.isEmpty || description.isEmpty) {
      throw ArgumentError('Title and description are required');
    }

    final reporterUid = payload.reporterUid.trim();
    if (reporterUid.isEmpty) {
      throw ArgumentError('Reporter UID is required');
    }

    final now = FieldValue.serverTimestamp();
    await _firestore.collection('issues').add(<String, dynamic>{
      'title': title,
      'description': description,
      'type': _normalizeType(payload.type),
      'priority': _normalizePriority(payload.priority),
      'status': 'open',
      'reportedBy': reporterUid,
      'reporterUid': reporterUid,
      'reporterEmail': payload.reporterEmail.trim(),
      'reporterDisplayName': payload.reporterDisplayName.trim(),
      'sourceScreen': payload.sourceScreen.trim(),
      'contextType': payload.contextType.trim(),
      'lessonId': _nullableTrim(payload.lessonId),
      'categoryId': _nullableTrim(payload.categoryId),
      'signId': _nullableTrim(payload.signId),
      'signLabel': _nullableTrim(payload.signLabel),
      'metadata': payload.metadata ?? <String, dynamic>{},
      'createdAt': now,
      'updatedAt': now,
    });
  }

  String _normalizeType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'bug':
      case 'feature':
      case 'content':
      case 'other':
        return value.trim().toLowerCase();
      default:
        return 'other';
    }
  }

  String _normalizePriority(String value) {
    switch (value.trim().toLowerCase()) {
      case 'low':
      case 'medium':
      case 'high':
      case 'critical':
        return value.trim().toLowerCase();
      default:
        return 'medium';
    }
  }

  String? _nullableTrim(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
