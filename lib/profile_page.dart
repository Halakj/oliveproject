import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'dart:convert';
import 'homepage.dart';
import 'create_post_page.dart';
import 'login_page.dart';
import 'capture_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

//======================================================================
// 1. الويدجت الرئيسية لصفحة الملف الشخصي (ProfilePage)
//======================================================================
class ProfilePage extends StatefulWidget {
  final User? user;
  final String? userId;
  final String? postIdToNavigateTo;
  final bool isViewOnly;

  const ProfilePage({
    Key? key,
    this.user,
    this.userId,
    this.postIdToNavigateTo,
    this.isViewOnly = false,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? currentUser;
  final Color oliveGreen = const Color(0xFF606C38);

  String experience = '';
  String skills = '';
  bool editingExperience = false;
  bool editingSkills = false;
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();

  final Map<String, GlobalKey> _postKeys = {};

  @override
  void initState() {
    super.initState();
    currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
    _loadFarmerData();
    _getTokenAndPrint();

    if (widget.postIdToNavigateTo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToPost(widget.postIdToNavigateTo!);
      });
    }
  }

  void _scrollToPost(String postId) {
    Future.delayed(const Duration(milliseconds: 400), () {
      final key = _postKeys[postId];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      } else {
        print("Error: Could not find key for post: $postId");
      }
    });
  }

  void _getTokenAndPrint() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
    if (token != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
        print('✅ FCM Token saved to Firestore');
      }
    }
  }

  Future<void> _loadFarmerData() async {
    try {
      final uid = widget.userId ?? currentUser!.uid;
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          final experienceData = userData['experience'];
          final skillsData = userData['skills'];
          if (experienceData is String) {
            experience = experienceData;
          } else if (experienceData is List) {
            experience = experienceData.join(', ');
          } else {
            experience = experienceData?.toString() ?? '';
          }
          if (skillsData is String) {
            skills = skillsData;
          } else if (skillsData is List) {
            skills = skillsData.join(', ');
          } else {
            skills = skillsData?.toString() ?? '';
          }
          experienceController.text = experience;
          skillsController.text = skills;
        });
      }
    } catch (e) {
      print('Error loading farmer data: $e');
    }
  }

  Future<void> _saveFarmerData() async {
    try {
      final uid = widget.userId ?? currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'experience': experience,
        'skills': skills,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data saved successfully')),
      );
    } catch (e) {
      print('Error saving farmer data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    }
  }

  Future<DocumentSnapshot> _fetchUserData() {
    final uid = widget.userId ?? currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Widget _buildEditableSection(
    String title,
    String value,
    bool isEditing,
    TextEditingController controller,
    Function(String) onSave,
    VoidCallback onEdit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: oliveGreen)),
              if (!widget.isViewOnly)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onSave('');
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: oliveGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: oliveGreen.withOpacity(0.5)),
            ),
            child: isEditing
                ? TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter ' + title.toLowerCase(),
                    ),
                    maxLines: null,
                  )
                : Text(value.isNotEmpty ? value : 'No information provided',
                    style: TextStyle(fontSize: 16, color: Colors.black87)),
          ),
          if (isEditing && !widget.isViewOnly)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onSave(controller.text.trim()),
                child: Text('Save', style: TextStyle(color: oliveGreen)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final userName = userData['name'] ?? 'User';
        final userType = userData['userType'] ?? 'User';
        final userTypeFormatted =
            userType == 'landOwner' ? 'Land Owner' : 'Farmer';
        final profileImage = userData['profileImage'] ??
            'https://www.gravatar.com/avatar/placeholder?s=200&d=mp';
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            child: ListView(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: oliveGreen,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: _buildProfileHeader(
                      userName, userTypeFormatted, profileImage),
                ),
                const SizedBox(height: 16),
                if (userType == 'landOwner')
                  _buildOwnerPosts()
                else ...[
                  _buildEditableSection(
                    'Experience',
                    experience,
                    editingExperience && !widget.isViewOnly,
                    experienceController,
                    (val) {
                      if (!widget.isViewOnly) {
                        setState(() {
                          experience = val;
                          editingExperience = false;
                        });
                        _saveFarmerData();
                      }
                    },
                    () {
                      if (!widget.isViewOnly) {
                        setState(() {
                          editingExperience = true;
                          experienceController.text = experience;
                        });
                      }
                    },
                  ),
                  _buildEditableSection(
                    'Skills',
                    skills,
                    editingSkills && !widget.isViewOnly,
                    skillsController,
                    (val) {
                      if (!widget.isViewOnly) {
                        setState(() {
                          skills = val;
                          editingSkills = false;
                        });
                        _saveFarmerData();
                      }
                    },
                    () {
                      if (!widget.isViewOnly) {
                        setState(() {
                          editingSkills = true;
                          skillsController.text = skills;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          bottomNavigationBar:
              widget.isViewOnly ? null : _buildBottomNav(userType),
        );
      },
    );
  }

  Widget _buildProfileHeader(
      String userName, String userTypeFormatted, String profileImage) {
    return Column(
      children: [
        if (widget.isViewOnly)
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 10),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(profileImage),
        ),
        const SizedBox(height: 10),
        Text(
          userName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          userTypeFormatted,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(String userType) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.home_outlined, color: oliveGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
              );
            },
          ),
          if (userType == 'landOwner') ...[
            IconButton(
              icon: Icon(Icons.edit_outlined, color: oliveGreen),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreatePostPage()),
                );
              },
            ),
          ],
          if (userType == 'farmer')
            IconButton(
              icon: Icon(Icons.camera_alt_outlined, color: oliveGreen),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CaptureImagePage()),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.person_outline, color: oliveGreen),
            onPressed: () {
              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              final isSameUser =
                  widget.userId == null || widget.userId == currentUid;

              if (!isSameUser) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(
                      user: FirebaseAuth.instance.currentUser,
                      userId: currentUid,
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.logout_outlined, color: oliveGreen),
            onPressed: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerPosts() {
    final uid = widget.userId ?? currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("posts")
          .where("ownerId", isEqualTo: uid)
          .orderBy("datePosted", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No posts yet."));
        }
        final posts = snapshot.data!.docs;
        return ListView.builder(
          itemCount: posts.length,
          padding: const EdgeInsets.all(12),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final postId = posts[index].id;
            _postKeys.putIfAbsent(postId, () => GlobalKey());

            return Container(
              key: _postKeys[postId],
              child: OwnerPostCard(
                postId: postId,
                postData: post,
                currentUser: currentUser!,
              ),
            );
          },
        );
      },
    );
  }
}

