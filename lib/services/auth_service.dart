import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType {
  landOwner,
  farmer,
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // متابعة حالة تسجيل الدخول
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // تسجيل الدخول
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('خطأ في تسجيل الدخول: ${e.message}');
      rethrow;
    }
  }

  // إنشاء حساب جديد
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserType userType,
    String? experience,
    List<String>? skills,
  }) async {
    try {
      // إنشاء حساب في Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // تحضير بيانات المستخدم
      final userData = {
        'id': uid,
        'name': name,
        'email': email,
        'userType': userType == UserType.landOwner ? 'landOwner' : 'farmer',
        'profileImageUrl': '',
        'postsCount': 0,
        'landsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // بيانات إضافية حسب نوع المستخدم
      if (userType == UserType.landOwner) {
        userData['ownedLands'] = [];
      } else {
        userData['experience'] = experience ?? 'لا توجد خبرة سابقة';
        userData['skills'] = skills ?? ['قطف الزيتون'];
        userData['workedLands'] = [];
      }

      // حفظ بيانات المستخدم في Firestore
      await _firestore.collection('users').doc(uid).set(userData);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('خطأ في إنشاء الحساب: ${e.message}');
      rethrow;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // إرسال رابط إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // تحديث بيانات المستخدم
  Future<void> updateUserProfile({
    String? name,
    String? profileImageUrl,
    String? experience,
    List<String>? skills,
  }) async {
    if (currentUser == null) throw Exception('لا يوجد مستخدم مسجل الدخول');

    final uid = currentUser!.uid;
    final updateData = <String, dynamic>{};

    if (name != null) updateData['name'] = name;
    if (profileImageUrl != null)
      updateData['profileImageUrl'] = profileImageUrl;

    // فحص نوع المستخدم قبل تحديث خصائص خاصة بالمزارع
    final doc = await _firestore.collection('users').doc(uid).get();
    final userData = doc.data();

    if (userData == null) throw Exception('لم يتم العثور على بيانات المستخدم');

    if (userData['userType'] == 'farmer') {
      if (experience != null) updateData['experience'] = experience;
      if (skills != null) updateData['skills'] = skills;
    }

    await _firestore.collection('users').doc(uid).update(updateData);
  }

  // التحقق إذا كان المستخدم هو مالك أرض
  Future<bool> isLandOwner() async {
    if (currentUser == null) return false;
    final doc =
        await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.data()?['userType'] == 'landOwner';
  }

  // التحقق إذا كان المستخدم هو مزارع
  Future<bool> isFarmer() async {
    if (currentUser == null) return false;
    final doc =
        await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.data()?['userType'] == 'farmer';
  }
}
