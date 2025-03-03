class Attendance {
  final String employeeID;
  final String employeeName;
  late final String checkIn;
  late final String checkOut;
  late final int overtimeHours;
  final String date;
  final bool isPresent;

  Attendance({
    required this.employeeID,
    required this.employeeName,
    required this.checkIn,
    required this.checkOut,
    required this.overtimeHours,
    required this.date,
    required this.isPresent,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      employeeID: json['EmployeeID'].toString(), // Ensure String
      employeeName: json['EmployeeName'] ?? '',
      checkIn: json['CheckIn']?.toString() ?? '', // ✅ Convert to String safely
      checkOut: json['CheckOut']?.toString() ?? '', // ✅ Convert to String safely
      overtimeHours: int.tryParse(json['OvertimeHours'].toString()) ?? 0, // Ensure int
      date: json['Date']?.toString() ?? '', // ✅ Convert to String safely
      isPresent: json['IsPresent'] == 'true' || json['IsPresent'] == true, // Handle both bool and String
    );
  }


  Map<String, dynamic> toJson() {
    return {
      "EmployeeID": employeeID,
      "EmployeeName": employeeName,
      "CheckIn": checkIn,
      "CheckOut": checkOut,
      "OvertimeHours": overtimeHours,
      "Date": date,
      "IsPresent": isPresent,
    };
  }

  /// ✅ **Copy method to update check-in, check-out, or overtime**
  Attendance copyWith({
    String? checkIn,
    String? checkOut,
    int? overtimeHours,
  }) {
    return Attendance(
      employeeID: employeeID,
      employeeName: employeeName,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      date: date,
      isPresent: isPresent,
    );
  }
}
