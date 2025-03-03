import 'dart:convert';
import 'package:attendance_manager/data/model/attendance_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class GoogleSheetsService {
  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbwte1At4-4q8ARX6zggO3ZMTS2pp0tZQU-FwbtUr65UKbg0ANMnw3DVMVhV4HBL9rLC/exec';

  final Dio _dio = Dio();

  Future<List<Attendance>> fetchAttendanceRecords() async {
    try {
      debugPrint('📥 Fetching attendance records...');
      final response = await _dio.get(_baseUrl);

      debugPrint('📊 Response Status: ${response.statusCode}');
      debugPrint('📊 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;

        List<Attendance> records = data
            .map((e) => Attendance.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        debugPrint(
            '✅ Attendance records fetched successfully: ${records.length} records');
        return records;
      } else {
        throw Exception('❌ Failed to load attendance records');
      }
    } catch (e) {
      debugPrint('❌ Error fetching attendance records: $e');
      throw Exception('Error fetching attendance records: $e');
    }
  }

  Future<void> addAttendance(Attendance attendance) async {
    try {
      debugPrint(
          "🚀 Sending request to add attendance for Employee ID: ${attendance.employeeID}");

      final response = await _dio.post(
        _baseUrl,
        data: jsonEncode({
          "action": "add_attendance",
          "EmployeeID": attendance.employeeID,
          "CheckIn": attendance.checkIn,
          "CheckOut": attendance.checkOut,
          "OvertimeHours": attendance.overtimeHours,
        }),
        options: Options(
          headers: {"Content-Type": "application/json"},
          followRedirects: false,
          validateStatus: (status) => status == 200 || status == 302,
        ),
      );

      debugPrint("📊 Response Status: ${response.statusCode}");
      debugPrint("📊 Response Data: ${response.data}");

      if (response.statusCode == 302) {
        await _handleRedirect(response);
        return;
      }

      if (response.statusCode == 200) {
        debugPrint("✅ Attendance added successfully");
      } else {
        throw Exception("❌ Failed to add attendance");
      }
    } catch (e) {
      debugPrint("❌ Error adding attendance: $e");
      throw Exception('Error adding attendance: $e');
    }
  }

  Future<void> updateAttendance(Attendance attendance) async {
    try {
      debugPrint(
          '🚀 Updating attendance for Employee ID: ${attendance.employeeID}');

      final response = await _dio.post(
        _baseUrl,
        data: jsonEncode({
          "action": "update_attendance",
          "EmployeeID": attendance.employeeID,
          "CheckIn": attendance.checkIn,
          "CheckOut": attendance.checkOut,
          "OvertimeHours": attendance.overtimeHours,
        }),
        options: Options(
          headers: {"Content-Type": "application/json"},
          followRedirects: true, // ✅ Allow redirects
          validateStatus: (status) {
            return status != null && status < 500; // ✅ Handle all 3xx responses
          },
        ),
      );

      debugPrint('📊 Response Status: ${response.statusCode}');
      debugPrint('📊 Raw Response Data: ${response.data}');

      // ✅ Ensure response is a JSON string
      final responseData = response.data is String
          ? jsonDecode(response.data) // If response is a string, decode it
          : response.data; // Otherwise, use it as is

      if (response.statusCode == 200 && responseData['success'] == true) {
        debugPrint('✅ Attendance updated successfully');
      } else {
        throw Exception(
            '❌ Failed to update attendance: ${responseData["error"] ?? response.data}');
      }
    } catch (e) {
      debugPrint('❌ Error updating attendance: $e');
      throw Exception('Error updating attendance: $e');
    }
  }

  Future<void> removeEmployee(String employeeId) async {
    try {
      debugPrint('🚀 Removing employee with ID: $employeeId');

      final response = await _dio.post(
        'https://script.google.com/macros/s/YOUR_DEPLOYED_WEB_APP_URL/exec',
        // ✅ Correct URL
        data: jsonEncode({
          "action": "remove_employee",
          "EmployeeID": employeeId,
        }),
        options: Options(
          headers: {"Content-Type": "application/json"},
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('📊 Response Status: ${response.statusCode}');
      debugPrint('📊 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.data);
        if (responseData['success']) {
          debugPrint('✅ Employee removed successfully');
        } else {
          throw Exception(
              '❌ Failed to remove employee: ${responseData["error"]}');
        }
      } else {
        throw Exception('❌ Failed to remove employee: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ Error removing employee: $e');
      throw Exception('Error removing employee: $e');
    }
  }

  Future<void> _handleRedirect(Response response) async {
    String? redirectUrl = response.headers.value("location");
    if (redirectUrl != null) {
      debugPrint("🔄 Following Redirect: $redirectUrl");
      final newResponse = await _dio.get(redirectUrl);
      debugPrint("📊 Final Response Status: ${newResponse.statusCode}");
      debugPrint("📊 Final Response Data: ${newResponse.data}");

      if (newResponse.statusCode == 200) {
        debugPrint("✅ Action completed successfully after redirect");
      } else {
        throw Exception("❌ Failed to follow redirect");
      }
    } else {
      throw Exception("❌ Redirect URL not found");
    }
  }
}
