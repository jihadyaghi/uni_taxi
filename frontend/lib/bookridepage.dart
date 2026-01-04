import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/mytripspage.dart';
import 'package:http/http.dart' as http;
class BookridePage extends StatefulWidget {
  final int userId; 
  const BookridePage({super.key, required this.userId});

  @override
  State<BookridePage> createState() => _BookRidePageState();
}

class _BookRidePageState extends State<BookridePage> {
  final _formKey = GlobalKey<FormState>();

  final pickupController = TextEditingController();
  final dropController = TextEditingController();

  String university = "LU";
  String paymentMethod = "cash";

  DateTime? rideDateTime;
  double price = 5.0;

  bool isLoading = false;
  String errorMsg = "";

  final universities = const ["LU", "AUB", "LIU", "BAU", "USEK"];
  final payments = const ["cash", "card", "omt", "wish"];

  @override
  void dispose() {
    pickupController.dispose();
    dropController.dispose();
    super.dispose();
  }

  // ✅ Snack helper
  void showSnack(String msg, {Color? bg}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: bg ?? Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30))),
    );

    if (time == null) return;

    setState(() {
      rideDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String formatDateTime(DateTime dt) {
    String two(int x) => x.toString().padLeft(2, "0");
    return "${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:00";
  }

  Future<void> createTrip() async {
    FocusScope.of(context).unfocus();

    // ✅ Validation + Snack
    if (!_formKey.currentState!.validate()) {
      showSnack("Please fill all required fields");
      return;
    }

    if (rideDateTime == null) {
      setState(() => errorMsg = "Please choose ride date & time");
      showSnack("Please choose ride date & time");
      return;
    }

    setState(() {
      isLoading = true;
      errorMsg = "";
    });

    // ✅ Optional: sending snack
    showSnack("Sending trip request...", bg: Colors.black);

    final url = Uri.parse("https://backend-coral-eta-14.vercel.app/api/trips/create");

    final body = {
      "userId": widget.userId,
      "pickupLocation": pickupController.text.trim(),
      "dropLocation": dropController.text.trim(),
      "university": university,
      "rideTime": formatDateTime(rideDateTime!),
      "paymentMethod": paymentMethod,
      "price": price,
    };

    print("Create Trip body => ${jsonEncode(body)}");

    try {
      final res = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if (res.statusCode == 201 || res.statusCode == 200) {
        if (!mounted) return;

        showSnack("Trip created successfully ✅", bg: Colors.green);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Trip created ✅"),
            content: const Text("Your request is pending admin approval."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyTripsPage(userId: widget.userId),
                    ),
                  );
                },
                child: const Text("Go to My Trips"),
              ),
            ],
          ),
        );
      } else {
        final msg = data["msg"]?.toString() ??
            data["message"]?.toString() ??
            "Failed to create trip";
        setState(() => errorMsg = msg);
        showSnack(msg);
      }
    } catch (e) {
      final msg = "Network/Server error";
      setState(() => errorMsg = msg);
      showSnack(msg);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        elevation: 3,
        title: const Text("Book a Ride", style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Hero card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [Colors.yellow.shade700, Colors.yellow.shade400],
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
                      child: const Icon(Icons.local_taxi, color: Colors.black, size: 34),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Fast, safe rides for students.\nRequest a ride and wait for admin approval.",
                        style: TextStyle(color: Colors.black, fontSize: 14, height: 1.3),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Form card
              Form(
                key: _formKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                      const Text("Trip Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: pickupController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.my_location),
                          labelText: "Pickup location",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Enter pickup location" : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: dropController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          labelText: "Destination",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Enter destination" : null,
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: university,
                              items: universities.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (v) => setState(() {
                                university = v!;
                                price = (university == "AUB") ? 8.0 : 5.0;
                              }),
                              decoration: InputDecoration(
                                labelText: "University",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: paymentMethod,
                              items: payments.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (v) => setState(() => paymentMethod = v!),
                              decoration: InputDecoration(
                                labelText: "Payment",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      InkWell(
                        onTap: pickDateTime,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  rideDateTime == null ? "Choose date & time" : formatDateTime(rideDateTime!),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_money),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Estimated price: \$${price.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (errorMsg.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(errorMsg, style: const TextStyle(color: Colors.red)),
                      ],

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : createTrip,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: Text(isLoading ? "Sending..." : "Request Ride"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow.shade700,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
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