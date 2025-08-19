import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'dart:convert';

import 'profile_page.dart';
import 'create_post_page.dart';
import 'login_page.dart';
import 'user_notifications_page.dart'; // ✅ إضافة import للصفحة الجديدة

// ✅ تعديل HomePage لتقبل openPostId parameter
class HomePage extends StatefulWidget {
  final String? openPostId; // ✅ إضافة المعامل الجديد

  const HomePage({Key? key, this.openPostId})
      : super(key: key); // ✅ تعديل الـ constructor

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color oliveGreen = const Color(0xFF606C38);
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _configureFirebaseMessaging();
  }

  void _configureFirebaseMessaging() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');

    if (token != null && currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
      print('✅ FCM Token saved to Firestore');
    }
  }

  // ✅ دالة للتحقق من وجود إشعارات غير مقروءة
  Stream<int> _getUnreadNotificationsCount() {
    if (currentUser == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: currentUser!.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 40),
          decoration: BoxDecoration(
            color: oliveGreen,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ إضافة صف يحتوي على الأيقونة والإشعارات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // مساحة فارغة للتوازن
                    SizedBox(width: 48),
                    // الأيقونة الرئيسية والنص
                    Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(shape: BoxShape.circle),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/olive_tree.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Icon(Icons.eco,
                                  color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Home Page',
                            style: TextStyle(color: Colors.white, fontSize: 16))
                      ],
                    ),
                    // ✅ أيقونة الإشعارات مع العداد
                    StreamBuilder<int>(
                      stream: _getUnreadNotificationsCount(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserNotificationsPage(),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 16),
                            child: Stack(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.notifications,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                // ✅ عرض العداد إذا كان هناك إشعارات غير مقروءة
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      child: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : unreadCount.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('datePosted', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: oliveGreen));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No posts yet.'));
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final post = posts[index].data() as Map<String, dynamic>;
                    final postId = posts[index].id;

                    return PostWidget(
                      post: post,
                      postId: postId,
                      currentUser: currentUser,
                      // ✅ تمرير معلومة ما إذا كان هذا البوست يجب فتح الكومنتات له
                      openComments: postId == widget.openPostId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home, color: oliveGreen),
              onPressed: () {},
            ),
            // ✅ إضافة أيقونة الإشعارات في الشريط السفلي أيضاً (اختياري)
            StreamBuilder<int>(
              stream: _getUnreadNotificationsCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;

                return Stack(
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.notifications_outlined, color: oliveGreen),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserNotificationsPage(),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.person_outline, color: oliveGreen),
              onPressed: () {
                if (currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(
                        userId: currentUser!.uid,
                        isViewOnly: false,
                      ),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.logout_outlined, color: oliveGreen),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// باقي الكود يبقى كما هو...
class PostWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;
  final User? currentUser;
  final bool openComments; // ✅ إضافة المعامل الجديد

  const PostWidget({
    Key? key,
    required this.post,
    required this.postId,
    required this.currentUser,
    this.openComments = false, // ✅ القيمة الافتراضية false
  }) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  final Color oliveGreen = const Color(0xFF606C38);
  late final TextEditingController _commentController;
  bool _showComments = false;

  DocumentReference? _editingCommentRef;
  // ✅ المتغير الجديد لتخزين UID صاحب التعليق اللي بنرد عليه
  String? _replyToUserId;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    // ✅ إذا كان openComments = true، افتح الكومنتات مباشرة
    _showComments = widget.openComments;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final serviceAccountJsonString =
          await rootBundle.loadString('assets/service-account.json');
      final serviceAccountJson = json.decode(serviceAccountJsonString);
      final projectId = serviceAccountJson['project_id'];
      final credentials =
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await auth.clientViaServiceAccount(credentials, scopes);
      final request = {
        'message': {
          'token': fcmToken,
          'notification': {'title': title, 'body': body},
          'data': data ?? {},
        }
      };
      final response = await client.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request),
      );
      if (response.statusCode == 200) {
        print('🔔 Notification sent successfully!');
      } else {
        print('❌ Failed to send notification. Code: ${response.statusCode}');
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('❌ An error occurred while sending the notification: $e');
    }
  }

  Future<void> _deletePost() async {
    try {
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .get();

      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    }
  }

  void _editPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostPage(
          postId: widget.postId,
          existingData: widget.post,
        ),
      ),
    );
  }

  // ✅ تعديل sendCommentNotification لإرسال إشعارين عند الحاجة
  Future<void> _sendCommentNotification(String commenterName) async {
    if (widget.currentUser == null) return;

    final postData = widget.post;
    final postOwnerId = postData['ownerId'];
    final commenterId = widget.currentUser!.uid;

    // إشعار لصاحب البوست
    if (postOwnerId != commenterId && postOwnerId != _replyToUserId) {
      final ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(postOwnerId)
          .get();
      final fcmToken = ownerDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        await sendPushNotification(
          fcmToken: fcmToken,
          title: 'New Comment',
          body: '$commenterName commented on your post',
          data: {'postId': widget.postId, 'type': 'comment'},
        );

        // ✅ حفظ الإشعار في قاعدة البيانات
        await FirebaseFirestore.instance.collection('notifications').add({
          'receiverId': postOwnerId,
          'senderId': commenterId,
          'title': 'New Comment',
          'body': '$commenterName commented on your post',
          'postId': widget.postId,
          'type': 'comment',
          'timestamp': DateTime.now(),
          'isRead': false,
        });
      }
    }

    // إشعار لصاحب التعليق (الرد)
    if (_replyToUserId != null && _replyToUserId != commenterId) {
      final replyUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_replyToUserId!)
          .get();
      final fcmToken = replyUserDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        await sendPushNotification(
          fcmToken: fcmToken,
          title: 'New Reply',
          body: '$commenterName replied to your comment',
          data: {'postId': widget.postId, 'type': 'reply'},
        );

        // ✅ حفظ الإشعار في قاعدة البيانات
        await FirebaseFirestore.instance.collection('notifications').add({
          'receiverId': _replyToUserId!,
          'senderId': commenterId,
          'title': 'New Reply',
          'body': '$commenterName replied to your comment',
          'postId': widget.postId,
          'type': 'reply',
          'timestamp': DateTime.now(),
          'isRead': false,
        });
      }
    }

    // تنظيف
    _replyToUserId = null;
  }

  Widget _buildComments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();
        final comments = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...comments.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final commentUserId = data['userId'];
              final isCommentOwner = widget.currentUser != null &&
                  commentUserId == widget.currentUser!.uid;

              return Container(
                margin: EdgeInsets.symmetric(vertical: 6),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black54, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (commentUserId == null) return;
                                  final bool isCurrentUser =
                                      widget.currentUser?.uid == commentUserId;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfilePage(
                                        userId: commentUserId,
                                        isViewOnly: !isCurrentUser,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  data['userName'] ?? 'User',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: oliveGreen,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(data['text'] ?? ''),
                            ],
                          ),
                        ),
                        if (isCommentOwner)
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: 20),
                            onSelected: (value) {
                              if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    return AlertDialog(
                                      title: Text("Confirm Deletion"),
                                      content: Text(
                                          "Are you sure you want to delete this comment?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dialogContext).pop(),
                                          child: Text("Cancel",
                                              style:
                                                  TextStyle(color: oliveGreen)),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(dialogContext).pop();
                                            await doc.reference.delete();
                                          },
                                          child: Text("Delete",
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else if (value == 'edit') {
                                // ✅ إضافة وظيفة التعديل
                                setState(() {
                                  _commentController.text = data['text'];
                                  _editingCommentRef = doc.reference;
                                  _showComments = true;
                                });
                              }
                            },
                            itemBuilder: (_) => [
                              // ✅ إضافة خيار Edit
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: oliveGreen),
                                    SizedBox(width: 8),
                                    Text('Edit',
                                        style: TextStyle(color: oliveGreen)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          )
                      ],
                    ),
                    SizedBox(height: 8),
                    // ✅ عند الضغط على "Reply" (داخل comments.map)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _commentController.text = '@${data['userName']} ';
                          _replyToUserId = data['userId'];
                          _showComments = true;
                        });
                      },
                      child: Text('Reply', style: TextStyle(color: oliveGreen)),
                    ),
                  ],
                ),
              );
            }).toList(),
            Container(
              margin: EdgeInsets.only(top: 12),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: oliveGreen.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _commentController,
                    decoration:
                        InputDecoration(hintText: 'Write your comment...'),
                    maxLines: null,
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        final text = _commentController.text.trim();
                        if (text.isEmpty) return;

                        final user = widget.currentUser;
                        if (user == null) return;

                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get();
                        final userName = userDoc['name'] ?? 'User';

                        if (_editingCommentRef != null) {
                          // تعديل التعليق
                          await _editingCommentRef!.update({'text': text});
                          _editingCommentRef = null;
                        } else {
                          // إضافة تعليق جديد
                          final commentData = {
                            'text': text,
                            'userId': user.uid,
                            'userName': userName,
                            'timestamp': DateTime.now(),
                          };

                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(widget.postId)
                              .collection('comments')
                              .add(commentData);

                          await _sendCommentNotification(userName);
                        }

                        // ✅ بعد إرسال التعليق أو التحديث (ضمن onPressed)
                        _commentController.clear();
                        _replyToUserId = null;
                        FocusScope.of(context).unfocus();
                        setState(() {});
                      },
                      child:
                          Text(_editingCommentRef != null ? "Update" : "Post"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = widget.post['ownerId'];
    final isOwner =
        widget.currentUser != null && widget.currentUser!.uid == ownerId;

    final postTitle = widget.post['title'] ?? '';
    final postLocation = widget.post['location'] ?? '';
    final postPhone = widget.post['phone'] ?? '';
    final postDescription = widget.post['description'] ?? '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEAD9),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }

        final userData =
            userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final userName = userData['name'] ?? 'User';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAEAD9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(
                              userId: ownerId,
                              isViewOnly: !isOwner,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: oliveGreen,
                            child: Icon(Icons.person,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userName,
                              style: TextStyle(
                                color: oliveGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: oliveGreen),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editPost();
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                title: Text('Confirm Deletion'),
                                content: Text(
                                    'Are you sure you want to delete this post?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      _deletePost();
                                    },
                                    child: Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit, color: oliveGreen),
                            SizedBox(width: 8),
                            Text('Edit')
                          ]),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red))
                          ]),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(postTitle,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: oliveGreen)),
              const SizedBox(height: 8),
              if (postLocation.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, color: oliveGreen, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text("Location: $postLocation",
                          style: TextStyle(fontSize: 14, color: oliveGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (postPhone.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.phone, color: oliveGreen, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text("Phone: $postPhone",
                          style: TextStyle(fontSize: 14, color: oliveGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Text(postDescription,
                  style: TextStyle(fontSize: 14, color: oliveGreen)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showComments = !_showComments;
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: oliveGreen, shape: BoxShape.circle),
                          child: Icon(Icons.comment,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 6),
                        Text('Comment', style: TextStyle(color: oliveGreen)),
                      ],
                    ),
                  ),
                ],
              ),
              if (_showComments) ...[
                const Divider(height: 20),
                _buildComments(),
              ]
            ],
          ),
        );
      },
    );
  }
}
