import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CaptureImagePage extends StatefulWidget {
  const CaptureImagePage({Key? key}) : super(key: key);

  @override
  _CaptureImagePageState createState() => _CaptureImagePageState();
}

class _CaptureImagePageState extends State<CaptureImagePage> {
  bool _isLoading = false;

  Future<void> _sendCaptureRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in first")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final raspberryIp = '10.79.219.237';
      final uid = user.uid;
      final uri =
          Uri.parse('http://$raspberryIp:5000/capture_annotated?uid=$uid');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final imageUrl = json['image_url'];
        final result = json['result'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(imageUrl: imageUrl, result: result),
          ),
        );
      } else {
        final errorJson = jsonDecode(response.body);
        final errorMessage = errorJson['error'] ?? 'Failed to send request';
        throw Exception(errorMessage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Capture and Analyze Image"),
        backgroundColor: const Color(0xFF606C38),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.camera_alt,
                size: 100,
                color: const Color(0xFF606C38).withOpacity(0.8),
              ),
              const SizedBox(height: 20),
              const Text(
                'Press the button below to send a command to the analysis device to capture and process an image.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.camera),
                      label: const Text("Start Capture and Analysis"),
                      onPressed: _sendCaptureRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF606C38),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final String imageUrl;
  final String result;

  const ResultPage({required this.imageUrl, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analysis Result"),
        backgroundColor: const Color(0xFF606C38),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Image.network(
            imageUrl,
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image),
          ),
          const SizedBox(height: 20),
          Text(
            result,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
