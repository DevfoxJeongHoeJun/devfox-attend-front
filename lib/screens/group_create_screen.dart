import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../config/AppConfig.dart';
import '../util/storage.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateState();
}

class _GroupCreateState extends State<GroupCreateScreen> {

  // テキストフィールドコントローラー及びフォーカス、スクロールを初期化
  TextEditingController groupNameController = TextEditingController();
  TextEditingController groupAddressController = TextEditingController();
  TextEditingController groupDomainController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController userEmailController = TextEditingController();
  TextEditingController userPasswordController = TextEditingController();
  TextEditingController userPasswordCheckController = TextEditingController();
  FocusNode groupNameFocus = FocusNode();
  FocusNode groupAddressFocus = FocusNode();
  FocusNode groupDomainFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode userEmailFocus = FocusNode();
  FocusNode userPasswordFocus = FocusNode();
  FocusNode userPasswordCheckFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // 初期状態
  @override
  void initState() {
    super.initState();
    groupNameController.text = '';
    groupAddressController.text = '';
    groupDomainController.text = '';
    userNameController.text = '';
    userEmailController.text = '';
    userPasswordController.text = '';
    userPasswordCheckController.text = '';
    _loadRole();
  }

  // Controller 解除して、Memory漏水防止
  @override
  void dispose() {
    groupNameController.dispose();
    groupAddressController.dispose();
    groupDomainController.dispose();
    userNameController.dispose();
    userEmailController.dispose();
    userPasswordController.dispose();
    userPasswordCheckController.dispose();
    groupNameFocus.dispose();
    groupAddressFocus.dispose();
    groupDomainFocus.dispose();
    userNameFocus.dispose();
    userEmailFocus.dispose();
    userPasswordFocus.dispose();
    userPasswordCheckFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // バリデーションチェック
  Future<String?> _validationCheck() async {
    if (groupNameController.text.isEmpty) {
      groupNameFocus.requestFocus();
      return 'グループ名を入力してください。';
    }
    if (groupAddressController.text.isEmpty) {
      groupAddressFocus.requestFocus();
      return '住所を入力してください。';
    }
    if (groupDomainController.text.isEmpty) {
      groupDomainFocus.requestFocus();
      return '住所を入力してください。';
    }
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
  Future<bool> _createGroup() async {
    // API 呼び出し
    try {
      final url = Uri.parse(
          "${AppConfig.apiBaseUrl}/api/group/create"
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "groupName": groupNameController.text,
          "address": groupAddressController.text,
          "domain": groupDomainController.text,
          "userName": userNameController.text,
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
        resizeToAvoidBottomInset: false,
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
        //タイトル end--------------------------------

        //ボディ start--------------------------------
        body: SingleChildScrollView(
          child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical:10 ,horizontal:30 ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column( //テキストボックス パート
                    children: [
                      //グループ名start--------------------------------
                      groupNameText(),
                      Container(
                        width: 800,
                        height: 40,
                        child: TextField( //CompanyName
                          decoration: InputDecoration(
                              hintText: "グループを入力してください",
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
                          controller: groupNameController,
                          focusNode: groupNameFocus,
                        ),
                      ),
                      //グループ名end--------------------------------

                      //グループ住所start--------------------------------
                      groupLocationText(),
                      Container(
                        width: 800,
                        height: 40,
                        child: TextField(
                          decoration: InputDecoration(
                              hintText: "住所を入力してください",
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
                          controller: groupAddressController,
                          focusNode: groupAddressFocus,
                        ),
                      ),
                      //グループ住所end--------------------------------

                      // //グループ管理コードstart--------------------------------
                      // companyCodeText(),
                      // textBox(),
                      // //グループ管理コードend--------------------------------

                      //ドメイン--------------------------
                      domainText(),
                      Container(
                        width: 800,
                        height: 40,
                        child: TextField( //CompanyName
                          decoration: InputDecoration(
                              hintText: "ドメインを入力してください",
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
                          controller: groupDomainController,
                          focusNode: groupDomainFocus,
                        ),
                      ),
                      //グループ管理コードend--------------------------------

                      //Divider start-----------------------------------
                      Container(
                        height: 30,
                        decoration:BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.black,
                                    width: 1
                                )
                            )
                        ),
                      ),
                      //Divider end----------------------------------

                      //Master infomation(管理者情報)
                      //ユーザー名start--------------------------------
                      groupMasterNameText(),
                      Container(
                        width: 800,
                        height: 40,
                        child: TextField( //CompanyName
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
                      //ユーザー名end--------------------------------

                      //メールアドレスstart--------------------------------
                      mailAddressText(),
                      Container(
                        width: 800,
                        height: 40,
                        child: TextField( //CompanyName
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
                        height: 40,
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

                      //パスワード確認start--------------------------------
                      passwordReconfirmText(),
                      Container(
                        width: 800,
                        height: 40,
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
                          margin: EdgeInsets.only(top:30 ,bottom: 50),
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
                                  if(await _createGroup()) {
                                    Flushbar(
                                      message: '登録処理に失敗しました。',
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
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                            ), child: Text("登録", style: TextStyle(fontSize: 24.0),),)
                      ),
                      //登録ボタンend--------------------------------
                    ].toList(),
                  ),
                ),
              )
          ),
        )
      //ボディ end--------------------------------
    );
    
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
//グループ名テキスト
class groupNameText extends StatelessWidget {
  const groupNameText({super.key});

  @override
  Widget build(BuildContext context) {
    return  Container(
        width: 800,
        height: 30,
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.only(top: 20,bottom: 5),
        child: Text(
        "グループ名",//group name
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ), textAlign: TextAlign.left,
      ),
    );
  }
}

//グループ住所テキスト
class groupLocationText extends StatelessWidget {
  const groupLocationText({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 30,
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(top: 20,bottom: 5),
      child:   Text(
        "住所",//"グループ住所",//group Location
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}

//ドメインテキスト
class domainText extends StatelessWidget {
  const domainText({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 30,
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(top: 20,bottom: 5),
      child:   Text(
        "ドメイン",//group domain
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}

class groupMasterNameText extends StatelessWidget {
  const groupMasterNameText({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 30,
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(top: 20,bottom: 5),
      child:   Text(
        "ユーザー名",//"グループ管理者名",//group master name
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
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
      height: 30,
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
      height: 30,
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

//パスワード確認テキスト
class passwordReconfirmText extends StatelessWidget {
  const passwordReconfirmText({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 30,
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(top: 20,bottom: 5),
      child:   Text(
        "パスワード再確認",//password reconfirm
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}

//一般テキストボックス
class textBox extends StatelessWidget {
  const textBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 800,
          height: 30,
          child: TextField( //CompanyName
          decoration: InputDecoration(
          hintText: "テキストボックス",
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
      ),
    );
  }
}

//パスワードテキストボックス
class passwordTextBox extends StatelessWidget {
  const passwordTextBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 30,
      child: TextField( //CompanyName
        obscureText: true,
        decoration: InputDecoration(
            hintText: "テキストボックス",
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
      ),
    );
  }
}

//登録ボタン
class registButton extends StatelessWidget {
  const registButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 50,
      margin: EdgeInsets.only(top:30 ,bottom: 50),
      child: ElevatedButton(onPressed: (){

      },
      style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
      ),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
      ), child: Text("登録"),)
    );
  }
}


class _MyHomePageState extends State<MyHomePage> {

  var results = "";
  final myController = TextEditingController(); //テキストボックスからデータを出す

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
              TextField(
                controller: myController,
                decoration: InputDecoration(
                  hintText: "Results"
                ),
              ),
            registButton(

            )
          ],
        ),
      ),
    );
  }
}

