import 'package:flutter/material.dart';

class MyProfilePage extends StatelessWidget {
  final int userId;
  const MyProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        elevation: 2,
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [Colors.yellow.shade700, Colors.yellow.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person, color: Colors.black, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Student Account",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "User ID: $userId",
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Info Card (sample)
            _infoCard(
              title: "Personal Info",
              children: const [
                _infoRow(icon: Icons.badge, label: "Name", value: "Sample User"),
                _infoRow(icon: Icons.email, label: "Email", value: "sample@email.com"),
                _infoRow(icon: Icons.school, label: "University", value: "LU"),
              ],
            ),

            const SizedBox(height: 12),

            // Preferences (sample)
            _infoCard(
              title: "Preferences",
              children: const [
                _infoRow(icon: Icons.payments, label: "Default Payment", value: "cash"),
                _infoRow(icon: Icons.location_on, label: "Default City", value: "Tripoli"),
              ],
            ),

            const SizedBox(height: 12),

            // Actions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  _actionTile(
                    icon: Icons.edit,
                    title: "Edit Profile",
                    subtitle: "Later (no backend)",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Edit Profile later ✅")),
                      );
                    },
                  ),
                  const Divider(height: 16),
                  _actionTile(
                    icon: Icons.lock_reset,
                    title: "Change Password",
                    subtitle: "Later (no backend)",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Change Password later ✅")),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Footer tip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lightbulb_outline),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tip: Later you can load profile data from backend بسهولة.",
                      style: TextStyle(color: Colors.black87),
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

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _infoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _infoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}