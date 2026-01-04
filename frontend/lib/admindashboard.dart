import 'package:flutter/material.dart';
import 'package:frontend/admindriverspage.dart';
import 'package:frontend/admintripspage.dart';
import 'package:frontend/adminuserspage.dart';
 

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        elevation: 2,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Refresh later")),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: "Logout",
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
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
                    child: const Icon(Icons.admin_panel_settings, color: Colors.black, size: 34),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Admin",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Manage trips, drivers & users easily.",
                          style: TextStyle(color: Colors.black87, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                  _Pill(
                    text: "Dashboard",
                    bg: Colors.black12,
                    fg: Colors.black,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _dashboardCard(
                  icon: Icons.local_taxi,
                  title: "Trips",
                  subtitle: "Approve / Reject trips",
                  badge: "Manage",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTripsPage()));
                  },
                ),
                _dashboardCard(
                  icon: Icons.person_pin_circle,
                  title: "Drivers",
                  subtitle: "Add / Edit drivers",
                  badge: "Manage",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDriversPage()));
                  },
                ),
                _dashboardCard(
                  icon: Icons.people_alt,
                  title: "Users",
                  subtitle: "Make Driver / View users",
                  badge: "New",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersPage()
                    ));
                  },
                ),
                _dashboardCard(
                  icon: Icons.info_outline,
                  title: "Help",
                  subtitle: "How to use dashboard",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Help later")),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quick Actions",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _actionRow(
                    icon: Icons.pending_actions,
                    title: "Open Trips",
                    subtitle: "View and update trip requests",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTripsPage()));
                    },
                  ),

                  const Divider(height: 18),

                  _actionRow(
                    icon: Icons.badge,
                    title: "Open Drivers",
                    subtitle: "Manage drivers list",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDriversPage()));
                    },
                  ),

                  const Divider(height: 18),

                  _actionRow(
                    icon: Icons.people_alt,
                    title: "Open Users",
                    subtitle: "Make Driver + edit driver info",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersPage()));
                    },
                  ),

                  const Divider(height: 18),

                  _actionRow(
                    icon: Icons.logout,
                    title: "Logout",
                    subtitle: "Return to login screen",
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tip: Use Users → Make Driver to turn a user into a driver with phone/car/plate.",
                      style: TextStyle(color: Colors.grey.shade800),
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

  static Future<void> _confirmLogout(BuildContext context) async {
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

    if (ok == true) {
      Navigator.pop(context);
    }
  }
}
class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Pill({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
Widget _dashboardCard({
  required IconData icon,
  required String title,
  required String subtitle,
  String? badge,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 26, color: Colors.black),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.black54, height: 1.2)),
              const Spacer(),
              const Row(
                children: [
                  Text("Open", style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios, size: 14),
                ],
              )
            ],
          ),
          if (badge != null)
            Align(
              alignment: Alignment.topRight,
              child: _Pill(text: badge, bg: Colors.yellow.shade700, fg: Colors.black),
            ),
        ],
      ),
    ),
  );
}

Widget _actionRow({
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
            child: Icon(icon, size: 20, color: Colors.black),
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