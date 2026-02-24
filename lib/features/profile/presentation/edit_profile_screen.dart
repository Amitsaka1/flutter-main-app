import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
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

    nameController =
        TextEditingController(text: widget.profile["name"] ?? "");
    usernameController =
        TextEditingController(text: widget.profile["username"] ?? "");
    ageController =
        TextEditingController(text: widget.profile["age"]?.toString() ?? "");

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
        if (mounted) context.pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter name" : null,
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                  validator: (v) =>
                      v == null || v.length < 3
                          ? "Min 3 characters"
                          : null,
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Age"),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter age";
                    final age = int.tryParse(v);
                    if (age == null || age < 18 || age > 100)
                      return "Invalid age";
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: gender.isEmpty ? null : gender,
                  decoration: const InputDecoration(labelText: "Gender"),
                  items: const [
                    DropdownMenuItem(value: "Male", child: Text("Male")),
                    DropdownMenuItem(value: "Female", child: Text("Female")),
                  ],
                  onChanged: (v) => gender = v ?? "",
                ),

                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: roleType.isEmpty ? null : roleType,
                  decoration: const InputDecoration(labelText: "Role"),
                  items: const [
                    DropdownMenuItem(value: "Top", child: Text("Top")),
                    DropdownMenuItem(value: "Bottom", child: Text("Bottom")),
                    DropdownMenuItem(value: "Versatile", child: Text("Versatile")),
                  ],
                  onChanged: (v) => roleType = v ?? "",
                ),

                const SizedBox(height: 15),

                SwitchListTile(
                  title: const Text("Have Place"),
                  value: havePlace,
                  onChanged: (v) => setState(() => havePlace = v),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _updateProfile,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text("Save Changes"),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
