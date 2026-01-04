import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DriverPage extends StatefulWidget {
  final int driverId;
  const DriverPage({super.key, required this.driverId});

  @override
  State<DriverPage> createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends State<DriverPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  final baseHost = "backend-coral-eta-14.vercel.app";

  bool loading = true;
  String errorMsg = "";
  List trips = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    fetchDriverTrips();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> fetchDriverTrips() async {
    setState(() {
      loading = true;
      errorMsg = "";
    });

    try {
      final uri = Uri.https(baseHost, "/api/admin/trips/list", {
        "driverId": widget.driverId.toString(),
      });

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

  List get assignedTrips {
    return trips.where((t) {
      final s = (t["status"] ?? "pending").toString();
      return s == "assigned" || s == "approved";
    }).toList();
  }

  List get historyTrips {
    return trips.where((t) {
      final s = (t["status"] ?? "pending").toString();
      return s == "completed" || s == "cancelled" || s == "rejected";
    }).toList();
  }

  String niceDate(dynamic v) {
    if (v == null) return "-";
    final s = v.toString();
    return s.replaceAll("T", " ").replaceAll(".000Z", "");
  }

  Future<void> updateTripStatus({
    required int tripId,
    required String status,
  }) async {
    try {
      final uri = Uri.https(baseHost, "/api/admin/trips/update");

      final body = {
        "tripId": tripId,
        "status": status,
        "adminNote": "Updated by driver ${widget.driverId}",
      };

      final res = await http
          .post(uri, headers: {"Content-Type": "application/json"}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["ok"] == true) {
        setState(() {
          final i = trips.indexWhere((t) => (t["id"] ?? "").toString() == tripId.toString());
          if (i != -1) trips[i]["status"] = status;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Trip #$tripId updated ")),
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

  Future<void> confirmComplete(int tripId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Complete trip?"),
        content: Text("Mark trip #$tripId as completed?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Complete"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await updateTripStatus(tripId: tripId, status: "completed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        elevation: 2,
        title: const Text("Driver Trips", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: fetchDriverTrips, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          tabs: [
            Tab(text: "Assigned (${assignedTrips.length})"),
            Tab(text: "History (${historyTrips.length})"),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg.isNotEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(errorMsg, style: const TextStyle(color: Colors.red))))
              : TabBarView(
                  controller: _tab,
                  children: [
                    _TripsListDriver(
                      trips: assignedTrips,
                      niceDate: niceDate,
                      onComplete: confirmComplete,
                    ),
                    _TripsListDriver(
                      trips: historyTrips,
                      niceDate: niceDate,
                      onComplete: (_) {},
                      hideActions: true,
                    ),
                  ],
                ),
    );
  }
}

class _TripsListDriver extends StatelessWidget {
  final List trips;
  final String Function(dynamic) niceDate;
  final void Function(int) onComplete;
  final bool hideActions;

  const _TripsListDriver({
    required this.trips,
    required this.niceDate,
    required this.onComplete,
    this.hideActions = false,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return const Center(child: Text("No trips", style: TextStyle(color: Colors.black54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: trips.length,
      itemBuilder: (_, i) {
        final t = trips[i];
        final id = (t["id"] ?? 0) is int ? t["id"] : int.tryParse(t["id"].toString()) ?? 0;

        final pickup = (t["pickup_location"] ?? "-").toString();
        final drop = (t["drop_location"] ?? "-").toString();
        final uni = (t["university"] ?? "-").toString();
        final pay = (t["payment_method"] ?? "-").toString();
        final price = (t["price"] ?? 0).toString();
        final time = niceDate(t["ride_time"]);
        final status = (t["status"] ?? "pending").toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$pickup → $drop", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text("University: $uni • Payment: $pay", style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 6),
              Text("Time: $time", style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(status, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  const Spacer(),
                  Text("\$$price", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if (!hideActions) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => onComplete(id),
                    icon: const Icon(Icons.check),
                    label: const Text("Complete Trip"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                )
              ]
            ],
          ),
        );
      },
    );
  }
}