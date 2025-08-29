import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../config/AppConfig.dart';
import '../util/storage.dart';


class UserCreateScreen extends StatefulWidget {
  final String groupCode;

  const UserCreateScreen({super.key, required this.groupCode});

  @override
  State<UserCreateScreen> createState() => _UserCreateState();
}


class _UserCreateState extends State<UserCreateScreen> {
  TextEditingController userNameController = TextEditingController();
  TextEditingController userEmailController = TextEditingController();
  TextEditingController userPasswordController = TextEditingController();
  TextEditingController userPasswordCheckController = TextEditingController();
  FocusNode userNameFocus = FocusNode();
  FocusNode userEmailFocus = FocusNode();
  FocusNode userPasswordFocus = FocusNode();
  FocusNode userPasswordCheckFocus = FocusNode();


  @override
  void initState() {
    super.initState();
    _loadRole();

    userNameController.text = '';
    userEmailController.text = '';
    userPasswordController.text = '';
    userPasswordCheckController.text = '';
  }

  // バリデーションチェック
  Future<String?> _validationCheck() async {
    if (userNameController.text.isEmpty) {
      userNameFocus.requestFocus();
      return 'ユーザー名を入力してください。';
    }
    if (userEmailController.text.isEmpty) {
      userEmailFocus.requestFocus();
      return 'メールアドレスを入力してください。';
    }
    if (userPasswordController.text.isEmpty) {
      userPasswordFocus.requestFocus();
      return 'パスワードを入力してください。';
    }
    if (userPasswordCheckController.text.isEmpty) {
      userPasswordCheckFocus.requestFocus();
      return 'パスワード再確認を入力してください。';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(userEmailController.text)) {
      userEmailFocus.requestFocus();
      return 'メールアドレスの形式が正しくありません。';
    }

    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,20}$');
    if (!passwordRegex.hasMatch(userPasswordController.text)) {
      userPasswordFocus.requestFocus();
      return 'パスワードは英字と数字を含む8～20文字で入力してください。';
    }
    if (userPasswordController.text != userPasswordCheckController.text) {
      userPasswordCheckFocus.requestFocus();
      return 'パスワードが一致しません。';
    }

