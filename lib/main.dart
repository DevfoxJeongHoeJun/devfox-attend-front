import 'package:attendance_client/screens/group_admin_home_screen.dart';
import 'package:attendance_client/screens/group_create_screen.dart';
import 'package:attendance_client/screens/group_info_screen.dart';
import 'package:attendance_client/screens/employee_attendance_list_screen.dart';
import 'package:attendance_client/screens/group_list_screen.dart';
import 'package:attendance_client/screens/user_create_screen.dart';
import 'package:attendance_client/util/storage.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/attendance_record_screen.dart';
import 'screens/user_more_info_screen.dart';
import 'screens/user_list_screen.dart';
import 'screens/user_detail_info_screen.dart';
import 'screens/app_admin_home_screen.dart';
import 'screens/group_detail_info_screen.dart';
import 'package:go_router/go_router.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = AppStorage();
  final role = await storage.read(key: "role");

  String initialLocation = '/login';
  if (role == "ROLE_USER" || role == "ROLE_MANAGER") {
    initialLocation = '/attend/record';
  } else if (role == "ROLE_ADMIN") {
    initialLocation = '/admin/home';
  } else if (role == "ROLE_SUPER") {
    initialLocation = '/app-admin/home';
  }

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(
        path: '/user/create/:groupCode',
        builder: (context, state) {
          final groupCode = state.pathParameters['groupCode']!;
          return UserCreateScreen(groupCode: groupCode);
        },
      ),

      GoRoute(path: '/admin/home', builder: (context, state) => const GroupAdminHomeScreen()),
      GoRoute(path: '/admin/create', builder: (context, state) => const GroupCreateScreen()),
      GoRoute(path: '/admin/info', builder: (context, state) => const GroupInfoScreen()),

      GoRoute(path: '/app-admin/user-list', builder: (context, state) => const UserListScreen()),
      GoRoute(
        path: '/app-admin/user-detail-info/:userId',
        builder: (context, state) {
          final userId = int.parse(state.pathParameters['userId']!);
          return UserDetailInfoScreen(userId: userId);
        },
      ),
      GoRoute(path: '/app-admin/home', builder: (context, state) => const AppAdminHomeScreen()),
      GoRoute(path: '/app-admin/group-list', builder: (context, state) => const GroupListScreen()),
      GoRoute(path: '/app-admin/group-detail-info', builder: (context, state) => const GroupDetailInfoScreen()),

      GoRoute(path: '/attend/record', builder: (context, state) => const AttendanceRecordScreen()),
      GoRoute(path: '/attend/list', builder: (context, state) => const EmployeeAttendanceListScreen()),
      GoRoute(path: '/attend/details', builder: (context, state) => const UserAttendanceInfoScreen(userId: 0)),
      GoRoute(
        path: '/attend/details/:userId',
        builder: (context, state) {
          final userId = int.parse(state.pathParameters['userId']!);
          return UserAttendanceInfoScreen(userId: userId);
        },
      ),
    ],
  );

  runApp(MyApp(router: router));
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: '勤怠管理アプリ',
    );
  }
}


