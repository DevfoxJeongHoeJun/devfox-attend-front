import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../config/AppConfig.dart';
import '../util/storage.dart';



class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfoScreen> {

  TextEditingController groupNameController = TextEditingController();
  TextEditingController groupAddressController = TextEditingController();
  TextEditingController groupDomainController = TextEditingController();
  TextEditingController inviteEmailController = TextEditingController();
  FocusNode groupNameFocus = FocusNode();
  FocusNode groupAddressFocus = FocusNode();
  FocusNode groupDomainFocus = FocusNode();
  FocusNode inviteEmailFocus = FocusNode();

  // LocalStorageを利用するためのライブラリ
  final storage = AppStorage();

  // 初期状態
  @override
  void initState() {
    super.initState();
    _loadRole();

    inviteEmailController.text = '';

    // 初期ページを呼び出し
    _initialData();
  }

  // 初期値 API 呼び出し
  Future<void> _initialData() async {

  // LocalStorageからグループコードを取得
  final groupCode = await storage.read(key: "groupCode");

    // API 呼び出し
    final url = Uri.parse(
        "${AppConfig.apiBaseUrl}/api/group/info/${groupCode}"
    );

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;

      final body = decoded['body'] as Map<String, dynamic>;

      setState(() {
        groupNameController.text = body['groupName'] ?? '';
        groupAddressController.text = body['groupAddress'] ?? '';
        groupDomainController.text = body['groupDomain'] ?? '';
      });
    } else {
      throw Exception("API 呼び出し失敗: ${response.statusCode}");
    }
  }

  // バリデーションチェック
  Future<String?> _inviteMailValidationCheck() async {
    if (inviteEmailController.text.isEmpty) {
      inviteEmailFocus.requestFocus();
      return 'メールアドレスを入力してください。';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(inviteEmailController.text)) {
      inviteEmailFocus.requestFocus();
      return 'メールアドレスの形式が正しくありません。';
    }

    return null;
  }

  Future<String?> _groupUpdateValidationCheck() async {
    if (groupNameController.text.isEmpty) {
      inviteEmailFocus.requestFocus();
      return 'グループ名を入力してください。';
    }

    if (groupAddressController.text.isEmpty) {
      inviteEmailFocus.requestFocus();
      return '住所を入力してください。';
    }

    return null;
  }


  Future<bool> _sendInviteMail() async {

    // API 呼び出し
    try {
      // LocalStorageからグループコードを取得
      final groupCode = await storage.read(key: "groupCode");

      final url = Uri.parse(
          "${AppConfig.apiBaseUrl}/api/mail/invite"
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "toMail": inviteEmailController.text,
          "inviteUrl": "${AppConfig.apiBaseUrl}/#/user/create/${groupCode}",
          "groupName": groupNameController.text,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch(e) {
      return false;
    }
  }

  Future<bool> _groupUpdate() async {

    try {
      // LocalStorageからグループコードを取得
      final groupCode = await storage.read(key: "groupCode");

      // API 呼び出し
      final url = Uri.parse(
          "${AppConfig.apiBaseUrl}/api/group/update"
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "groupCode": groupCode,
          "groupName": groupNameController.text,
          "groupAddress": groupAddressController.text,
        }),
      );

      if (response.statusCode == 200) {
        context.push("/admin/home");
        return false;
      } else {
        return true;
      }
    } catch(e) {
      return true;
    }

  }


  // Controller 解除して、Memory漏水防止
  @override
  void dispose() {
    groupNameController.dispose();
    groupAddressController.dispose();
    groupDomainController.dispose();
    inviteEmailController.dispose();
    super.dispose();
  }


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
      appBar:  AppBar(
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
                  context.push('/admin/home');
                },
              ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 34),
                child: const  Center(
                  child: Text(
                    'グループ詳細画面',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.only(bottom: 4),
                child: const Text(
                  'グループ名',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              Container(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: groupNameController,
                  decoration: InputDecoration(
                    hintText: '編集したいグループ名を入力してください',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black54, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.only(bottom: 4),
                child: const Text(
                  '住所',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              Container(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: groupAddressController,
                  decoration: InputDecoration(
                    hintText: '編集したい住所を入力してください',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black54, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.only(bottom: 4),
                child: const Text(
                  'ドメイン',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              Container(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextFormField(
                  controller: groupDomainController,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black54, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.only(bottom: 4),
                child: const Text(
                  '招待メールアドレス',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              Container(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: inviteEmailController,
                        focusNode: inviteEmailFocus,
                        decoration: InputDecoration(
                          hintText: 'メールアドレスを入力してください',
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black54, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton(
                      onPressed: () async {
                        if(await _inviteMailValidationCheck() != null) {
                          Flushbar(
                            message: await _inviteMailValidationCheck(),
                            duration: Duration(seconds: 2),
                            flushbarPosition: FlushbarPosition.TOP,
                            backgroundColor: Colors.red,
                            margin: EdgeInsets.all(16),
                            borderRadius: BorderRadius.circular(8),
                            icon: Icon(Icons.warning, color: Colors.white),
                          ).show(context);
                          return;
                        } else {
                          if(await _sendInviteMail()) {
                            Flushbar(
                              message: "招待メールを送信しました。",
                              duration: Duration(seconds: 2),
                              flushbarPosition: FlushbarPosition.TOP,
                              backgroundColor: Colors.blue,
                              margin: EdgeInsets.all(16),
                              borderRadius: BorderRadius.circular(8),
                              icon: Icon(Icons.warning, color: Colors.white),
                            ).show(context);
                          } else {
                            Flushbar(
                              message: "送信に失敗しました。",
                              duration: Duration(seconds: 2),
                              flushbarPosition: FlushbarPosition.TOP,
                              backgroundColor: Colors.red,
                              margin: EdgeInsets.all(16),
                              borderRadius: BorderRadius.circular(8),
                              icon: Icon(Icons.warning, color: Colors.white),
                            ).show(context);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(80, 50),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('送信'),
                    ),
                  ],
                ),
              ),
              Container(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height:15),
                        ElevatedButton(
                          onPressed: () async {
                            if(await _groupUpdateValidationCheck() != null) {
                              Flushbar(
                                message: await _groupUpdateValidationCheck(),
                                duration: Duration(seconds: 2),
                                flushbarPosition: FlushbarPosition.TOP,
                                backgroundColor: Colors.red,
                                margin: EdgeInsets.all(16),
                                borderRadius: BorderRadius.circular(8),
                                icon: Icon(Icons.warning, color: Colors.white),
                              ).show(context);
                              return;
                            } else {
                              if (await _groupUpdate()) {
                                Flushbar(
                                  message: '編集に失敗しました。',
                                  duration: Duration(seconds: 2),
                                  flushbarPosition: FlushbarPosition.TOP,
                                  backgroundColor: Colors.red,
                                  margin: EdgeInsets.all(16),
                                  borderRadius: BorderRadius.circular(8),
                                  icon: Icon(Icons.warning, color: Colors.white),
                                ).show(context);
                                return;
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 20),
                          ),
                          child: const Text(
                            '編集',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                  )
              ),
            ],
          ),
        ),
      )
    );
  }
}