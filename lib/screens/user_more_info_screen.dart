import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as httpdart;
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';

import '../config/AppConfig.dart';
import '../util/storage.dart';

class UserAttendanceInfoScreen extends StatefulWidget {
  final int userId;

  const UserAttendanceInfoScreen({super.key, required this.userId});

  @override
  UserAttendanceInfoScreenState createState() => UserAttendanceInfoScreenState();
}


class UserAttendanceInfoScreenState extends State<UserAttendanceInfoScreen> {

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
    _loadUserId();
    _loadRole();
  }
  Future<void> _loadRole() async {
    final storage = AppStorage();
    String? storedRole = await storage.read(key: "role");
    setState(() {
      role = storedRole;
    });
  }

  final storage = AppStorage();

  int workDaysCount = 0;
  String totalWorkTime = "0:00";
  String hourWorkTime = "0";

  DateTime focusedDay = DateTime.now();
  DateTime firstDay = DateTime.utc(2025, 1, 1);
  DateTime lastDay = DateTime.utc(2025, 12, 31);

  int selectedMonth = DateTime.now().month; // 選択された月
  int selectedYear = DateTime.now().year;
  String? userId;

  //ユーザー情報を呼び出す
  Future<void> _loadUserId() async {

    if (widget.userId == 0) {
      final id = await storage.read(key: "userId");
      if (id != null) {
        setState(() {
          userId = id;
        });
        fetchAttendanceData(selectedYear, selectedMonth, id);
      }
    } else {
      final id = widget.userId.toString();
      setState(() {
        userId = id;
      });
      fetchAttendanceData(selectedYear, selectedMonth, id);
    }
  }

  //勤怠状況を呼び出す
  Future<void> fetchAttendanceData(int year, int month, String userId) async {
    final uri = Uri.parse(
        "${AppConfig.apiBaseUrl}/api/user/searchRecord/$userId?year=$year&month=$month");

    final response = await httpdart.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        workDaysCount = data['workDaysCount'];
        hourWorkTime = data['totalHours'].toString();
        focusedDay = DateTime(year, month, 1);
      });
    } else {
      // エラー処理
      setState(() {
        workDaysCount = 0;
        hourWorkTime = "0";
        focusedDay = DateTime(year, month, 1);
      });
    }
  }

  //欠勤日計算
  int calculateAbsentDays(int year, int month, int workDaysCount) {
    final today = DateTime.now();
    final lastDayOfMonth = (month == 12)
        ? DateTime(year + 1, 1, 1).subtract(const Duration(days: 1))
        : DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
    int totalWeekdays = 0;

    for (int d = 1; d <= lastDayOfMonth.day; d++) {
      final day = DateTime(year, month, d);
      if (day.isAfter(today)) continue;
      if (day.weekday != DateTime.saturday && day.weekday != DateTime.sunday) {
        totalWeekdays++;
      }
    }
    return totalWeekdays - workDaysCount; // 欠勤日数　
  }

  // 月を決めたときに呼び出すAPI
  void _onMonthChanged(int? newMonth) {
    if (newMonth == null) return;
    setState(() {
      selectedMonth = newMonth;
      focusedDay = DateTime(focusedDay.year, newMonth, 1); //
    });
    if (userId != null) {
      fetchAttendanceData(selectedYear, newMonth, userId!).then((_) {
        // 決めた欠勤日数を再計算
        setState(() {});
      });
    }
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
      body: SingleChildScrollView(
        child: userId == null
            ? const Center(child: CircularProgressIndicator()) //Loading
            :Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '勤怠詳細画面',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButtonFormField<int?>(
                value: selectedMonth,
                decoration: InputDecoration(
                  labelText: 'カレンダー',
                  labelStyle: TextStyle(fontSize: 15, color: Color(0xffcfcfcf)),
                ),
                onChanged: _onMonthChanged,
                items: List.generate(12, (index) {
                  final month = index + 1;
                  return DropdownMenuItem<int>(
                    value: month,
                    child: Text("${month}月"),
                  );
                }),
              ),
              const SizedBox(height: 10),
              //カレンダー
              TableCalendar(
                firstDay: firstDay,
                lastDay: lastDay,
                focusedDay: focusedDay,
                calendarFormat: CalendarFormat.month,
                headerVisible: false,
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                      color: Colors.orange, shape: BoxShape.circle),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (day.weekday == DateTime.sunday) { //日曜日＝赤色
                      return Center(
                          child: Text("${day.day}",
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)));
                    }
                    return null;
                  },
                ),
              ),
              Row(
                children: [
                  Text("・出勤 ${workDaysCount}日 (総: ${hourWorkTime}時間)",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  Text("・欠勤 ${calculateAbsentDays(selectedYear, selectedMonth, workDaysCount)}日",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                ],
              ),
            ],
          ),
        ),
      )
    );
  }
}