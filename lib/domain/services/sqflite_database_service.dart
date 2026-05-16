import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:prep_up/domain/entities/app_settings_model.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/entities/user_model.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';

class SqfliteDatabaseService implements RelationalDatabaseService {
  Database? _database;

  @override
  Future<void> initialize() async {
    if (_database != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'prep_up_local.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            email TEXT,
            display_name TEXT,
            photo_url TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            user_id TEXT PRIMARY KEY,
            theme_mode TEXT,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE interview_sessions (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            type TEXT,
            job_role TEXT,
            status TEXT,
            question_count INTEGER,
            time_limit_seconds INTEGER,
            video_reference TEXT,
            turns TEXT, -- JSON String
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE interview_results (
            id TEXT PRIMARY KEY,
            session_id TEXT,
            user_id TEXT,
            score REAL,
            outcome TEXT,
            breakdown TEXT, -- JSON String
            highlights TEXT, -- JSON String
            personalized_feedback TEXT,
            recommendations TEXT, -- JSON String
            improvement_tips TEXT, -- JSON String
            average_response_seconds REAL,
            total_response_seconds REAL,
            valid_answers_count INTEGER,
            analyzed_at TEXT
          )
        ''');
      },
    );
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;
    
    // Mapear campos de snake_case (DB) a camelCase (JSON Model)
    final row = maps.first;
    return UserModel.fromJson({
      'id': row['id'],
      'email': row['email'],
      'displayName': row['display_name'],
      'photoUrl': row['photo_url'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    });
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (maps.isEmpty) return null;
    
    final row = maps.first;
    return UserModel.fromJson({
      'id': row['id'],
      'email': row['email'],
      'displayName': row['display_name'],
      'photoUrl': row['photo_url'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    });
  }

  @override
  Future<void> upsertUser(UserModel user) async {
    final data = user.toJson();
    await _database!.insert(
      'users',
      {
        'id': data['id'],
        'email': data['email'],
        'display_name': data['displayName'],
        'photo_url': data['photoUrl'],
        'created_at': data['createdAt'],
        'updated_at': data['updatedAt'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<AppSettingsModel?> getSettingsForUser(String userId) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;

    final row = maps.first;
    return AppSettingsModel(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == row['theme_mode'],
        orElse: () => AppThemeMode.system,
      ),
    );
  }

  @override
  Future<void> saveSettingsForUser(String userId, AppSettingsModel settings) async {
    await _database!.insert(
      'settings',
      {
        'user_id': userId,
        'theme_mode': settings.themeMode.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveInterviewSession(InterviewSessionModel session) async {
    final data = session.toJson();
    await _database!.insert(
      'interview_sessions',
      {
        'id': data['id'],
        'user_id': data['userId'],
        'type': data['type'],
        'job_role': data['jobRole'],
        'status': data['status'],
        'question_count': data['questionCount'],
        'time_limit_seconds': data['timeLimitSeconds'],
        'video_reference': data['videoReference'],
        'turns': jsonEncode(data['turns']),
        'created_at': data['createdAt'],
        'updated_at': data['updatedAt'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<InterviewSessionModel?> getInterviewSessionById(String sessionId) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'interview_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (maps.isEmpty) return null;

    final row = maps.first;
    return InterviewSessionModel.fromJson({
      'id': row['id'],
      'userId': row['user_id'],
      'type': row['type'],
      'jobRole': row['job_role'],
      'status': row['status'],
      'questionCount': row['question_count'],
      'timeLimitSeconds': row['time_limit_seconds'],
      'videoReference': row['video_reference'],
      'turns': jsonDecode(row['turns'] ?? '[]'),
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    });
  }

  @override
  Future<List<InterviewSessionModel>> getInterviewHistoryForUser(String userId) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'interview_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((row) {
      return InterviewSessionModel.fromJson({
        'id': row['id'],
        'userId': row['user_id'],
        'type': row['type'],
        'jobRole': row['job_role'],
        'status': row['status'],
        'questionCount': row['question_count'],
        'timeLimitSeconds': row['time_limit_seconds'],
        'videoReference': row['video_reference'],
        'turns': jsonDecode(row['turns'] ?? '[]'),
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      });
    }).toList();
  }

  @override
  Future<void> saveInterviewResult(InterviewResultsModel result) async {
    final data = result.toJson();
    await _database!.insert(
      'interview_results',
      {
        'id': data['id'],
        'session_id': data['sessionId'],
        'user_id': data['userId'],
        'score': data['overallScore'],
        'outcome': data['outcome'],
        'breakdown': jsonEncode(data['breakdown']),
        'highlights': jsonEncode(data['highlights']),
        'personalized_feedback': data['personalizedFeedback'],
        'recommendations': jsonEncode(data['recommendations']),
        'improvement_tips': jsonEncode(data['improvementTips']),
        'average_response_seconds': data['averageResponseSeconds'],
        'total_response_seconds': data['totalResponseSeconds'],
        'valid_answers_count': data['validAnswersCount'],
        'analyzed_at': data['analyzedAt'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<InterviewResultsModel?> getInterviewResultForSession(String sessionId) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'interview_results',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    if (maps.isEmpty) return null;

    final row = maps.first;
    return InterviewResultsModel.fromJson({
      'id': row['id'],
      'sessionId': row['session_id'],
      'userId': row['user_id'],
      'overallScore': row['score'],
      'outcome': row['outcome'],
      'breakdown': jsonDecode(row['breakdown'] ?? '[]'),
      'highlights': jsonDecode(row['highlights'] ?? '[]'),
      'personalizedFeedback': row['personalized_feedback'],
      'recommendations': jsonDecode(row['recommendations'] ?? '[]'),
      'improvementTips': jsonDecode(row['improvement_tips'] ?? '[]'),
      'averageResponseSeconds': row['average_response_seconds'],
      'totalResponseSeconds': row['total_response_seconds'],
      'validAnswersCount': row['valid_answers_count'],
      'analyzedAt': row['analyzed_at'],
    });
  }

  @override
  Future<List<InterviewResultsModel>> getInterviewResultsForUser(String userId) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'interview_results',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'analyzed_at DESC',
    );

    return maps.map((row) {
      return InterviewResultsModel.fromJson({
        'id': row['id'],
        'sessionId': row['session_id'],
        'userId': row['user_id'],
        'overallScore': row['score'],
        'outcome': row['outcome'],
        'breakdown': jsonDecode(row['breakdown'] ?? '[]'),
        'highlights': jsonDecode(row['highlights'] ?? '[]'),
        'personalizedFeedback': row['personalized_feedback'],
        'recommendations': jsonDecode(row['recommendations'] ?? '[]'),
        'improvementTips': jsonDecode(row['improvement_tips'] ?? '[]'),
        'averageResponseSeconds': row['average_response_seconds'],
        'totalResponseSeconds': row['total_response_seconds'],
        'validAnswersCount': row['valid_answers_count'],
        'analyzedAt': row['analyzed_at'],
      });
    }).toList();
  }
}
