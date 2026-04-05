import 'package:cloud_firestore/cloud_firestore.dart';

class StudyClass {
  final String id;
  final String name;
  final DateTime createdAt;

  StudyClass({required this.id, required this.name, required this.createdAt});

  factory StudyClass.fromMap(String id, Map<String, dynamic> map) {
    return StudyClass(
      id: id,
      name: map['name'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class StudySubject {
  final String id;
  final String classId;
  final String name;
  final String? icon;

  StudySubject({required this.id, required this.classId, required this.name, this.icon});

  factory StudySubject.fromMap(String id, Map<String, dynamic> map) {
    return StudySubject(
      id: id,
      classId: map['classId'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'name': name,
      'icon': icon,
    };
  }
}

class StudyChapter {
  final String id;
  final String subjectId;
  final String classId;
  final String title;
  final int order;

  StudyChapter({required this.id, required this.subjectId, required this.classId, required this.title, this.order = 0});

  factory StudyChapter.fromMap(String id, Map<String, dynamic> map) {
    return StudyChapter(
      id: id,
      subjectId: map['subjectId'] ?? '',
      classId: map['classId'] ?? '',
      title: map['title'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'classId': classId,
      'title': title,
      'order': order,
    };
  }
}

class StudyContent {
  final String id;
  final String chapterId;
  final String type; // 'video', 'test', 'material'
  final String title;
  final String? url;
  final String? data; // e.g. quiz questions JSON or PDF link
  final int order;

  StudyContent({
    required this.id,
    required this.chapterId,
    required this.type,
    required this.title,
    this.url,
    this.data,
    this.order = 0,
  });

  factory StudyContent.fromMap(String id, Map<String, dynamic> map) {
    return StudyContent(
      id: id,
      chapterId: map['chapterId'] ?? '',
      type: map['type'] ?? 'material',
      title: map['title'] ?? '',
      url: map['url'],
      data: map['data'],
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chapterId': chapterId,
      'type': type,
      'title': title,
      'url': url,
      'data': data,
      'order': order,
    };
  }
}
