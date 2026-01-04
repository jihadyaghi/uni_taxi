import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final baseHost = "backend-coral-eta-14.vercel.app";

  bool loading = true;
  String errorMsg = "";
  List users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      loading = true;
      errorMsg = "";
    });

    try {
      final uri = Uri.https(baseHost, "/api/admin/users/list");
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["ok"] == true) {
        setState(() {
          users = (data["users"] ?? []) as List;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorMsg = data["msg"]?.toString() ?? "Failed to load users";
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Network/Server error: $e";
      });
    }
  }

  Future<void> openMakeDriverDialog(Map user) async {
    final id = int.tryParse(user["id"].toString()) ?? 0;
    final name = (user["name"] ?? "-").toString();
    final email = (user["email"] ?? "-").toString();
    final role = (user["role"] ?? "user").toString();
    if (role == "driver") {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This user is already a driver ✅")),
      );
      return;
    }

    final phoneCtrl = TextEditingController();
    final carCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    bool isActive = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Make Driver"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "$name\n$email",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: carCtrl,
                decoration: const InputDecoration(
                  labelText: "Car Model",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: plateCtrl,
                decoration: const InputDecoration(
                  labelText: "Plate Number",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              StatefulBuilder(
                builder: (context, setLocal) => SwitchListTile(
                  value: isActive,
                  onChanged: (v) => setLocal(() => isActive = v),
                  title: const Text("Active"),
                ),
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (phoneCtrl.text.trim().isEmpty ||
                  carCtrl.text.trim().isEmpty ||
                  plateCtrl.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow.shade700,
              foregroundColor: Colors.black,
            ),
            child: const Text("Make Driver"),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      final uri = Uri.https(baseHost, "/api/admin/users/makedriver");
      final body = {
        "userId": id,
        "phone": phoneCtrl.text.trim(),
        "carModel": carCtrl.text.trim(),
        "plateNumber": plateCtrl.text.trim(),
        "isActive": isActive ? 1 : 0,
      };

      final res = await http
          .post(uri, headers: {"Content-Type": "application/json"}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["ok"] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$name is now a driver ✅")),
        );
        fetchUsers();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["msg"]?.toString() ?? "Failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    }
  }

  Color roleColor(String role) {
    if (role == "admin") return Colors.blue;
    if (role == "driver") return Colors.green;
    return Colors.orange;
  }

  IconData roleIcon(String role) {
    if (role == "admin") return Icons.admin_panel_settings;
    if (role == "driver") return Icons.badge;
    return Icons.person;
  }

  String niceRole(String role) {
    if (role == "admin") return "Admin";
    if (role == "driver") return "Driver";
    return "User";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        elevation: 2,
        title: const Text("Users (Admin)", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: fetchUsers, icon: const Icon(Icons.refresh)),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(errorMsg, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : users.isEmpty
                  ? const Center(child: Text("No users yet"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: users.length,
                      itemBuilder: (_, i) {
                        final u = users[i];
                        final role = (u["role"] ?? "user").toString();
                        final name = (u["name"] ?? "-").toString();
                        final email = (u["email"] ?? "-").toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 8))
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: roleColor(role),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(roleIcon(role), color: roleColor(role)),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 3),
                                    Text(email, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: roleColor(role),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            niceRole(role),
                                            style: TextStyle(
                                              color: roleColor(role),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              
                              Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: role == "user" ? () => openMakeDriverDialog(u) : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.yellow.shade700,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: const Text("Make Driver", style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}