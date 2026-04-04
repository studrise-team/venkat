import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialModel {
  final String id;
  final String title;
  final String description;
  final String contentUrl; // URL for the material (PDF, image, link)
  final String type; // 'PDF', 'Video', 'Link', 'Image'
  final String subject;
  final DateTime createdAt;

  MaterialModel({
    required this.id,
    required this.title,
    required this.description,
    required this.contentUrl,
    required this.type,
    required this.subject,
    required this.createdAt,
  });

  factory MaterialModel.fromMap(String id, Map<String, dynamic> map) {
    return MaterialModel(
      id: id,
      title: map['title'] ?? 'Untitled',
      description: map['description'] ?? '',
      contentUrl: map['contentUrl'] ?? '',
      type: map['type'] ?? 'Link',
      subject: map['subject'] ?? 'General',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'contentUrl': contentUrl,
      'type': type,
      'subject': subject,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
