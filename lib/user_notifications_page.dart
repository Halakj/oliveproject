import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';

class UserNotificationsPage extends StatelessWidget {
  const UserNotificationsPage({Key? key}) : super(key: key);

  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> _deleteAllNotifications(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final Color oliveGreen = const Color(0xFF606C38);

    if (currentUserId == null || currentUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Notifications'),
          backgroundColor: oliveGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notifications'),
        backgroundColor: oliveGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await _markAllAsRead(currentUserId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('All notifications marked as read')),
              );
            },
            tooltip: 'Mark all as read',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete_all') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Delete All Notifications'),
                      content: const Text(
                          'Are you sure you want to delete all notifications? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: Text('Cancel',
                              style: TextStyle(color: oliveGreen)),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Delete All',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed == true) {
                  await _deleteAllNotifications(currentUserId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications deleted')),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete All', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('receiverId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No notifications found",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final notificationId = doc.id;
              final postId = data['postId'];
              final isRead = data['isRead'] ?? false;
              final timestamp = data['timestamp'] as Timestamp?;

              String timeAgo = '';
              if (timestamp != null) {
                final now = DateTime.now();
                final notificationTime = timestamp.toDate();
                final difference = now.difference(notificationTime);

                if (difference.inDays > 0) {
                  timeAgo = '${difference.inDays}d ago';
                } else if (difference.inHours > 0) {
                  timeAgo = '${difference.inHours}h ago';
                } else if (difference.inMinutes > 0) {
                  timeAgo = '${difference.inMinutes}m ago';
                } else {
                  timeAgo = 'Just now';
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                elevation: isRead ? 1 : 3,
                color: isRead ? Colors.grey[50] : Colors.white,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.grey[300] : oliveGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      data['type'] == 'reply' ? Icons.reply : Icons.comment,
                      color: isRead ? Colors.grey[600] : Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'New notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: isRead ? Colors.grey[700] : Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['body'] ?? '',
                        style: TextStyle(
                          color: isRead ? Colors.grey[600] : Colors.grey[800],
                        ),
                      ),
                      if (timeAgo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: oliveGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'mark_read' && !isRead) {
                            await _markAsRead(notificationId);
                          } else if (value == 'delete') {
                            await _deleteNotification(notificationId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Notification deleted')),
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          if (!isRead)
                            PopupMenuItem<String>(
                              value: 'mark_read',
                              child: Row(
                                children: [
                                  Icon(Icons.done, color: oliveGreen),
                                  const SizedBox(width: 8),
                                  Text('Mark as read',
                                      style: TextStyle(color: oliveGreen)),
                                ],
                              ),
                            ),
                          PopupMenuItem<String>(
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
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (!isRead) {
                      await _markAsRead(notificationId);
                    }
                    if (postId != null && postId.isNotEmpty) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(openPostId: postId),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
