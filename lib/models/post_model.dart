import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id; // معرف البوست
  final String ownerId; // معرف صاحب الأرض
  final String title; // عنوان البوست
  final String description; // وصف الأرض أو الطلب
  final String location; // موقع الأرض
  final double area; // المساحة بالدونم
  final DateTime datePosted; // وقت النشر
  final bool isRented; // هل تم تأجير الأرض
  final String? rentedByUserId; // المزارع اللي ضمنها (اختياري)
  final DateTime? rentedAt; // وقت الضمان (اختياري)
  final List<String> likedBy; // المستخدمين اللي عملوا لايك

  Post({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.location,
    required this.area,
    required this.datePosted,
    this.isRented = false,
    this.rentedByUserId,
    this.rentedAt,
    this.likedBy = const [],
  });

  // من Firebase
  factory Post.fromMap(Map<String, dynamic> map, String documentId) {
    return Post(
      id: documentId,
      ownerId: map['ownerId'],
      title: map['title'],
      description: map['description'],
      location: map['location'],
      area: map['area']?.toDouble() ?? 0.0,
      datePosted: map['datePosted'] != null
          ? (map['datePosted'] as Timestamp).toDate()
          : DateTime.now(),
      isRented: map['isRented'] ?? false,
      rentedByUserId: map['rentedByUserId'],
      rentedAt: map['rentedAt'] != null
          ? (map['rentedAt'] as Timestamp).toDate()
          : null,
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  // إلى Firebase
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'location': location,
      'area': area,
      'datePosted': Timestamp.fromDate(datePosted),
      'isRented': isRented,
      'rentedByUserId': rentedByUserId,
      'rentedAt': rentedAt != null ? Timestamp.fromDate(rentedAt!) : null,
      'likedBy': likedBy,
    };
  }
}
