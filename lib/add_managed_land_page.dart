import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddManagedLandPage extends StatefulWidget {
  const AddManagedLandPage({Key? key}) : super(key: key);

  @override
  State<AddManagedLandPage> createState() => _AddManagedLandPageState();
}

class _AddManagedLandPageState extends State<AddManagedLandPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerPhoneController = TextEditingController();

  final Color oliveGreen = const Color(0xFF606C38);

  Future<void> _saveManagedLand() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('managed_lands').add({
          'farmerId': user.uid,
          'address': _addressController.text.trim(),
          'ownerName': _ownerNameController.text.trim(),
          'ownerPhone': _ownerPhoneController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Managed land added successfully!')),
        );
        Navigator.pop(context); // Go back to the previous page
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding managed land: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Managed Land'),
        backgroundColor: oliveGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Land Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on, color: oliveGreen),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the land address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _ownerNameController,
                decoration: InputDecoration(
                  labelText: 'Land Owner Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, color: oliveGreen),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the land owner\'s name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _ownerPhoneController,
                decoration: InputDecoration(
                  labelText: 'Land Owner Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone, color: oliveGreen),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the land owner\'s phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                onPressed: _saveManagedLand,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Save Managed Land',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: oliveGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
