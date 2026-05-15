import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

import 'widgets/profile_form_text_field.dart';
import 'widgets/profile_form_dropdown.dart';
import 'widgets/profile_form_switch.dart';
import 'widgets/profile_save_button.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController usernameController;
  late TextEditingController ageController;

  String gender = "";
  String roleType = "";
  bool havePlace = false;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.profile["name"] ?? "",
    );
    usernameController = TextEditingController(
      text: widget.profile["username"] ?? "",
    );
    ageController = TextEditingController(
      text: widget.profile["age"]?.toString() ?? "",
    );

    gender = widget.profile["gender"] ?? "";
    roleType = widget.profile["roleType"] ?? "";
    havePlace = widget.profile["havePlace"] ?? false;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final response = await ApiClient.put(
        "/profile/update",
        {
          "name": nameController.text.trim(),
          "username": usernameController.text.trim(),
          "age": int.parse(ageController.text.trim()),
          "gender": gender,
          "roleType": roleType,
          "havePlace": havePlace,
        },
      );

      if (response["success"] == true) {
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ProfileFormTextField(
                  controller: nameController,
                  label: "Name",
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter name" : null,
                ),
                const SizedBox(height: 15),

                ProfileFormTextField(
                  controller: usernameController,
                  label: "Username",
                  validator: (v) =>
                      v == null || v.length < 3
                          ? "Min 3 characters"
                          : null,
                ),
                const SizedBox(height: 15),

                ProfileFormTextField(
                  controller: ageController,
                  label: "Age",
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter age";
                    final age = int.tryParse(v);
                    if (age == null || age < 18 || age > 100) {
                      return "Invalid age";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                ProfileFormDropdown<String>(
                  value: gender.isEmpty ? null : gender,
                  label: "Gender",
                  items: const [
                    DropdownMenuItem(value: "Male", child: Text("Male")),
                    DropdownMenuItem(
                        value: "Female", child: Text("Female")),
                  ],
                  onChanged: (v) =>
                      setState(() => gender = v ?? ""),
                ),
                const SizedBox(height: 15),

                ProfileFormDropdown<String>(
                  value: roleType.isEmpty ? null : roleType,
                  label: "Role",
                  items: const [
                    DropdownMenuItem(value: "Top", child: Text("Top")),
                    DropdownMenuItem(
                        value: "Bottom", child: Text("Bottom")),
                    DropdownMenuItem(
                        value: "Versatile",
                        child: Text("Versatile")),
                  ],
                  onChanged: (v) =>
                      setState(() => roleType = v ?? ""),
                ),
                const SizedBox(height: 15),

                ProfileFormSwitchTile(
                  title: "Have Place",
                  value: havePlace,
                  onChanged: (v) => setState(() => havePlace = v),
                ),

                const SizedBox(height: 30),

                ProfileSaveButton(
                  loading: loading,
                  onPressed: _updateProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // ================= UI END =================
  }
}
