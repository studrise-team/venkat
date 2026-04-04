import 'package:cloud_firestore/cloud_firestore.dart';

class FeesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<double> getStandardFee() async {
    final doc = await _db.collection('settings').doc('fees').get();
    if (doc.exists) {
      return (doc.data()?['standardAmount'] ?? 2000.0).toDouble();
    }
    return 2000.0;
  }

  Future<void> setStandardFee(double amount) async {
    await _db.collection('settings').doc('fees').set({
      'standardAmount': amount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendFeeReminders() async {
    // This is where you would call an Edge Function or use FCM to send notifications
    // For now, we'll mark that a reminder was sent.
    await _db.collection('reminders').add({
      'type': 'fees',
      'sentAt': FieldValue.serverTimestamp(),
      'message': 'Reminder: Please clear your pending fee dues.',
    });
    
    // Logic to notify students with 'pending' status
    // In a real app, you'd trigger a cloud function here.
  }
}
