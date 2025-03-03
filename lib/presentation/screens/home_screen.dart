import 'package:attendance_manager/core/services/google_sheet_service.dart';
import 'package:attendance_manager/data/model/attendance_model.dart';
import 'package:flutter/material.dart';
import 'employee_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleSheetsService _googleSheetsService = GoogleSheetsService();
  List<Attendance> _attendanceRecords = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);

    try {
      final records = await _googleSheetsService.fetchAttendanceRecords();
      setState(() => _attendanceRecords = records);
    } catch (e) {
      print('❌ Error loading attendance data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to load data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAttendance(Attendance record) async {
    try {
      await _googleSheetsService.updateAttendance(record);
      debugPrint('✅ Attendance updated successfully!');
    } catch (e) {
      debugPrint('❌ Error updating attendance: $e');
    }
  }

  void _editAttendance(Attendance record) {
    TextEditingController checkInController =
        TextEditingController(text: record.checkIn);
    TextEditingController checkOutController =
        TextEditingController(text: record.checkOut);
    TextEditingController overtimeController =
        TextEditingController(text: record.overtimeHours.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Attendance for ${record.employeeName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: checkInController,
                decoration: const InputDecoration(labelText: 'Check-in Time'),
              ),
              TextField(
                controller: checkOutController,
                decoration: const InputDecoration(labelText: 'Check-out Time'),
              ),
              TextField(
                controller: overtimeController,
                decoration: const InputDecoration(labelText: 'Overtime Hours'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Attendance updatedRecord = record.copyWith(
                  checkIn: checkInController.text,
                  checkOut: checkOutController.text,
                  overtimeHours: int.tryParse(overtimeController.text) ?? 0,
                );

                _updateAttendance(updatedRecord);

                setState(() {
                  int index = _attendanceRecords
                      .indexWhere((r) => r.employeeID == record.employeeID);
                  if (index != -1) {
                    _attendanceRecords[index] = updatedRecord;
                  }
                });

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Management')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attendanceRecords.isEmpty
              ? const Center(child: Text('No attendance records found.'))
              : ListView.builder(
                  itemCount: _attendanceRecords.length,
                  itemBuilder: (context, index) {
                    final record = _attendanceRecords[index];
                    return Card(
                      child: ListTile(
                        title: Text(record.employeeName),
                        subtitle: Text(
                          'Check-in: ${record.checkIn} | '
                          'Check-out: ${record.checkOut} | '
                          'Overtime: ${record.overtimeHours}h',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editAttendance(record),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AttendanceManagementScreen()),
          );
        },
        child: const Icon(Icons.people),
      ),
    );
  }
}
