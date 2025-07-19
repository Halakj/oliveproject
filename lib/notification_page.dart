import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FarmerNotificationsPage extends StatefulWidget {
  const FarmerNotificationsPage({Key? key}) : super(key: key);

  @override
  _FarmerNotificationsPageState createState() =>
      _FarmerNotificationsPageState();
}

class _FarmerNotificationsPageState extends State<FarmerNotificationsPage> {
  List<Map<String, String>> notifications = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        error = "You must be logged in.";
        isLoading = false;
      });
      return;
    }

    final uid = user.uid;
    final raspberryIp = '10.79.219.237'; // عدلها حسب IP الرازبيري عندك

    try {
      // هذا endpoint مفترض يرجع آخر تحليل (مثلاً، لو بدك أكتر من تحليل، لازم تغير السيرفر)
      final response = await http.get(
        Uri.parse('http://$raspberryIp:5000/capture_annotated?uid=$uid'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'ok') {
          // نضيف النتيجة ضمن قائمة الإشعارات
          setState(() {
            notifications = [
              {
                'image_url': data['image_url'] ?? '',
                'result': data['result'] ?? '',
              }
            ];
            isLoading = false;
          });
        } else {
          setState(() {
            error = data['message'] ?? 'Unknown error from server';
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load notifications from server');
      }
    } catch (e) {
      setState(() {
        error = "Error: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(error)),
      );
    }

    if (notifications.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No notifications available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmer Notifications"),
        centerTitle: true,
        backgroundColor: const Color(0xFF606C38),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          final url = item['image_url'] ?? '';
          final result = item['result'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  url,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    result,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
