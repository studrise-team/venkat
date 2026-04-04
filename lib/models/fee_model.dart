class FeeModel {
  final String id;
  final String studentId;
  final String studentName;
  final double totalAmount;
  final double paidAmount;
  final String status; // 'Paid', 'Partial', 'Pending'
  final DateTime dueDate;
  final DateTime? lastPaymentDate;
  final String remarks;

  FeeModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.dueDate,
    this.lastPaymentDate,
    this.remarks = '',
  });

  factory FeeModel.fromMap(String id, Map<String, dynamic> map) {
    return FeeModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'Pending',
      dueDate: map['dueDate'] != null ? (map['dueDate'] as dynamic).toDate() : DateTime.now(),
      lastPaymentDate: map['lastPaymentDate'] != null ? (map['lastPaymentDate'] as dynamic).toDate() : null,
      remarks: map['remarks'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status,
      'dueDate': dueDate,
      'lastPaymentDate': lastPaymentDate,
      'remarks': remarks,
    };
  }

  double get pendingAmount => totalAmount - paidAmount;
}
