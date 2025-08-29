import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/AppConfig.dart';
import '../util/storage.dart';

class UserDetailInfoScreen extends StatefulWidget {
  final int userId;

  const UserDetailInfoScreen({super.key, required this.userId});

  @override
  State<UserDetailInfoScreen> createState() => _UserDetailInfoScreenState();
}

class _UserDetailInfoScreenState extends State<UserDetailInfoScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();

  String accessLevelCode = '';
  String groupCode = '';
  String createdAt = '';

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _loadRole();
  }

  Future<void> _fetchUserInfo() async {
    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/api/app/${widget.userId}"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        passwordController.clear();
        passwordConfirmController.clear();

        accessLevelCode = data['accessLevelCode'] ?? '';
        groupCode = data['groupCode'] ?? '';
        createdAt = data['createdAt'] ?? '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ユーザー取得エラー: ${response.statusCode}")),
      );
    }
  }

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
      if (isEditing) {
        passwordController.clear();
        passwordConfirmController.clear();
      }
    });
  }

  Future<void> _updateUser() async {
    if (passwordController.text != passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("パスワードが一致しません")),
      );
      return;
    }

    final updatedUser = {
      'id': widget.userId,
      'name': nameController.text,
      'email': emailController.text,
      'password': passwordController.text,
      'accessLevelCode': accessLevelCode,
      'groupCode': groupCode,
      'createdAt': DateTime.now().toIso8601String(),
      'createdUser':  widget.userId,
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedUser':  widget.userId,
    };

    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/api/app/update"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(updatedUser),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("更新完了")),
      );
      _toggleEdit();
      _fetchUserInfo();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("更新エラー: ${response.statusCode}")),
      );
    }
  }

  Future<void> _deleteUser() async {
    final response = await http.delete(
      Uri.parse("${AppConfig.apiBaseUrl}/api/app/delete/${widget.userId}"),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("削除完了")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("削除エラー: ${response.statusCode}")),
      );
    }
  }

  // ---------------------- UI ----------------------

  int selectedIndex = 0;
  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }
  String? role;

  Future<void> _loadRole() async {
    final storage = AppStorage();
    String? storedRole = await storage.read(key: "role");
    setState(() {
      role = storedRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
            title: Text('勤怠アプリ'),
            centerTitle: true,
            elevation: 0.0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                context.pop();
              },
            ),
            actions: [
              //Menu button start -----------------------------------------
              IconButton(onPressed: (){
                // print('menu button is clicked1');
                _scaffoldKey.currentState?.openEndDrawer();
              }, icon: Icon(Icons.menu)),
              //Menu button end ----------------------------------------
            ]
        ),
        //Drawer Start
        endDrawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text('歓迎致します!',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              if (role != null)
                ListTile(
                  title: const Text('ログアウト',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  selected: selectedIndex == 0,
                  onTap: () async {
                    final storage = AppStorage();
                    await storage.deleteAll();
                    context.go('/login');
                  },
                ),
              if (role == "ROLE_MANAGER")
                ListTile(
                  title: const Text(
                    'グループ管理者ホームへ',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  selected: selectedIndex == 0,
                  onTap: () async {
                    context.go('/admin/home');
                  },
                ),
            ],
          ),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ユーザー情報画面",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("ユーザー名"),
            TextField(controller: nameController, enabled: isEditing),
            const SizedBox(height: 10),
            const Text("メールアドレス"),
            TextField(controller: emailController, enabled: isEditing),
            const SizedBox(height: 10),
            const Text("パスワード"),
            TextField(
              controller: passwordController,
              enabled: isEditing,
              obscureText: true,
            ),
            const SizedBox(height: 10),
            const Text("パスワード再確認"),
            TextField(
              controller: passwordConfirmController,
              enabled: isEditing,
              obscureText: true,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                ElevatedButton(
                  onPressed: isEditing ? _updateUser : _toggleEdit,
                  child: Text(isEditing ? "保存" : "編集"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _deleteUser,
                  child: const Text("削除"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
