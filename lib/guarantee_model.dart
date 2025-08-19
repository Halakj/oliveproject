import 'package:cloud_firestore/cloud_firestore.dart';

class Guarantee {
  final String id;
  final String postId;
  final String landOwnerId;
  final String guaranteeName;
  final String guaranteePhone;
  final String guaranteeAddress;
  final String guaranteeNationalId;
  final String location; // من بيانات البوست
  final DateTime createdAt;
  final Map<String, dynamic>? additionalInfo;

  Guarantee({
    required this.id,
    required this.postId,
    required this.landOwnerId,
    required this.guaranteeName,
    required this.guaranteePhone,
    required this.guaranteeAddress,
    required this.guaranteeNationalId,
    required this.location,
    required this.createdAt,
    this.additionalInfo,
  });

  // تحويل من Firestore Document إلى Guarantee object
  factory Guarantee.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Guarantee(
      id: doc.id,
      postId: data['postId'] ?? '',
      landOwnerId: data['landOwnerId'] ?? '',
      guaranteeName: data['guaranteeName'] ?? '',
      guaranteePhone: data['guaranteePhone'] ?? '',
      guaranteeAddress: data['guaranteeAddress'] ?? '',
      guaranteeNationalId: data['guaranteeNationalId'] ?? '',
      location: data['location'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      additionalInfo: data['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  // تحويل من Guarantee object إلى Map للحفظ في Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'landOwnerId': landOwnerId,
      'guaranteeName': guaranteeName,
      'guaranteePhone': guaranteePhone,
      'guaranteeAddress': guaranteeAddress,
      'guaranteeNationalId': guaranteeNationalId,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'additionalInfo': additionalInfo,
    };
  }

  // نسخة محدثة من الكائن
  Guarantee copyWith({
    String? id,
    String? postId,
    String? landOwnerId,
    String? guaranteeName,
    String? guaranteePhone,
    String? guaranteeAddress,
    String? guaranteeNationalId,
    String? location,
    DateTime? createdAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Guarantee(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      landOwnerId: landOwnerId ?? this.landOwnerId,
      guaranteeName: guaranteeName ?? this.guaranteeName,
      guaranteePhone: guaranteePhone ?? this.guaranteePhone,
      guaranteeAddress: guaranteeAddress ?? this.guaranteeAddress,
      guaranteeNationalId: guaranteeNationalId ?? this.guaranteeNationalId,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

// خدمة إدارة الضمانات
class GuaranteeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'guarantees';

  // إضافة ضمانة جديدة
  static Future<String> addGuarantee(Guarantee guarantee) async {
    try {
      DocumentReference docRef =
          await _firestore.collection(_collection).add(guarantee.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('خطأ في إضافة الضمانة: $e');
    }
  }

  // الحصول على جميع ضمانات مالك الأرض
  static Stream<List<Guarantee>> getGuaranteesByLandOwner(String landOwnerId) {
    return _firestore
        .collection(_collection)
        .where('landOwnerId', isEqualTo: landOwnerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Guarantee.fromFirestore(doc)).toList());
  }

  // الحصول على ضمانات بوست معين
  static Stream<List<Guarantee>> getGuaranteesByPost(String postId) {
    return _firestore
        .collection(_collection)
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Guarantee.fromFirestore(doc)).toList());
  }

  // حذف ضمانة
  static Future<void> deleteGuarantee(String guaranteeId) async {
    try {
      await _firestore.collection(_collection).doc(guaranteeId).delete();
    } catch (e) {
      throw Exception('خطأ في حذف الضمانة: $e');
    }
  }

  // تحديث ضمانة
  static Future<void> updateGuarantee(
      String guaranteeId, Guarantee guarantee) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(guaranteeId)
          .update(guarantee.toFirestore());
    } catch (e) {
      throw Exception('خطأ في تحديث الضمانة: $e');
    }
  }

  // الحصول على ضمانة واحدة
  static Future<Guarantee?> getGuarantee(String guaranteeId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(guaranteeId).get();

      if (doc.exists) {
        return Guarantee.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب الضمانة: $e');
    }
  }
}
