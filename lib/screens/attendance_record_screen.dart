import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as httpdart;
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/AppConfig.dart';
import '../util/storage.dart';


class AttendanceRecordScreen extends StatefulWidget {
  const AttendanceRecordScreen({super.key});
  @override
  State<AttendanceRecordScreen> createState() => _AttendanceRecordScreenState();
}

class _AttendanceRecordScreenState extends State<AttendanceRecordScreen> {

  String? selectedWorkType; // Dropdown 選沢値を保存
  bool isWorking = false; //出勤可否
  bool hasEnded = false; //退勤可否
  final storage = AppStorage();
  String? lastWorkDate; //今日日付
  String? startTime;//出勤時間
  String? endTime; //退勤時間
  int? lastAttendId;
  // DBの数字→文字な変更
  Map<int, String> workTypeMap = {1: '出社', 2: '在宅'};
  Map<String, int> workTypeReverseMap = {'出社': 1, '在宅': 2};

  void _userMoreInfo() async {
    final userId = await storage.read(key: "userId");
    context.push('/attend/details/$userId');
  }

  //出勤処理-Async
  Future<httpdart.Response> postAttend(Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/api/user/addAttend');
    return await httpdart.post(url,
        headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
  }

  //退勤処理-Async
  Future<httpdart.Response> putAttend(int attendId, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/api/user/update/$attendId');
    return await httpdart.put(url,
        headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
  }

  //初期ステータス
  @override
  void initState() {
    super.initState();
    _loadAttendanceStatus();
    _loadRole();
  }

  //基本セッチング
  Future<void> _loadAttendanceStatus() async {
    final userIdStr = await storage.read(key: "userId");
    if (userIdStr == null) return;
    final userId = int.tryParse(userIdStr);
    if (userId == null) return;

    // attendance テーブルから今日の出退勤情報を呼び出す
    final url = Uri.parse('${AppConfig.apiBaseUrl}/api/user/searchAttend/$userId');
    try {
      final response = await httpdart.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final dbTypeRaw = data['type'];
        int? dbType;
        if (dbTypeRaw is int) {
          dbType = dbTypeRaw;
        } else if (dbTypeRaw is String) {
          dbType = int.tryParse(dbTypeRaw);
        }
        setState(() {
          selectedWorkType = workTypeMap[dbType] ?? null;
          startTime = data['startTime'];
          endTime = data['endTime'];
          lastAttendId = data['id'];

          if (startTime != null && endTime == null) {// 出勤状態
            isWorking = true;
            hasEnded = false;
          } else if (startTime != null && endTime != null) {// 退勤状態
            isWorking = false;
            hasEnded = true;
          } else {// 出勤前
            isWorking = false;
            hasEnded = false;
          }
        });
      } else if (response.statusCode == 404) {
        //データなし
        setState(() {
          startTime = null;
          endTime = null;
          isWorking = false;
          hasEnded = false;
          lastAttendId = null;
        });
      } else {
        print('Attendance情報取得失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('Attendance情報取得エラー: $e');
    }
  }

  //Login Logic後、呼び出すデータ
  Future<void> sendAttendance(String workType, bool isStart) async {
    final userId = await storage.read(key: "userId");
    if (userId == null) {
      return;
    }
    final now = DateTime.now(); //LocalDateTime専用パラメータ
    final todayDate = DateFormat('yyyy-MM-dd').format(now); // 日付
    final nowTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now); // 日付＋時間

    if (isStart) {
      // 出勤
      final body = {
        "userId": userId,
        "date": todayDate,
        "type": workTypeReverseMap[selectedWorkType], //1:出社、2:自宅
        "startTime": nowTime,
        "startLocation": "雑色",
        "createdUser": userId,
      };
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/attendance/add');
      final response = await httpdart.post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
      if (response.statusCode == 200) {
        await _loadAttendanceStatus(); //ステータス更新
      } else {
        print('出勤失敗: ${response.statusCode}');
      }
    } else {
      // 退勤
      if (lastAttendId == null) {
        print("退勤IDが存在しません");
        return;
      }

      final body = {
        "endTime": nowTime,
        "endLocation": "雑色",
        "updatedUser": userId,
      };
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/attendance/update/$lastAttendId');
      final response = await httpdart.put(url, headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
      if (response.statusCode == 200) {
        await _loadAttendanceStatus();
      } else {
        print('退勤失敗: ${response.statusCode}');
      }
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
    final String formattedDate = DateFormat('yyyy/MM/dd').format(DateTime.now());

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
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: const  Center(
                  child: Text(
                    '出退勤打刻',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Container(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Center(
                    child: Text(
                      '$formattedDate',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  )
              ),

            Container(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                children: [
                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: const Center(
                              child: Text(
                                '出勤時間',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          Center(
                              child: Text(
                                startTime != null? DateFormat('HH:mm').format(DateTime.parse(startTime!)) //時間だけ表示
                                    :'--:--',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              )
                          ),
                        ],
                      )
                  ),

                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: const Center(
                              child: Text(
                                '退勤時間',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          Center(
                              child: Text(
                                endTime != null? DateFormat('HH:mm').format(DateTime.parse(endTime!)) //時間だけ表示
                                    :'--:--',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              )
                          ),
                        ],
                      )
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              //トーストメッセージ-------------------------------------------------
              child: FutureBuilder<String?>(
                future: storage.read(key: "username"),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('エラーが発生しました');
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return Text('ユーザーIDが存在しません');
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text( // ログインユーザー名表示
                          '${snapshot.data}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        Text(// GPS 情報
                          'GPS情報（地域名）',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        // トーストメッセージEND--------------------------------------------------------------
                        // Dropdown BOX START--------------------------------------------------------------
                        DropdownButtonFormField<String?>(
                          value: selectedWorkType,
                          decoration: InputDecoration(
                            labelText: '業務形態',
                            labelStyle: TextStyle(fontSize: 15, color: Color(0xffcfcfcf)),
                          ),
                          hint: const Text('業務形態'),
                          onChanged: (isWorking||hasEnded) ? null : (String? newValue) {
                            setState(() {
                              selectedWorkType = newValue;
                            });
                          },
                          items: ['出社', '在宅'].map((i) {
                            return DropdownMenuItem<String?>(
                              value: i,
                              child: Text(i),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 15),

                        // 出勤退勤ボタン機能
                        hasEnded? SizedBox.shrink() //退勤まで終わったらボタン非表示
                        :ElevatedButton(
                          onPressed: () async {
                            if (selectedWorkType == null) {
                              Flushbar(
                                message: '出勤処理に失敗しました。',
                                duration: Duration(seconds: 2),
                                flushbarPosition: FlushbarPosition.TOP,
                                backgroundColor: Colors.red,
                                margin: EdgeInsets.all(16),
                                borderRadius: BorderRadius.circular(8),
                                icon: Icon(Icons.warning, color: Colors.white),
                              ).show(context);
                              return;
                            }

                            final userIdStr = await storage.read(key: "userId");
                            final userId = int.tryParse(userIdStr ?? "");
                            if (userId == null) {
                              print("ユーザーIDが無効です");
                              return;
                            }

                            final now = DateTime.now();
                            final today = DateFormat('yyyy-MM-dd').format(now);

                            if (!isWorking && !hasEnded) {
                              // 오늘 처음 출근
                              final body = {
                                "userId": userId,
                                "date": today,
                                "type": selectedWorkType,
                                "startTime": DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
                                "startLocation": "雑色",
                                "createdUser": userId,
                              };
                              final response = await postAttend(body);
                              if (response.statusCode == 200) {
                                final respBody = jsonDecode(response.body);
                                setState(() {
                                  lastAttendId = respBody["id"];
                                  startTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
                                  endTime = null;
                                  isWorking = true;
                                  hasEnded = false;
                                });
                                print("出勤成功: $selectedWorkType");
                              } else {
                                print("出勤失敗: ${response.statusCode}");
                              }
                            } else if (isWorking && !hasEnded) {
                              // 퇴근 처리
                              if (lastAttendId == null) {
                                print("退勤IDが存在しません");
                                return;
                              }
                              final body = {
                                "endTime": DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
                                "endLocation": "雑色",
                                "updatedUser": userId,
                              };
                              final response = await putAttend(lastAttendId!, body);
                              if (response.statusCode == 200) {
                                setState(() {
                                  endTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
                                  isWorking = false;
                                  hasEnded = true;
                                });
                                print("退勤成功: $selectedWorkType");
                              } else {
                                print("退勤失敗: ${response.statusCode}");
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: isWorking ? Colors.amber : Colors.indigo,
                            foregroundColor: isWorking ? Colors.black : Colors.white,
                            textStyle: const TextStyle(fontSize: 20),
                          ),
                          child: Text(
                            isWorking ? '退勤' : '出勤',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Dropdown BOX END--------------------------------------------------------------
                      ],
                    );
                  }
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              child: Column(
                  children:[
                    ElevatedButton(
                      onPressed: () {
                        _userMoreInfo();
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
                        '自分の勤怠詳細へ',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}