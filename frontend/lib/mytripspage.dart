import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
class MyTripsPage extends StatefulWidget {
  final int userId;
  const MyTripsPage({super.key, required this.userId});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  bool loading = true;
  String errorMsg = "";
  List trips = [];

  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchTrips();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchTrips());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchTrips() async {
  try {
    final uri = Uri.https(
      "backend-coral-eta-14.vercel.app",
      "/api/trips/my",
      {"userId": widget.userId.toString()},
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body);

    if (!mounted) return;

    if (res.statusCode == 200 && data["ok"] == true) {
      setState(() {
        trips = (data["trips"] as List?) ?? [];
        loading = false;
        errorMsg = "";
      });
    } else {
      setState(() {
        loading = false;
        errorMsg = data["msg"]?.toString() ?? "Failed to load trips";
      });
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      loading = false;
      errorMsg = "Network/Server error: $e";
    });
  }
}

  Color statusColor(String s) {
    switch (s) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "completed":
        return Colors.blue;
      case "cancelled":
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData statusIcon(String s) {
    switch (s) {
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

  String niceStatus(String s) {
    switch (s) {
      case "approved":
        return "Approved ";
      case "rejected":
        return "Rejected ";
      case "completed":
        return "Completed ";
      case "cancelled":
        return "Cancelled";
      default:
        return "Pending… waiting admin approval ";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        elevation: 3,
        title: const Text("My Trips", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: fetchTrips,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.yellow.shade50, Colors.white, Colors.yellow.shade100],
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMsg.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(errorMsg, style: const TextStyle(color: Colors.red)),
                    ),
                  )
                : trips.isEmpty
                    ? const Center(
                        child: Text(
                          "No trips yet.\nBook a ride to see it here.",
                          textAlign: TextAlign.center,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchTrips,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: trips.length,
                          itemBuilder: (_, i) {
                            final t = trips[i];
                            final status = (t["status"] ?? "pending").toString();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: statusColor(status),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(statusIcon(status), color: statusColor(status)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${t["pickup_location"]}  →  ${t["drop_location"]}",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "University: ${t["university"]}",
                                          style: const TextStyle(color: Colors.black54),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Time: ${t["ride_time"] ?? "-"}",
                                          style: const TextStyle(color: Colors.black54),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: statusColor(status),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                niceStatus(status),
                                                style: TextStyle(
                                                  color: statusColor(status),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              "\$${(t["price"] ?? 0).toString()}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if ((t["admin_note"] ?? "").toString().isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            "Admin note: ${t["admin_note"]}",
                                            style: const TextStyle(color: Colors.black87),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}