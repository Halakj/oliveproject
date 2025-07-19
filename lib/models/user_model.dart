enum UserType { landOwner, farmer }

class User {
  final String id;
  final String name;
  final UserType userType;
  final String profileImageUrl;
  final int postsCount; // سيكون دائماً 0 للمزارعين
  final int landsCount;

  // بيانات خاصة بصاحب الأرض
  final List<String>? ownedLands;

  // بيانات خاصة بالمزارع
  final String? experience;
  final List<String>? skills;
  final List<String>? workedLands;

  User({
    required this.id,
    required this.name,
    required this.userType,
    required this.profileImageUrl,
    this.postsCount = 0,
    this.landsCount = 0,
    this.ownedLands,
    this.experience,
    this.skills,
    this.workedLands,
  });

  // إنشاء مستخدم من بيانات JSON (سنستخدمه لاحقاً مع Firebase)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      userType: json['userType'] == 'landOwner'
          ? UserType.landOwner
          : UserType.farmer,
      profileImageUrl: json['profileImageUrl'] ?? '',
      postsCount: json['userType'] == 'landOwner'
          ? (json['postsCount'] ?? 0)
          : 0, // المزارعين لا يمكنهم النشر
      landsCount: json['landsCount'] ?? 0,
      ownedLands: json['userType'] == 'landOwner'
          ? List<String>.from(json['ownedLands'] ?? [])
          : null,
      experience: json['userType'] == 'farmer' ? json['experience'] : null,
      skills: json['userType'] == 'farmer'
          ? List<String>.from(json['skills'] ?? [])
          : null,
      workedLands: json['userType'] == 'farmer'
          ? List<String>.from(json['workedLands'] ?? [])
          : null,
    );
  }

  // تحويل المستخدم إلى JSON (سنستخدمه لاحقاً مع Firebase)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'userType': userType == UserType.landOwner ? 'landOwner' : 'farmer',
      'profileImageUrl': profileImageUrl,
      'postsCount': userType == UserType.landOwner
          ? postsCount
          : 0, // المزارعين لا يمكنهم النشر
      'landsCount': landsCount,
    };

    if (userType == UserType.landOwner) {
      data['ownedLands'] = ownedLands;
    } else {
      data['experience'] = experience;
      data['skills'] = skills;
      data['workedLands'] = workedLands;
    }

    return data;
  }

  // دالة للتحقق مما إذا كان المستخدم يمكنه النشر
  bool canCreatePosts() {
    return userType == UserType.landOwner;
  }
}
