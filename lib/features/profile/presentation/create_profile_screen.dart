import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';

import 'widgets/create_profile_text_field.dart';
import 'widgets/create_profile_dropdown.dart';
import 'widgets/create_profile_checkbox.dart';
import 'widgets/create_profile_button.dart';

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
      if (mounted) {
        context.pushReplacement("/login");
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
      message = "";
    });

    try {

      final response =
          await ApiClient.post(
        "/profile/create",
        {
          "name": _nameController.text.trim(),
          "gender": gender,
          "roleType": roleType,
          "havePlace": havePlace,
          "age": int.parse(
            _ageController.text.trim(),
          ),
        },
      );

      if (response["success"] == true) {

        if (mounted) {
          context.pushReplacement("/dashboard");
        }

      } else {

        setState(() {
          message =
              response["message"] ??
              "Profile creation failed";
        });
      }

    } catch (_) {

      setState(() {
        message = "Server error";
      });
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

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
              width: 350,
              padding: const EdgeInsets.all(32),

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
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

                    CreateProfileTextField(
                      controller: _nameController,
                      label: "Name",
                      validator: (value) =>
                          value == null ||
                                  value.isEmpty
                              ? "Name required"
                              : null,
                    ),

                    const SizedBox(height: 12),

                    CreateProfileDropdown<String>(
                      value: gender,
                      label: "Select Gender",

                      items: const [
                        DropdownMenuItem(
                          value: "Male",
                          child: Text("Male"),
                        ),
                        DropdownMenuItem(
                          value: "Female",
                          child: Text("Female"),
                        ),
                      ],

                      onChanged: (val) {
                        gender = val;
                      },

                      validator: (val) =>
                          val == null
                              ? "Select gender"
                              : null,
                    ),

                    const SizedBox(height: 12),

                    CreateProfileDropdown<String>(
                      value: roleType,
                      label: "Select Role",

                      items: const [
                        DropdownMenuItem(
                          value: "Top",
                          child: Text("Top"),
                        ),
                        DropdownMenuItem(
                          value: "Bottom",
                          child: Text("Bottom"),
                        ),
                        DropdownMenuItem(
                          value: "Normal",
                          child: Text("Normal"),
                        ),
                        DropdownMenuItem(
                          value: "Lesbian",
                          child: Text("Lesbian"),
                        ),
                      ],

                      onChanged: (val) {
                        roleType = val;
                      },

                      validator: (val) =>
                          val == null
                              ? "Select role"
                              : null,
                    ),

                    const SizedBox(height: 12),

                    CreateProfileTextField(
                      controller: _ageController,
                      label: "Age",
                      keyboardType:
                          TextInputType.number,

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

                    CreateProfileCheckbox(
                      value: havePlace,
                      onChanged: (val) {
                        setState(() {
                          havePlace =
                              val ?? false;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: CreateProfileButton(
                        loading: loading,
                        onPressed: _submit,
                      ),
                    ),

                    if (message.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          top: 10,
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // ================= UI END =================
  }
}
