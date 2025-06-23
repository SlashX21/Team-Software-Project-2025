import 'package:flutter/material.dart';
import '../services/app_colors.dart';
import '../services/app_styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Map<String, dynamic> _userProfile = {
    'username': 'john_doe',
    'fullName': 'John Doe',
    'email': 'john.doe@example.com',
    'hasAllergies': true,
    'allergyDescription': 'Peanuts, shellfish, lactose',
  };

  void _showEditDialog() {
    final controller = TextEditingController(text: _userProfile['allergyDescription']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Allergies'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter allergy info...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _userProfile['allergyDescription'] = controller.text.trim();
                _userProfile['hasAllergies'] = controller.text.trim().isNotEmpty;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text("$label: ", style: AppStyles.bodyBold),
          Expanded(child: Text(value, style: AppStyles.bodyRegular)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            _buildRow("Username", _userProfile['username']),
            _buildRow("Full Name", _userProfile['fullName']),
            _buildRow("Email", _userProfile['email']),
            const SizedBox(height: 24),
            Text("Allergies", style: AppStyles.h2),
            const SizedBox(height: 8),
            Text(
              _userProfile['hasAllergies']
                  ? _userProfile['allergyDescription']
                  : "No known allergies",
              style: AppStyles.bodyRegular,
            ),
          ],
        ),
      ),
    );
  }
}
