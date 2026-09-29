import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ApiService {
  static const String baseUrl = 'https://pibd.org/api';

  static const String tokenKey = 'auth_token';
  static const String rememberedEmailKey = 'remembered_email';
  static const String sessionStartedKey = 'session_started_at';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'device_name': 'pibd-employee-app',
        },
      );

      final data = _asMap(response.data);
      final token = data['token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception('Login token was not received.');
      }

      await _storage.write(key: tokenKey, value: token);

      await _saveLoginSession(email: email, rememberMe: rememberMe);

      return data;
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(
          error,
          fallback: 'Login failed. Please check your internet connection.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _authenticatedGet('/auth/me');
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, fallback: 'Profile could not be loaded.'),
      );
    }
  }

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _authenticatedGet('/employee/dashboard');

      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, fallback: 'Dashboard could not be loaded.'),
      );
    }
  }

  Future<Map<String, dynamic>> createStockItem(
    Map<String, dynamic> data,
  ) async {
    final response = await _authenticatedPost('/admin/stock/items', data: data);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> updateStockItem(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _authenticatedPut(
      '/admin/stock/items/$id',
      data: data,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> recordStockTransaction(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _authenticatedPost(
      '/admin/stock/items/$id/transactions',
      data: data,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getAttendance({int? month, int? year}) async {
    try {
      final now = DateTime.now();

      final response = await _authenticatedGet(
        '/employee/attendance',
        queryParameters: {
          'month': month ?? now.month,
          'year': year ?? now.year,
        },
      );

      final data = _asMap(response.data);

      if (data['success'] == false) {
        throw Exception(
          data['message']?.toString() ?? 'Attendance could not be loaded.',
        );
      }

      return data;
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, fallback: 'Attendance could not be loaded.'),
      );
    }
  }

  Future<Map<String, dynamic>> submitAttendance({String status = 'P'}) async {
    try {
      final response = await _authenticatedPost(
        '/employee/attendance',
        data: {'status': status},
      );

      return _asMap(response.data);
    } on DioException catch (error) {
      final responseData = error.response?.data;

      if (error.response?.statusCode == 409 && responseData is Map) {
        throw Exception(
          responseData['message']?.toString() ??
              'Attendance has already been submitted today.',
        );
      }

      throw Exception(
        _errorMessage(error, fallback: 'Attendance could not be submitted.'),
      );
    }
  }

  Future<Map<String, dynamic>> getLeaveRequests({int page = 1}) async {
    try {
      final response = await _authenticatedGet(
        '/employee/leave',
        queryParameters: {'page': page},
      );

      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, fallback: 'Leave requests could not be loaded.'),
      );
    }
  }

  Future<Map<String, dynamic>> submitLeaveRequest({
    required String leaveType,
    String? project,
    required String startDate,
    required String endDate,
    required String reason,
    required String relieverName,
    String? relieverDesignation,
    String? comments,
  }) async {
    try {
      final response = await _authenticatedPost(
        '/employee/leave',
        data: {
          'leave_type': leaveType,
          'project': project,
          'start_date': startDate,
          'end_date': endDate,
          'reason': reason,
          'reliever_name': relieverName,
          'reliever_designation': relieverDesignation,
          'comments': comments,
        },
      );

      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, fallback: 'Leave request could not be submitted.'),
      );
    }
  }

  Future<String> downloadLeaveDocument(int leaveId) async {
    final token = await _requiredToken();

    try {
      final response = await _dio.get<List<int>>(
        '/employee/leave/$leaveId/document',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/leave-application-$leaveId.docx');

      await file.writeAsBytes(response.data ?? <int>[]);
      await OpenFilex.open(file.path);

      return file.path;
    } on DioException catch (error) {
      await _clearTokenIfUnauthorized(error);

      throw Exception(
        _errorMessage(
          error,
          fallback: 'Leave document could not be downloaded.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> getTasks({int page = 1}) async {
    try {
      final response = await _authenticatedGet(
        '/employee/tasks',
        queryParameters: {'page': page},
      );

      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, fallback: 'Tasks could not be loaded.'),
      );
    }
  }

  Future<Map<String, dynamic>> getStock({int page = 1}) async {
    try {
      final response = await _authenticatedGet(
        '/employee/stock',
        queryParameters: {'page': page},
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, fallback: 'Stock could not be loaded.'),
      );
    }
  }

  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    try {
      final response = await _authenticatedGet(
        '/notifications',
        queryParameters: {'page': page},
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, fallback: 'Notifications could not be loaded.'),
      );
    }
  }

  Future<Map<String, dynamic>> getTaskDetails(int assignmentId) async {
    try {
      final response = await _authenticatedGet('/employee/tasks/$assignmentId');

      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, fallback: 'Task details could not be loaded.'),
      );
    }
  }

  Future<Map<String, dynamic>> updateTaskStatus(
    int assignmentId,
    String status,
  ) async {
    try {
      final response = await _authenticatedPatch(
        '/employee/tasks/$assignmentId/status',
        data: {'status': status},
      );

      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, fallback: 'Task status could not be updated.'),
      );
    }
  }

  Future<String> downloadTaskAttachment(
    int assignmentId,
    int attachmentId,
    String fileName,
  ) async {
    final token = await _requiredToken();

    try {
      final response = await _dio.get<List<int>>(
        '/employee/tasks/$assignmentId/attachments/$attachmentId',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(response.data ?? <int>[]);
      await OpenFilex.open(file.path);

      return file.path;
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(
          error,
          fallback: 'Task attachment could not be downloaded.',
        ),
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    try {
      await _authenticatedPut(
        '/auth/password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmation,
        },
      );
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, fallback: 'Password could not be changed.'),
      );
    }
  }

  Future<String?> getRememberedEmail() async {
    return _storage.read(key: rememberedEmailKey);
  }

  Future<bool> hasValidSession() async {
    final token = await _storage.read(key: tokenKey);

    final sessionStartedValue = await _storage.read(key: sessionStartedKey);

    if (token == null ||
        token.isEmpty ||
        sessionStartedValue == null ||
        sessionStartedValue.isEmpty) {
      return false;
    }

    final now = DateTime.now();

    // Friday is the weekly holiday.
    if (now.weekday == DateTime.friday) {
      await clearLocalSession();
      return false;
    }

    final sessionStarted = DateTime.tryParse(sessionStartedValue);

    if (sessionStarted == null) {
      await clearLocalSession();
      return false;
    }

    final sessionAge = now.difference(sessionStarted);

    // Session remains valid for six days.
    if (sessionAge.inDays >= 6) {
      await clearLocalSession();
      return false;
    }

    return true;
  }

  Future<void> clearLocalSession() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: sessionStartedKey);
  }

  Future<Map<String, dynamic>> uploadAvatar(XFile image) async {
    final token = await _requiredToken();

    try {
      final formData = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(
          await image.readAsBytes(),
          filename: image.name,
        ),
      });

      final response = await _dio.post(
        '/auth/avatar',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return _asMap(response.data);
    } on DioException catch (error) {
      await _clearTokenIfUnauthorized(error);

      throw Exception(
        _errorMessage(error, fallback: 'Profile image upload failed.'),
      );
    }
  }

  Future<void> logout() async {
    try {
      final token = await _storage.read(key: tokenKey);

      if (token != null && token.isNotEmpty) {
        await _dio.post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } on DioException {
      // Local session is cleared even if server is unavailable.
    } finally {
      await _storage.delete(key: tokenKey);
      await _storage.delete(key: sessionStartedKey);
    }
  }

  Future<void> _saveLoginSession({
    required String email,
    required bool rememberMe,
  }) async {
    if (rememberMe) {
      await _storage.write(key: rememberedEmailKey, value: email);

      await _storage.write(
        key: sessionStartedKey,
        value: DateTime.now().toIso8601String(),
      );
    } else {
      await _storage.delete(key: rememberedEmailKey);

      await _storage.delete(key: sessionStartedKey);
    }
  }

  Future<Response<dynamic>> _authenticatedGet(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final token = await _requiredToken();

    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (error) {
      await _clearTokenIfUnauthorized(error);
      rethrow;
    }
  }

  Future<Response<dynamic>> _authenticatedPut(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final token = await _requiredToken();

    try {
      return await _dio.put(
        path,
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (error) {
      await _clearTokenIfUnauthorized(error);
      rethrow;
    }
  }

  Future<Response<dynamic>> _authenticatedPatch(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final token = await _requiredToken();

    try {
      return await _dio.patch(
        path,
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (error) {
      await _clearTokenIfUnauthorized(error);
      rethrow;
    }
  }

  Future<Response<dynamic>> _authenticatedPost(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final token = await _requiredToken();

    try {
      return await _dio.post(
        path,
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (error) {
      await _clearTokenIfUnauthorized(error);
      rethrow;
    }
  }

  Future<String> _requiredToken() async {
    final token = await _storage.read(key: tokenKey);

    if (token == null || token.isEmpty) {
      throw Exception('Your session has expired. Please log in again.');
    }

    return token;
  }

  Future<void> _clearTokenIfUnauthorized(DioException error) async {
    if (error.response?.statusCode == 401) {
      await clearLocalSession();
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw Exception('Unexpected response format from the server.');
  }

  String _errorMessage(DioException error, {required String fallback}) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message = responseData['message']?.toString();

      if (message != null && message.isNotEmpty) {
        return message;
      }

      final errors = responseData['errors'];

      if (errors is Map) {
        final messages = <String>[];

        for (final value in errors.values) {
          if (value is List) {
            messages.addAll(value.map((item) => item.toString()));
          } else {
            messages.add(value.toString());
          }
        }

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The server took too long to respond.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Could not connect to the PIBD server.';
    }

    return fallback;
  }
}
