import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart'; // استيراد صفحة البروفايل

class CreatePostPage extends StatefulWidget {
  final String? postId;
  final Map<String, dynamic>? existingData;

  const CreatePostPage({Key? key, this.postId, this.existingData})
      : super(key: key);

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final phoneController = TextEditingController();
  final descriptionController = TextEditingController();

  bool isLoading = false;

  final Color oliveGreen = const Color(0xFF606C38);
  final Color inputBackground = const Color(0xFFEAEAD9);

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      titleController.text = widget.existingData!['title'] ?? '';
      locationController.text = widget.existingData!['location'] ?? '';
      phoneController.text = widget.existingData!['phone'] ?? '';
      descriptionController.text = widget.existingData!['description'] ?? '';
    }
  }

  void submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      final post = {
        'ownerId': user!.uid,
        'title': titleController.text.trim(),
        'location': locationController.text.trim(),
        'phone': phoneController.text.trim(),
        'description': descriptionController.text.trim(),
        'datePosted': DateTime.now(),
      };

      final postsRef = FirebaseFirestore.instance.collection('posts');

      if (widget.postId != null) {
        await postsRef.doc(widget.postId).update(post);
      } else {
        await postsRef.add(post);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  widget.postId != null ? 'Post updated' : 'Post created')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int? maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: oliveGreen)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: keyboardType == TextInputType.multiline
              ? TextInputAction.newline
              : TextInputAction.done,
          validator: (value) =>
              value!.isEmpty ? 'This field is required' : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: oliveGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ProfilePage(user: FirebaseAuth.instance.currentUser)),
            );
          },
        ),
        title: Text(widget.postId != null ? 'Edit Post' : 'Create Post'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _buildTextField(
                          label: 'Title', controller: titleController),
                      _buildTextField(
                          label: 'Location', controller: locationController),
                      _buildTextField(
                        label: 'For contact (Phone number)',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        label: 'Description',
                        controller: descriptionController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 12),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Center(
                              child: ElevatedButton(
                                onPressed: submitPost,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: oliveGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 12),
                                ),
                                child: Text(
                                    widget.postId != null ? 'Update' : 'Post'),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