//======================================================================
// 2. الويدجت المستقلة للمنشور الواحد (OwnerPostCard)
//======================================================================
class OwnerPostCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;
  final User currentUser;

  const OwnerPostCard({
    Key? key,
    required this.postId,
    required this.postData,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<OwnerPostCard> createState() => _OwnerPostCardState();
}

class _OwnerPostCardState extends State<OwnerPostCard> {
  final Color oliveGreen = const Color(0xFF606C38);
  bool showComments = false;

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
        print('🔔 V1 Notification sent successfully!');
      } else {
        print('❌ Failed to send V1 notification. Code: ${response.statusCode}');
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('❌ A critical error occurred while sending the notification: $e');
    }
  }

  Future<void> _deletePost() async {
    try {
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.postId)
          .collection("comments")
          .get();
      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }
      await FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.postId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("The post has been deleted successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred while deleting the post.")),
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
          existingData: widget.postData,
        ),
      ),
    );
  }

  Widget _commentInputField(String postId) {
    final controller = TextEditingController();
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: oliveGreen.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Write your comment...'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await _addCommentWithNotification(postId, controller.text.trim());
              controller.clear();
            },
            child: Text("Post", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addCommentWithNotification(
      String postId, String commentText) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc['name'] ?? 'User';
      final commentData = {
        'text': commentText,
        'userId': user.uid,
        'userName': userName,
        'timestamp': DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add(commentData);

      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();
      if (postDoc.exists) {
        final postData = postDoc.data()!;
        if (postData['ownerId'] != user.uid) {
          final notificationBody =
              '$userName commented on your post: "$commentText"';
          await FirebaseFirestore.instance.collection('notifications').add({
            'receiverId': postData['ownerId'],
            'senderId': user.uid,
            'title': 'New Comment',
            'body': notificationBody,
            'timestamp': Timestamp.now(),
            'postId': postId,
            'isRead': false,
          });
          final ownerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(postData['ownerId'])
              .get();
          final fcmToken = ownerDoc.data()?['fcmToken'];
          if (fcmToken != null) {
            await sendPushNotification(
              fcmToken: fcmToken,
              title: 'New Comment',
              body: '$userName commented on your post',
              data: {'postId': postId},
            );
          }
        }
      }
    } catch (e) {
      print('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error adding comment. Please try again.")),
        );
      }
    }
  }

  Widget _buildComments(String postId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();
        final comments = snapshot.data!.docs;
        if (comments.isEmpty) {
          return Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No comments yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              _commentInputField(
                  postId), // Show input field even if no comments
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...comments.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final bool isCommentOwner =
                  (widget.currentUser.uid == data['userId']);
              return Container(
                margin: EdgeInsets.symmetric(vertical: 6),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black54, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              final currentUid =
                                  FirebaseAuth.instance.currentUser?.uid;
                              final isCurrentUser =
                                  data['userId'] == currentUid;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(
                                    userId: data['userId'],
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
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                          Text(data['text'] ?? ''),
                        ],
                      ),
                    ),
                    if (isCommentOwner)
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Confirm Deletion"),
                                  content: Text(
                                      "Are you sure you want to delete this comment?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await FirebaseFirestore.instance
                                            .collection('posts')
                                            .doc(postId)
                                            .collection('comments')
                                            .doc(doc.id)
                                            .delete();
                                      },
                                      child: Text("Delete",
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          // --- START OF MODIFICATION ---
                          // Only the delete option is available now
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
                          // --- END OF MODIFICATION ---
                        ],
                      ),
                  ],
                ),
              );
            }).toList(),
            _commentInputField(postId),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = widget.postData["ownerId"];
    final isOwner = widget.currentUser.uid == ownerId;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(ownerId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return SizedBox.shrink();
        }

        final userData =
            userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final userName = userData["name"] ?? "User";

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
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProfilePage(userId: ownerId)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: oliveGreen,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userName,
                              style: TextStyle(
                                color: oliveGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                      icon: Icon(
                        Icons.more_vert,
                        color: oliveGreen,
                      ),
                      onSelected: (value) async {
                        if (value == "edit") {
                          _editPost();
                        } else if (value == "delete") {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Confirm Deletion"),
                                content: Text(
                                    "Are you sure you want to delete this post?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _deletePost();
                                    },
                                    child: Text("Delete",
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
                          value: "edit",
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: oliveGreen),
                              SizedBox(width: 8),
                              Text("Edit"),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: "delete",
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text("Delete",
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(widget.postData["title"] ?? "",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: oliveGreen)),
              const SizedBox(height: 8),
              if (widget.postData["location"] != null &&
                  widget.postData["location"].toString().isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on, color: oliveGreen, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Location: ${widget.postData["location"]}",
                        style: TextStyle(fontSize: 14, color: oliveGreen),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              if (widget.postData["phone"] != null &&
                  widget.postData["phone"].toString().isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.phone, color: oliveGreen, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Phone: ${widget.postData["phone"]}",
                        style: TextStyle(fontSize: 14, color: oliveGreen),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(widget.postData["description"] ?? "",
                  style: TextStyle(fontSize: 14, color: oliveGreen)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showComments = !showComments;
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: oliveGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.comment,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 6),
                        Text("Comment", style: TextStyle(color: oliveGreen)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (showComments) _buildComments(widget.postId),
            ],
          ),
        );
      },
    );
  }
}
