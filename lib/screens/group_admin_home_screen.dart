import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../util/storage.dart';

class GroupAdminHomeScreen extends StatefulWidget {
  const GroupAdminHomeScreen({super.key});

  @override
  GroupAdminHomeScreenState createState() => GroupAdminHomeScreenState();
}


class GroupAdminHomeScreenState extends State<GroupAdminHomeScreen> {



  void goCompanyInfoScreen() {
    context.go('/admin/info');
  }

  void goEmployeeAttendanceListScreen() {
    context.go('/attend/list');
  }



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
      appBar:  AppBar(
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
                'グループ管理者用 \nホーム画面',
                // style適用
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  // 文字を厚く
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 空間生成

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: goEmployeeAttendanceListScreen,
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
                  '勤怠一覧画面へ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: goCompanyInfoScreen,
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
                  'グループ詳細画面へ',
                  style: TextStyle(
                    fontSize: 24,
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
