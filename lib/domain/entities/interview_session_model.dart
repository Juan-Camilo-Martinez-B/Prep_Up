enum InterviewType {
  behavioral,
  technical,
  mixed,
}

enum InterviewSessionStatus {
  draft,
  ready,
  inProgress,
  completed,
  analyzed,
}

class InterviewSessionModel {
  const InterviewSessionModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.jobRole,
    required this.status,
    required this.questionCount,
    required this.timeLimitSeconds,
    this.videoReference,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final InterviewType type;
  final String jobRole;
  final InterviewSessionStatus status;
  final int questionCount;
  final int timeLimitSeconds;
  final String? videoReference;

  // TODO: persistir esta sesión en base de datos relacional (historial/estado).
  // TODO: vincular videoReference a almacenamiento no relacional (video/blob).

  InterviewSessionModel copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    InterviewType? type,
    String? jobRole,
    InterviewSessionStatus? status,
    int? questionCount,
    int? timeLimitSeconds,
    String? videoReference,
  }) {
    return InterviewSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      jobRole: jobRole ?? this.jobRole,
      status: status ?? this.status,
      questionCount: questionCount ?? this.questionCount,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      videoReference: videoReference ?? this.videoReference,
    );
  }

  factory InterviewSessionModel.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] as String?) ?? InterviewType.behavioral.name;
    final type = InterviewType.values.firstWhere(
      (e) => e.name == typeRaw,
      orElse: () => InterviewType.behavioral,
    );

    final statusRaw =
        (json['status'] as String?) ?? InterviewSessionStatus.draft.name;
    final status = InterviewSessionStatus.values.firstWhere(
      (e) => e.name == statusRaw,
      orElse: () => InterviewSessionStatus.draft,
    );

    return InterviewSessionModel(
      id: (json['id'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      type: type,
      jobRole: (json['jobRole'] as String?) ?? '',
      status: status,
      questionCount: (json['questionCount'] as int?) ?? 0,
      timeLimitSeconds: (json['timeLimitSeconds'] as int?) ?? 0,
      videoReference: json['videoReference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'type': type.name,
      'jobRole': jobRole,
      'status': status.name,
      'questionCount': questionCount,
      'timeLimitSeconds': timeLimitSeconds,
      'videoReference': videoReference,
    };
  }

  @override
  String toString() {
    return 'InterviewSessionModel(id: $id, userId: $userId, type: ${type.name}, jobRole: $jobRole, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InterviewSessionModel &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            userId == other.userId &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt &&
            type == other.type &&
            jobRole == other.jobRole &&
            status == other.status &&
            questionCount == other.questionCount &&
            timeLimitSeconds == other.timeLimitSeconds &&
            videoReference == other.videoReference;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      createdAt,
      updatedAt,
      type,
      jobRole,
      status,
      questionCount,
      timeLimitSeconds,
      videoReference,
    );
  }
}
