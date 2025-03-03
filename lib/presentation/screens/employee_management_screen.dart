import 'package:attendance_manager/core/services/google_sheet_service.dart';
import 'package:attendance_manager/data/model/attendance_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  _AttendanceManagementScreenState createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState
    extends State<AttendanceManagementScreen> {
  final GoogleSheetsService _googleSheetsService = GoogleSheetsService();
  List<Attendance> _attendanceRecords = [];
  final TextEditingController _employeeNameController = TextEditingController();
  bool _isLoading = false; // Loader state

  @override
  void initState() {
    super.initState();
    _fetchAttendanceRecords();
  }

  Future<void> _fetchAttendanceRecords() async {
    setState(() => _isLoading = true); // Show loader

    try {
      final records = await _googleSheetsService.fetchAttendanceRecords();
      setState(() => _attendanceRecords = records);
    } catch (e) {
      print('❌ Error loading attendance records: $e');
    } finally {
      setState(() => _isLoading = false); // Hide loader
    }
  }

  Future<void> _addAttendanceRecord() async {
    String name = _employeeNameController.text.trim();
    if (name.isEmpty) return;

    Attendance newRecord = Attendance(
      employeeID: DateTime.now().millisecondsSinceEpoch.toString(),
      employeeName: name,
      checkIn: DateFormat('hh:mm a').format(DateTime.now()),
      // Format time as "08:00 AM"
      checkOut: DateFormat('hh:mm a').format(DateTime.now()),
      // Format time as "05:00 PM"
      overtimeHours: 0,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      // Format date as "YYYY-MM-DD"
      isPresent: true, // Assume the employee is present when adding
    );

    setState(() => _isLoading = true); // Show loader

    try {
      await _googleSheetsService.addAttendance(newRecord);
      setState(() {
        _attendanceRecords.add(newRecord);
        _employeeNameController.clear();
      });
    } catch (e) {
      print('❌ Error adding attendance record: $e');
    } finally {
      setState(() => _isLoading = false); // Hide loader
    }
  }

  Future<void> _removeAttendanceRecord(Attendance record) async {
    setState(() => _isLoading = true); // Show loader

    try {
      await _googleSheetsService.removeEmployee(record.employeeID);
      setState(() {
        _attendanceRecords
            .removeWhere((r) => r.employeeID == record.employeeID);
      });
    } catch (e) {
      print('❌ Error removing attendance record: $e');
    } finally {
      setState(() => _isLoading = false); // Hide loader
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Management')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator()) // Show loader
                : ListView.builder(
                    itemCount: _attendanceRecords.length,
                    itemBuilder: (context, index) {
                      final record = _attendanceRecords[index];
                      return Card(
                        child: ListTile(
                          title: Text(record.employeeName),
                          subtitle: Text(
                              "Check-In: ${record.checkIn} | Check-Out: ${record.checkOut}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () => _removeAttendanceRecord(record),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _employeeNameController,
                    decoration:
                        const InputDecoration(labelText: 'Employee Name'),
                  ),
                ),
                IconButton(
                  icon: _isLoading
                      ? const CircularProgressIndicator() // Show loader
                      : const Icon(Icons.add, color: Colors.blue),
                  onPressed: _isLoading ? null : _addAttendanceRecord,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