    return null;
  }

  // Email重複チェック API チェック
  Future<bool> _existsByEmail() async {
    try {
      final url = Uri.parse(
        "${AppConfig.apiBaseUrl}/api/user/existsByEmail/${userEmailController.text}",
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final result = decoded['body'];
        return result;
      } else {
        return true;
      }
    } catch(e) {
      return true;
    }
  }

  // 登録 API 呼び出し
  Future<bool> _createUser() async {
    // API 呼び出し
    try {
      final url = Uri.parse(
          "${AppConfig.apiBaseUrl}/api/user/create"
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "groupCode": widget.groupCode,
          "name": userNameController.text,
          "email": userEmailController.text,
          "password": userPasswordController.text
        }),
      );

      if (response.statusCode == 200) {
        context.go('/login');
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
    userNameController.dispose();
    userEmailController.dispose();
    userPasswordController.dispose();
    userPasswordCheckController.dispose();
    userNameFocus.dispose();
    userEmailFocus.dispose();
    userPasswordFocus.dispose();
    userPasswordCheckFocus.dispose();
    super.dispose();
  }

  int selectedIndex = 0;
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
                  context.push('/admin/home');
                },
              ),
          ],
        ),
      ),
        resizeToAvoidBottomInset: false,

        //タイトル end--------------------------------

        //ボディ start--------------------------------
        body: SingleChildScrollView(
          child: Center(
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: Column( //テキストボックス パート
                  children: [
                    //グループ名start--------------------------------
                    userNameText(),
                    Container(
                      width: 800,
                      height: 45,
                      child: TextField(
                        decoration: InputDecoration(
                            hintText: "ユーザー名を入力してください",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.black)
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.black)
                            )
                        ),
                        controller: userNameController,
                        focusNode: userNameFocus,
                      ),
                    ),
                    //グループ名end--------------------------------

                    //メールアドレスstart--------------------------------
                    mailAddressText(),
                    Container(
                      width: 800,
                      height: 45,
                      child: TextField(
                        decoration: InputDecoration(
                            hintText: "メールアドレスを入力してください",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.black)
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.black)
                            )
                        ),
                        controller: userEmailController,
                        focusNode: userEmailFocus,
                      ),
                    ),
                    //メールアドレスend--------------------------------

                    //パスワードstart--------------------------------
                    passwordText(),
                    Container(
                      width: 800,
                      height: 45,
                      child: TextField( //CompanyName
                        obscureText: true,
                        decoration: InputDecoration(
                            hintText: "パスワードを入力してください",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.black)
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.black)
                            )
                        ),
                        controller: userPasswordController,
                        focusNode: userPasswordFocus,
                      ),
                    ),
                    //パスワードend--------------------------------

                    //パスワード再確認start--------------------------------
                    passwordReconfirmText(),
                    Container(
                      width: 800,
                      height: 45,
                      child: TextField( //CompanyName
                        obscureText: true,
                        decoration: InputDecoration(
                            hintText: "パスワードを入力してください",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.black)
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.black)
                            )
                        ),
                        controller: userPasswordCheckController,
                        focusNode: userPasswordCheckFocus,
                      ),
                    ),
                    //パスワード確認end--------------------------------

                    //登録ボタンstart--------------------------------
                    Container(
                        width: 800,
                        height: 50,
                        margin: EdgeInsets.only(top: 30,bottom: 5),
                        child: ElevatedButton(
                          onPressed: () async {
                            if(await _validationCheck() != null) {
                              Flushbar(
                                message: await _validationCheck(),
                                duration: Duration(seconds: 2),
                                flushbarPosition: FlushbarPosition.TOP,
                                backgroundColor: Colors.red,
                                margin: EdgeInsets.all(16),
                                borderRadius: BorderRadius.circular(8),
                                icon: Icon(Icons.warning, color: Colors.white),
                              ).show(context);
                              return;
                            } else {
                              if(await _existsByEmail()) {
                                Flushbar(
                                  message: 'すでに使用されているメールアドレスです。',
                                  duration: Duration(seconds: 2),
                                  flushbarPosition: FlushbarPosition.TOP,
                                  backgroundColor: Colors.red,
                                  margin: EdgeInsets.all(16),
                                  borderRadius: BorderRadius.circular(8),
                                  icon: Icon(Icons.warning, color: Colors.white),
                                ).show(context);
                                return;
                              } else {
                                if(await _createUser()) {
                                  Flushbar(
                                    message: '登録処理に失敗しました。',
                                    duration: Duration(seconds: 2),
                                    flushbarPosition: FlushbarPosition.TOP,
                                    backgroundColor: Colors.red,
                                    margin: EdgeInsets.all(16),
                                    borderRadius: BorderRadius.circular(8),
                                    icon: Icon(Icons.warning, color: Colors.white),
                                  ).show(context);
                                }
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ), child: Text("登録",style: TextStyle(fontSize: 24.0),),
                        )
                    ),
                    //登録ボタンend--------------------------------
                  ].toList(),
                ),
              )
          ),
        ),//ボディ end--------------------------------
    );
  }
}

//グループ名テキスト
class userNameText extends StatelessWidget {
  const userNameText({super.key});

  @override
  Widget build(BuildContext context) {
    return  Container(
      width: 800,
      height: 35,
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(top: 20,bottom: 5),
      child: Text(
        "ユーザー名",//username
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ), textAlign: TextAlign.left,
      ),
    );
  }
}

//メールアドレステキスト
class mailAddressText extends StatelessWidget {
  const mailAddressText({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 35,
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(top: 20,bottom: 5),
      child:   Text(
        "メールアドレス",//mail address
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}

//パスワードテキスト
class passwordText extends StatelessWidget {
  const passwordText({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 35,
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(top: 20,bottom: 5),
      child:   Text(
        "パスワード",//password
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}

//パスワード再確認テキスト
class passwordReconfirmText extends StatelessWidget {
  const passwordReconfirmText({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 35,
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(top: 20,bottom: 5),
      child:   Text(
        "パスワード再確認",//password confirm
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}