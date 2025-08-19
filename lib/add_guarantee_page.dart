import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oliveproject/guarantee_model.dart';

class AddGuaranteePage extends StatefulWidget {
  final String postId;
  final String postLocation;
  final String postTitle;

  const AddGuaranteePage({
    Key? key,
    required this.postId,
    required this.postLocation,
    required this.postTitle,
  }) : super(key: key);

  @override
  State<AddGuaranteePage> createState() => _AddGuaranteePageState();
}

class _AddGuaranteePageState extends State<AddGuaranteePage> {
  final _formKey = GlobalKey<FormState>();
  final Color oliveGreen = const Color(0xFF606C38);

  final TextEditingController _farmerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _locationController.text = widget.postLocation;
  }

  @override
  void dispose() {
    _farmerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveGuarantee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      final guarantee = Guarantee(
        id: '',
        postId: widget.postId,
        landOwnerId: currentUser.uid,
        guaranteeName: _farmerNameController.text.trim(),
        guaranteePhone: _phoneController.text.trim(),
        guaranteeAddress: _addressController.text.trim(),
        guaranteeNationalId: '', // تم حذفه، ويمكن تعيينه كـ فارغ
        location: _locationController.text.trim(),
        createdAt: DateTime.now(),
      );

      await GuaranteeService.addGuarantee(guarantee);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guarantee saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving guarantee: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: oliveGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: oliveGreen),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: oliveGreen.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: oliveGreen, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.withOpacity(0.1),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Add Guarantee',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: oliveGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: oliveGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: oliveGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Post Information',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: oliveGreen)),
                  const SizedBox(height: 8),
                  Text('Title: ${widget.postTitle}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Location: ${widget.postLocation}',
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guarantor Information',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: oliveGreen)),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _farmerNameController,
                    label: 'Farmer Name',
                    hint: 'Enter farmer name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Farmer name is required';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Enter phone number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Phone number is required';
                      if (value.trim().length < 10)
                        return 'Invalid phone number';
                      return null;
                    },
                  ),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Enter address',
                    icon: Icons.home,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Address is required';
                      return null;
                    },
                  ),
                  _buildTextField(
                    controller: _locationController,
                    label: 'Land Location',
                    hint: 'Auto-filled from post',
                    icon: Icons.location_on,
                    enabled: false,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveGuarantee,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: oliveGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Text(
                              'Save Guarantee',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
