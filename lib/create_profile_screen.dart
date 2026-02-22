import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState
    extends State<CreateProfileScreen> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();
  final TextEditingController _ageController =
      TextEditingController();

  String? gender;
  String? roleType;
  bool havePlace = false;

  bool loading = false;
  String message = "";

  Future<void> _submit() async {

    final token = await ApiClient.getToken();
    if (token == null) {
      if (mounted) context.go("/login");
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      message = "";
    });

    try {

      final response =
          await ApiClient.post("/profile/create", {
        "name": _nameController.text.trim(),
        "gender": gender,
        "roleType": roleType,
        "havePlace": havePlace,
        "age": int.parse(_ageController.text.trim()),
      });

      if (response["success"] == true) {
        if (mounted) context.go("/dashboard");
      } else {
        setState(() {
          message =
              response["message"] ??
                  "Profile creation failed";
        });
      }

    } catch (e) {
      setState(() {
        message = "Server error";
      });
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF141E30),
              Color(0xFF243B55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(32),
              width: 350,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    const Text(
                      "Create Profile",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // NAME
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                          color: Colors.white),
                      decoration:
                          _inputDecoration("Name"),
                      validator: (value) =>
                          value == null ||
                                  value.isEmpty
                              ? "Name required"
                              : null,
                    ),

                    const SizedBox(height: 12),

                    // GENDER
                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration:
                          _inputDecoration("Select Gender"),
                      dropdownColor:
                          const Color(0xFF243B55),
                      items: const [
                        DropdownMenuItem(
                            value: "Male",
                            child: Text("Male")),
                        DropdownMenuItem(
                            value: "Female",
                            child: Text("Female")),
                      ],
                      onChanged: (val) =>
                          gender = val,
                      validator: (val) =>
                          val == null
                              ? "Select gender"
                              : null,
                    ),

                    const SizedBox(height: 12),

                    // ROLE TYPE
                    DropdownButtonFormField<String>(
                      value: roleType,
                      decoration:
                          _inputDecoration("Select Role"),
                      dropdownColor:
                          const Color(0xFF243B55),
                      items: const [
                        DropdownMenuItem(
                            value: "Top",
                            child: Text("Top")),
                        DropdownMenuItem(
                            value: "Bottom",
                            child: Text("Bottom")),
                        DropdownMenuItem(
                            value: "Normal",
                            child: Text("Normal")),
                        DropdownMenuItem(
                            value: "Lesbian",
                            child: Text("Lesbian")),
                      ],
                      onChanged: (val) =>
                          roleType = val,
                      validator: (val) =>
                          val == null
                              ? "Select role"
                              : null,
                    ),

                    const SizedBox(height: 12),

                    // AGE
                    TextFormField(
                      controller: _ageController,
                      keyboardType:
                          TextInputType.number,
                      style: const TextStyle(
                          color: Colors.white),
                      decoration:
                          _inputDecoration("Age"),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return "Age required";
                        }
                        final age =
                            int.tryParse(value);
                        if (age == null ||
                            age < 18) {
                          return "Invalid age";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // HAVE PLACE
                    Row(
                      children: [
                        Checkbox(
                          value: havePlace,
                          onChanged: (val) {
                            setState(() {
                              havePlace =
                                  val ?? false;
                            });
                          },
                        ),
                        const Text(
                          "Have Place",
                          style: TextStyle(
                              color: Colors.white),
                        )
                      ],
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed:
                          loading ? null : _submit,
                      style: ElevatedButton
                          .styleFrom(
                        minimumSize:
                            const Size.fromHeight(45),
                        backgroundColor:
                            const Color(
                                0xFF0072ff),
                      ),
                      child: Text(
                        loading
                            ? "Creating..."
                            : "Create Profile",
                      ),
                    ),

                    if (message.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                                top: 10),
                        child: Text(
                          message,
                          style: const TextStyle(
                              color: Colors.red),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String label) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(color: Colors.white70),
      filled: true,
      fillColor:
          Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}
