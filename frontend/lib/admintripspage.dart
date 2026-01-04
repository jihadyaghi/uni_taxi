 import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminTripsPage extends StatefulWidget {
  const AdminTripsPage({super.key});

  @override
  State<AdminTripsPage> createState() => _AdminTripsPageState();
}

class _AdminTripsPageState extends State<AdminTripsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool loading = true;
  String errorMsg = "";
  List trips = [];

  String query = "";

  final baseHost = "backend-coral-eta-14.vercel.app";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchTrips() async {
    setState(() {
      loading = true;
      errorMsg = "";
    });

    try {
      final uri = Uri.https(baseHost, "/api/admin/trips/list");
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["ok"] == true) {
        setState(() {
          trips = (data["trips"] ?? []) as List;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorMsg = data["msg"]?.toString() ?? "Failed to load trips";
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Network/Server error: $e";
      });
    }
  }

  List get pendingTrips =>
      trips.where((t) => (t["status"] ?? "pending") == "pending").toList();

  List filterTrips(List list) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;

    return list.where((t) {
      final pickup =
          (t["pickup_location"] ?? t["pickupLocation"] ?? "").toString().toLowerCase();
      final drop =
          (t["drop_location"] ?? t["dropLocation"] ?? "").toString().toLowerCase();
      final uni = (t["university"] ?? "").toString().toLowerCase();
      final pay =
          (t["payment_method"] ?? t["paymentMethod"] ?? "").toString().toLowerCase();
      final status = (t["status"] ?? "pending").toString().toLowerCase();

      return pickup.contains(q) ||
          drop.contains(q) ||
          uni.contains(q) ||
          pay.contains(q) ||
          status.contains(q);
    }).toList();
  }

  Color statusColor(String s) {
    switch (s) {
      case "assigned":
        return Colors.deepPurple;
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "completed":
        return Colors.blue;
      case "cancelled":
        return Colors.grey;
      default:
        return Colors.orange; // pending
    }
  }

  IconData statusIcon(String s) {
    switch (s) {
      case "assigned":
        return Icons.person_pin_circle;
      case "approved":
        return Icons.check_circle;
      case "rejected":
        return Icons.cancel;
      case "completed":
        return Icons.verified;
      case "cancelled":
        return Icons.block;
      default:
        return Icons.hourglass_bottom;
    }
  }

  String niceDate(dynamic v) {
    if (v == null) return "-";
    final s = v.toString();
    return s.replaceAll("T", " ").replaceAll(".000Z", "");
  }

  /// ✅ update trip status / assign driver (uses your same backend file)
  Future<void> updateTrip({
    required int tripId,
    required String status,
    String? adminNote,
    int? driverId,
  }) async {
    try {
      final uri = Uri.https(baseHost, "/api/admin/trips/update");

      final body = {
        "tripId": tripId,
        "status": status,
        "adminNote": adminNote ?? "",
        if (driverId != null) "driverId": driverId,
      };

      final res = await http
          .post(uri, headers: {"Content-Type": "application/json"}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["ok"] == true) {
        setState(() {
          final i = trips.indexWhere((t) => (t["id"] ?? "").toString() == tripId.toString());
          if (i != -1) {
            trips[i]["status"] = status;
            trips[i]["admin_note"] = adminNote ?? "";
            if (driverId != null) {
              trips[i]["driver_id"] = driverId;
            }
          }
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Trip #$tripId updated ✅")),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["msg"]?.toString() ?? "Update failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    }
  }

  /// ✅ fetch drivers (from users role='driver' API)
  Future<List> fetchDriversList() async {
    final uri = Uri.https(baseHost, "/api/admin/drivers/list");
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data["ok"] == true) {
      return (data["drivers"] ?? []) as List;
    }
    throw Exception(data["msg"]?.toString() ?? "Failed to load drivers");
  }

  /// ✅ Approve + Assign Dialog
  Future<void> approveAndAssign(int tripId) async {
    final noteCtrl = TextEditingController();
    int? selectedDriverId;
    List drivers = [];
    bool dialogLoading = true;
    String dialogError = "";

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(builder: (context, setD) {
          // load drivers once
          if (dialogLoading && drivers.isEmpty && dialogError.isEmpty) {
            fetchDriversList().then((list) {
              setD(() {
                drivers = list;
                dialogLoading = false;
              });
            }).catchError((e) {
              setD(() {
                dialogError = e.toString();
                dialogLoading = false;
              });
            });
          }

          return AlertDialog(
            title: const Text("Approve & Assign Driver"),
            content: dialogLoading
                ? const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : dialogError.isNotEmpty
                    ? Text(dialogError, style: const TextStyle(color: Colors.red))
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Trip #$tripId"),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              value: selectedDriverId,
                              decoration: const InputDecoration(
                                labelText: "Choose Driver",
                                border: OutlineInputBorder(),
                              ),
                              items: drivers.map((d) {
                                final id = int.tryParse(d["id"].toString()) ?? 0;
                                final name = (d["name"] ?? "Driver").toString();
                                final phone = (d["phone"] ?? "-").toString();
                                final car = (d["car_model"] ?? "-").toString();
                                final plate = (d["plate_number"] ?? "-").toString();

                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text("$name • $phone • $car • $plate"),
                                );
                              }).toList(),
                              onChanged: (v) => setD(() => selectedDriverId = v),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: noteCtrl,
                              decoration: const InputDecoration(
                                labelText: "Admin note (optional)",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDriverId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please choose a driver")),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  // ✅ هنا منستعمل status = assigned (حسب backend تبعك)
                  await updateTrip(
                    tripId: tripId,
                    status: "assigned",
                    adminNote: noteCtrl.text.trim(),
                    driverId: selectedDriverId,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Assign & Approve"),
              ),
            ],
          );
        });
      },
    );
  }

  /// ✅ Reject dialog
  Future<void> rejectTrip(int tripId) async {
    final noteController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Trip?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Trip #$tripId will be rejected."),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: "Admin note (optional)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await updateTrip(
      tripId: tripId,
      status: "rejected",
      adminNote: noteController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = filterTrips(pendingTrips);
    final all = filterTrips(trips);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        elevation: 2,
        title: const Text("Trips (Admin)", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(tooltip: "Refresh", onPressed: fetchTrips, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          tabs: [
            Tab(text: "Pending (${pendingTrips.length})"),
            Tab(text: "All (${trips.length})"),
          ],
        ),
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
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.local_taxi, color: Colors.black),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Review trip requests\nPending: ${pendingTrips.length} • Total: ${trips.length}",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: InputDecoration(
                    hintText: "Search by pickup / destination / university / status",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
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
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _TripsList(
                            trips: pending,
                            statusColor: statusColor,
                            statusIcon: statusIcon,
                            niceDate: niceDate,
                            onApprove: (id) => approveAndAssign(id), // ✅ assign driver
                            onReject: (id) => rejectTrip(id),
                          ),
                          _TripsList(
                            trips: all,
                            statusColor: statusColor,
                            statusIcon: statusIcon,
                            niceDate: niceDate,
                            onApprove: (id) => approveAndAssign(id),
                            onReject: (id) => rejectTrip(id),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _TripsList extends StatelessWidget {
  final List trips;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;
  final String Function(dynamic) niceDate;
  final void Function(int) onApprove;
  final void Function(int) onReject;

  const _TripsList({
    required this.trips,
    required this.statusColor,
    required this.statusIcon,
    required this.niceDate,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return const Center(child: Text("No trips here 👌", style: TextStyle(color: Colors.black54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: trips.length,
      itemBuilder: (_, i) {
        final t = trips[i];
        final id = (t["id"] ?? 0) is int ? t["id"] : int.tryParse(t["id"].toString()) ?? 0;

        final pickup = (t["pickup_location"] ?? t["pickupLocation"] ?? "-").toString();
        final drop = (t["drop_location"] ?? t["dropLocation"] ?? "-").toString();
        final uni = (t["university"] ?? "-").toString();
        final pay = (t["payment_method"] ?? t["paymentMethod"] ?? "-").toString();
        final price = (t["price"] ?? 0).toString();
        final time = niceDate(t["ride_time"] ?? t["trip_time"] ?? t["tripTime"]);
        final status = (t["status"] ?? "pending").toString();
        final note = (t["admin_note"] ?? "").toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 8))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(statusIcon(status), color: statusColor(status), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$pickup → $drop", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text("University: $uni • Payment: $pay", style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text("\$$price", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.black54),
                  const SizedBox(width: 6),
                  Expanded(child: Text(time, style: const TextStyle(color: Colors.black54))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor(status), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Admin note: $note", style: const TextStyle(color: Colors.black87)),
                ),
              ],
              if (status == "pending") ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onReject(id),
                        icon: const Icon(Icons.close),
                        label: const Text("Reject"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onApprove(id),
                        icon: const Icon(Icons.check),
                        label: const Text("Approve"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ],
          ),
        );
      },
    );
  }
}