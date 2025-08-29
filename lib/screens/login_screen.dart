import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:attendance_client/util/storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../config/AppConfig.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {

  int selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final storage = AppStorage();
  bool isChecked = false;
  String? sessionCookie;

  Future<String?> loginUserHttp() async {
    // 「https://velog.io/@ramyuning/%EB%B0%B1%EC%97%94%EB%93%9C%EC%99%80-http-%ED%86%B5%EC%8B%A0%ED%95%98%EA%B8%B0」、
    // 「https://qiita.com/k-keita/items/5b748e081cf96c5ea38f」←は私が参考したリンクです。
    // FlutterでHTTPのRequestの方法です。
    final url = Uri.parse("${AppConfig.apiBaseUrl}/api/user/login");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "email": emailController.text,
        "password": passwordController.text
      }),
    );

    final userData = json.decode(response.body);
    if (userData['body'] == null) {
      return null;
    }

    if (userData['body']['accessLevelCode'] != null) {
      // 「https://juntcom.tistory.com/276」、←は私が参考したリンクです。
      // 「https://llshl.tistory.com/64」←は私が参考したリンクです。（JSONの配列でーたに接近する方法です。）
      // FlutterでresponseのjsonDataをparsingの方法です。

      final userData = json.decode(response.body);

      // 「https://jutole.tistory.com/63」、←は私が参考したリンクです。
      // Flutterのsecure storageの使い方です。
      await storage.write(key: "userId", value: userData['body']['id'].toString());
      await storage.write(key: "username", value: userData['body']['name']);
      await storage.write(key: "role", value: userData['body']['accessLevelCode']);
      await storage.write(key: "groupCode", value: userData['body']['groupCode']);

      // await storage.write(key: "userId", value: userData['id'].toString());
      // await storage.write(key: "username", value: userData['name']);
      // await storage.write(key: "role", value: userData['accessLevelCode']);
      // await storage.write(key: "groupCode", value: userData['groupCode']);

      final role = await storage.read(key: "role");

      return role;
    }
    return null;
  }

  void loginUser() {
    context.go('/attend/record');
  }

  void loginAdmin() {
    context.go('/admin/home');
  }

  void loginAppAdmin() {
    context.go('/app-admin/home');
  }

  void userCreate() {
    context.go('/admin/create');
  }

  void adminHome() {
    context.go('/admin/home');
  }

  Future<void> _logout(BuildContext context) async {
    final storage = AppStorage();
    await storage.deleteAll(); // SecureStorage 全削除
    // LoginScreen に戻る（履歴を全部削除して戻す）
    context.go('/login');
  }

  void _goToGroupAdmin(BuildContext context) {
    context.go('/admin/home');
  }

  String? role;
  @override
  void initState() {

    super.initState();
    _loadRole();
    AppStorage().deleteAll();
  }
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          // 縦に配置
          child: Column(
            // 真ん中に
            mainAxisAlignment: MainAxisAlignment.center,
            // 子ウィジェット配置
            children: [
              // Text配置
              const Text(
                'ログイン',
                // style適用
                style: TextStyle(
                  fontSize: 40,
                  // 文字を厚く
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 空間生成
              const SizedBox(height: 90),
              // 特定位置に整列
              Align(
                // 左に整列
                alignment: Alignment.centerLeft,
                // 左に整列
                child: const Text(
                  'メールアドレス',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: "メールを入力してください",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'パスワード',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                controller: passwordController,
                decoration: const InputDecoration(
                  hintText: "パスワードを入力してください",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(

                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      '自動でログインチェック',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Checkbox(
                      value: isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isChecked = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final result = await loginUserHttp();
                  if (result == null) {
                    Flushbar(
                      message: '                          ToastMessage\n                      認証に失敗しました。',
                      duration: Duration(seconds: 2),
                      flushbarPosition: FlushbarPosition.TOP,
                      backgroundColor: Colors.red,
                      margin: EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(8),
                      icon: Icon(Icons.warning, color: Colors.white),
                    ).show(context);
                    return;
                  } else {
                    if(result == "ROLE_USER" || result == "ROLE_MANAGER"){
                      context.go('/attend/record');
                    } else if (result == "ROLE_ADMIN") {
                      context.go('/admin/home');
                    } else if (result == "ROLE_SUPER") {
                      context.go('/app-admin/home');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text(
                  'ログイン',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: userCreate,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text(
                  '新規登録',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}
