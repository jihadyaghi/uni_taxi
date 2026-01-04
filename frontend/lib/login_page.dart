import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/admindashboard.dart';
import 'package:frontend/driverpage.dart';
import 'package:frontend/homepage.dart';
import 'package:frontend/signup.dart';
import 'package:http/http.dart' as http;
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String errorsMessage = ""; 

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _snack("Please enter email and password");
      return;
    }

    setState(() {
      isLoading = true;
      errorsMessage = "";
    });

    final uri = Uri.parse("https://backend-coral-eta-14.vercel.app/api/login");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["ok"] == true) {
        final int userId = data["user"]["id"];
        final String role = (data["user"]["role"] ?? "user").toString();

        _snack("Login successful ", success: true);
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;

        if (role == "admin") {
          Navigator.push(context, MaterialPageRoute(builder: (_)=>AdminDashboard()));
        } else if (role == "driver") {
          Navigator.push(context, MaterialPageRoute(builder: (_)=>DriverPage(driverId:userId)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_)=>Homepage(userId:userId)));
        }
      } else {
        final msg = data["msg"] ?? data["message"] ?? "Email or password is incorrect";
        setState(() => errorsMessage = msg.toString());
        _snack("Invalid Email or Password");
      }
    } catch (e) {
      setState(() => errorsMessage = "Server error. Please try again later.");
      _snack("Server error. Please try again later.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow.shade700, Colors.yellow.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.local_taxi, size: 80, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  "UniTaxi Login",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email),
                          hintText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          hintText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),

                       
                      if (errorsMessage.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorsMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],

                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: isLoading ? null : login,
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_)=>SignupPage()));
                        },
                        child: const Text("Don't have an account? Sign Up"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}