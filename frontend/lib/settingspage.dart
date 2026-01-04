import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true;
  bool darkMode = false;
  bool locationServices = true;

  String language = "English";
  String defaultPayment = "cash";

  final languages = const ["English", "Arabic"];
  final payments = const ["cash", "card", "omt", "wish"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        elevation: 2,
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                    child: const Icon(Icons.settings, color: Colors.black, size: 30),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Customize your UniTaxi experience\n(All options are sample)",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            _sectionTitle("Preferences"),
            _card(
              children: [
                _switchTile(
                  icon: Icons.notifications_active,
                  title: "Notifications",
                  subtitle: "Trip updates & offers",
                  value: notifications,
                  onChanged: (v) => setState(() => notifications = v),
                ),
                const Divider(height: 10),
                _switchTile(
                  icon: Icons.dark_mode,
                  title: "Dark Mode",
                  subtitle: "Sample toggle only",
                  value: darkMode,
                  onChanged: (v) {
                    setState(() => darkMode = v);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Dark mode is sample only")),
                    );
                  },
                ),
                const Divider(height: 10),
                _switchTile(
                  icon: Icons.location_on,
                  title: "Location Services",
                  subtitle: "Help pickup accuracy",
                  value: locationServices,
                  onChanged: (v) => setState(() => locationServices = v),
                ),
              ],
            ),

            const SizedBox(height: 14),
            _sectionTitle("App Settings"),
            _card(
              children: [
                _dropdownTile(
                  icon: Icons.language,
                  title: "Language",
                  subtitle: "Choose app language",
                  value: language,
                  items: languages,
                  onChanged: (v) => setState(() => language = v ?? language),
                ),
                const Divider(height: 10),
                _dropdownTile(
                  icon: Icons.payments,
                  title: "Default Payment",
                  subtitle: "Pre-select in booking",
                  value: defaultPayment,
                  items: payments,
                  onChanged: (v) => setState(() => defaultPayment = v ?? defaultPayment),
                ),
              ],
            ),

            const SizedBox(height: 14),
            _sectionTitle("Account"),
            _card(
              children: [
                _actionTile(
                  icon: Icons.lock_reset,
                  title: "Change Password",
                  subtitle: "Later (no backend)",
                  onTap: () => _snack("Change password later"),
                ),
                const Divider(height: 10),
                _actionTile(
                  icon: Icons.privacy_tip,
                  title: "Privacy Policy",
                  subtitle: "Sample page",
                  onTap: () => _snack("Privacy policy later"),
                ),
                const Divider(height: 10),
                _actionTile(
                  icon: Icons.info_outline,
                  title: "About UniTaxi",
                  subtitle: "Version info",
                  onTap: () => _showAbout(),
                ),
              ],
            ),

            const SizedBox(height: 14),
            _sectionTitle("Danger Zone"),
            _card(
              children: [
                _actionTile(
                  icon: Icons.logout,
                  title: "Logout",
                  subtitle: "Return to login",
                  danger: true,
                  onTap: () => _confirmLogout(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            
            Text(
              "UniTaxi • Settings",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  Widget _sectionTitle(String t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
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
      child: Column(children: children),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.black, size: 20),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        _iconBox(icon),
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
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: Colors.yellow.shade700,
        ),
      ],
    );
  }

  Widget _dropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        _iconBox(icon),
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
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
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
                color: danger ? Colors.red : Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: danger ? Colors.red : Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: danger ? Colors.red : Colors.black),
                  ),
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
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("About UniTaxi"),
        content: const Text(
          "UniTaxi is a student-focused ride app.\n\nVersion: 1.0.0 (Sample)\nBackend: not required for this page.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout?"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      Navigator.pop(context); 
    }
  }
}