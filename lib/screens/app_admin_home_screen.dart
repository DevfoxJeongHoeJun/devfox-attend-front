import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../config/AppConfig.dart';
import '../util/storage.dart';

class AppAdminHomeScreen extends StatefulWidget {
  const AppAdminHomeScreen({Key? key}) : super(key: key);


  @override
  AppAdminHomeScreenState createState() => AppAdminHomeScreenState();
}

class AppAdminHomeScreenState extends State<AppAdminHomeScreen> {

  Future<void> UserListHttp() async {

    final storage = new AppStorage();
    final role = await storage.read(key: "role");

    // role에 따른 초기 화면 결정
    String initialRoute = '/login';
    if (role == "ROLE_USER" || role == "ROLE_MANAGER") {
      initialRoute = '/attend/record';
    } else if (role == "ROLE_ADMIN") {
      initialRoute = '/admin/home';
    } else if (role == "ROLE_SUPER") {
      initialRoute = '/app-admin/home';
    }
    if (role == "ROLE_SUPER") {
      goToUserList();
    } if (role == null || role != "ROLE_SUPER") {
      goToLogin();
    }
  }

  Future<void> groupListHttp() async {
    final url = Uri.parse("${AppConfig.apiBaseUrl}/api/user/session");

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {

      final storage = new AppStorage();
      final userId = await storage.read(key: "userId");
      final username = await storage.read(key: "username");
      final role = await storage.read(key: "role");
      final groupCode = await storage.read(key: "groupCode");

      goToGroupList();
    } else {
      goToLogin();
    }

  }


  void goToLogin() {
    context.go('/login');
  }


  void goToUserList() {
    context.go('/app-admin/user-list');
  }

  // Navigate to the Group List
  void goToGroupList() {
    context.go('/app-admin/group-list');
  }



  int selectedIndex = 0;
  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
      print('tapped');
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'アプリ管理者用　\nホーム',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 200),
              ElevatedButton(
                onPressed: UserListHttp,
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
                  'ユーザー一覧画面へ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: groupListHttp,
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
                  'グループ一覧画面へ',
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
