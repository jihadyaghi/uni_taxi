import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminDriversPage extends StatefulWidget {
  const AdminDriversPage({super.key});

  @override
  State<AdminDriversPage> createState() => _AdminDriversPageState();
}

class _AdminDriversPageState extends State<AdminDriversPage> {
  final baseHost = "backend-coral-eta-14.vercel.app";

  bool loading = true;
  String errorMsg = "";
  List drivers = [];

  String query = "";

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    setState(() {
      loading = true;
      errorMsg = "";
    });

    try {
      final uri = Uri.https(baseHost, "/api/admin/drivers/list");
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["ok"] == true) {
        setState(() {
          drivers = (data["drivers"] ?? []) as List;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorMsg = data["msg"]?.toString() ?? "Failed to load drivers";
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Network/Server error: $e";
      });
    }
  }

  Future<void> openEditDriver(Map driver) async {
    final id = int.tryParse(driver["id"].toString()) ?? 0;
    final name = (driver["name"] ?? "-").toString();

    final phoneCtrl = TextEditingController(text: (driver["phone"] ?? "").toString());
    final carCtrl = TextEditingController(text: (driver["car_model"] ?? "").toString());
    final plateCtrl = TextEditingController(text: (driver["plate_number"] ?? "").toString());

    bool isActive = (driver["is_active"] ?? 1).toString() == "1";

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Driver"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isActive ? "Active" : "Inactive",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: "Phone", border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),

              TextField(
                controller: carCtrl,
                decoration: const InputDecoration(labelText: "Car Model", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: plateCtrl,
                decoration: const InputDecoration(labelText: "Plate Number", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),

              StatefulBuilder(
                builder: (context, setLocal) => SwitchListTile(
                  value: isActive,
                  onChanged: (v) => setLocal(() => isActive = v),
                  title: const Text("Active"),
                ),
              ),
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
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final body = {
      "driverId": id,
      "phone": phoneCtrl.text.trim(),
      "carModel": carCtrl.text.trim(),
      "plateNumber": plateCtrl.text.trim(),
      "isActive": isActive ? 1 : 0,
    };

    try {
      final uri = Uri.https(baseHost, "/api/admin/drivers/update");
      final res = await http
          .post(uri, headers: {"Content-Type": "application/json"}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && (data["ok"] == true || data["ok"] == null)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Driver updated")));
        fetchDrivers();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["msg"]?.toString() ?? "Update failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Network error: $e")));
    }
  }

  Future<void> deleteDriver(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove Driver?"),
        content: Text("This will remove driver role from:\n$name\n\n(Driver will become a normal user)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final uri = Uri.https(baseHost, "/api/admin/drivers/delete", {"driverId": id.toString()});
      final res = await http.delete(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["ok"] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Driver removed ✅")));
        fetchDrivers();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["msg"]?.toString() ?? "Remove failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Network error: $e")));
    }
  }

  Color statusColor(bool active) => active ? Colors.green : Colors.red;

  List get filteredDrivers {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return drivers;
    return drivers.where((d) {
      final name = (d["name"] ?? "").toString().toLowerCase();
      final phone = (d["phone"] ?? "").toString().toLowerCase();
      final car = (d["car_model"] ?? "").toString().toLowerCase();
      final plate = (d["plate_number"] ?? "").toString().toLowerCase();
      return name.contains(q) || phone.contains(q) || car.contains(q) || plate.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredDrivers;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        elevation: 2,
        title: const Text("Drivers (Admin)", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: fetchDrivers, icon: const Icon(Icons.refresh)),
        ],
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow.shade700, Colors.yellow.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.person_pin_circle, color: Colors.black),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Manage drivers (edit / remove)\nTotal: ${drivers.length}",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: InputDecoration(
                    hintText: "Search by name / phone / car / plate",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : errorMsg.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(errorMsg, style: const TextStyle(color: Colors.red)),
                        ),
                      )
                    : list.isEmpty
                        ? const Center(child: Text("No drivers found"))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final d = list[i];
                              final id = int.tryParse(d["id"].toString()) ?? 0;
                              final name = (d["name"] ?? "-").toString();
                              final phone = (d["phone"] ?? "-").toString();
                              final car = (d["car_model"] ?? "-").toString();
                              final plate = (d["plate_number"] ?? "-").toString();
                              final active = (d["is_active"] ?? 1).toString() == "1";

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
                                        color: statusColor(active),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        active ? Icons.verified : Icons.block,
                                        color: statusColor(active),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(height: 4),
                                          Text(" $phone", style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                          Text(" $car • $plate",
                                              style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                        ],
                                      ),
                                    ),

                                    PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == "edit") openEditDriver(d);
                                        if (v == "delete") deleteDriver(id, name);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: "edit", child: Text("Edit")),
                                        PopupMenuItem(value: "delete", child: Text("Remove Driver")),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}