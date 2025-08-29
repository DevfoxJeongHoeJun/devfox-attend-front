import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../util/storage.dart';

class GroupDetailInfoScreen extends StatefulWidget {
  const GroupDetailInfoScreen({super.key});

  @override
  State<GroupDetailInfoScreen> createState() => _GroupDetailInfoScreenState();
}

class _GroupDetailInfoScreenState extends State<GroupDetailInfoScreen> {
  int selectedIndex = 0;
  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }
  String? role;
  @override
  void initState() {
    super.initState();
    _loadRole();
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
      // 本体部分
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(50.0),

            child: Column(


              children: [
                const titleLable(),
                // ユーザー名
                const UserNameLabel(),
                const InputTextBox1(),

                // メールアドレス
                const EmailLabel(),
                const InputTextBox2(),

                // パスワード
                const PasswordLabel(),
                const InputTextBox3(),

                // 登録ボタンと削除ボタン
                const UpdateDeleteButtons(),
              ],
            ),
          ),
        ),
      )
    );
  }
}


class titleLable extends StatelessWidget {
  const titleLable({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      "グループ情報画面",
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ---------------------- ラベルウィジェット ----------------------

// ユーザー名ラベル
class UserNameLabel extends StatelessWidget {
  const UserNameLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildLabel("グループ名");
  }
}

// メールアドレスラベル
class EmailLabel extends StatelessWidget {
  const EmailLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildLabel("グループ住所");
  }
}

// パスワードラベル
class PasswordLabel extends StatelessWidget {
  const PasswordLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildLabel("ドメイン");
  }
}


// 共通ラベルウィジェット
Widget _buildLabel(String text) {
  return Container(
    width: 800,
    height: 35,
    alignment: Alignment.centerLeft,
    margin: const EdgeInsets.only(top: 20, bottom: 5),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// ---------------------- 入力欄ウィジェット ----------------------

class InputTextBox1 extends StatelessWidget {
  const InputTextBox1({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      height: 35,
      child: TextField(
        decoration: InputDecoration(
          hintText: "DEVFOX",
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class InputTextBox2 extends StatelessWidget {
  const InputTextBox2({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      height: 35,
      child: TextField(
        decoration: InputDecoration(
          hintText: "東京....",
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
      ),
    );
  }
}


class InputTextBox3 extends StatelessWidget {
  const InputTextBox3({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      height: 35,
      child: TextField(
        decoration: InputDecoration(
          hintText: "devfox.attend.co.jp",
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

// ---------------------- ボタン ----------------------

class UpdateDeleteButtons extends StatelessWidget {
  const UpdateDeleteButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        UpdateButton(),
        DeleteButton(),
      ],
    );
  }
}

class UpdateButton extends StatelessWidget {
  const UpdateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 35,
      margin: const EdgeInsets.only(top: 50, bottom: 5),
      child: ElevatedButton(
        onPressed: () {
          // 編集ボタンの処理
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: const Text("編集"),
      ),
    );
  }
}

class DeleteButton extends StatelessWidget {
  const DeleteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 35,
      child: ElevatedButton(
        onPressed: () {
          // 削除ボタンの処理
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: const Text("削除"),
      ),
    );
  }
}
