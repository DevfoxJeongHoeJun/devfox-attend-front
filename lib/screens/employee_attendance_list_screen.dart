import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../config/AppConfig.dart';
import '../util/storage.dart';

class EmployeeAttendanceListScreen extends StatefulWidget {
  const EmployeeAttendanceListScreen({super.key});

  @override
  State<EmployeeAttendanceListScreen> createState() => _EmpAttandState();
}

class _EmpAttandState extends State<EmployeeAttendanceListScreen> {

  // LocalStorageを利用するためのライブラリ
  final storage = AppStorage();

  // 検索・フィルターの入力コントローラー
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  // リストスクロールコントローラー
  ScrollController scrollController = ScrollController();

  // ステータス値：勤怠状態「0 = 全体」、「1 = 欠勤」
  String selectedStatus = '0';

  // 勤怠一覧リスト（ページングデータは append される）
  List<Map<String, dynamic>> employees = [];

  // ページング初期値
  int page = 0;   // 現在のページ番号
  int size = 10;  // 一つのページに出力するデータ数

  //　ローディング状態
  bool isLoading = false; // 重複ローディング防止「ture = すでにローディング中」
  bool hasMore = true;    // 次のページの存在可否（サーバー側の Pageable アノテーションで取得可能）



  // 初期状態
  @override
  void initState() {
    super.initState();
    _loadRole();
    // 初期日時を本日に設定
    final today = DateTime.now();
    startDateController.text = DateFormat('yyyy-MM-dd').format(today);
    endDateController.text = DateFormat('yyyy-MM-dd').format(today);

    // 初期検索キーワードなしに設定
    searchController.text = '';

    // スクロールリスナー登録
    scrollController.addListener(_onScroll);

    // 初期ページを呼び出し
    _handleSearch();
  }

  // スクロールイベント処理
  void _onScroll() {
    // すでにローディング中及び次のページがなければ処理終了
    if (isLoading || !hasMore) return;

    // 現在のスクロール位置が「最大スクロール長さ - 200」以上なら、次のページを呼び出し
    final current = scrollController.position.pixels;
    final max = scrollController.position.maxScrollExtent;

    if (current >= max - 200) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSearch();
      });
    }
  }

  // 勤怠一覧データ取得 API を呼び出し
  // 変数の isRefresh が true　の場合はページ ① から呼び出し（初期表示、検索した場合）
  // 変数の isRefresh が false の場合は次のページを呼び出し
  Future<void> _handleSearch({bool isRefresh = false}) async {

    // すてにローディング中なら処理終了
    if (isLoading) return;

    //　ローディング中の状態に変更
    setState(() {
      isLoading = true;
    });

    // れフレッシュすれば、ページとリストを初期化
    if (isRefresh) {
      page = 0;
      employees.clear();
      hasMore = true; // ページ ① からな（次のページないって意味）
      Future.delayed(Duration(milliseconds: 50), () {
        scrollController.jumpTo(0);
      });
    }

    // ログイン状態チェック（LocalStorageに情報がなければログイン画面に遷移）
    final groupCode = await storage.read(key: "groupCode");

    if (groupCode == null || groupCode.isEmpty) {
      context.go('/login');
      return;
    }

    // API 呼び出し
    final url = Uri.parse(
        "${AppConfig.apiBaseUrl}/api/group/attend-list?page=${page}&size=${size}"
    );

    try {

      // レスポンス
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "groupCode": groupCode,
          "startDate": startDateController.text,
          "endDate": endDateController.text,
          "status": selectedStatus,
          "userName": searchController.text
        }),
      );

      // レスポンスをパーシング
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> contentList  = decoded['body']['content'] ?? [];

        final pageInfo = decoded['body']['page'] ?? {};
        final int pageNumber = pageInfo['number'] ?? 0;
        final int totalPages = pageInfo['totalPages'] ?? 1;

        final bool lastPage = pageNumber >= totalPages - 1;

        final newItems = contentList.map((e) => Map<String, dynamic>.from(e)).toList();

        setState(() {
          employees.addAll(newItems);
          hasMore = !lastPage;
          if (!lastPage) page++;
          isLoading = false;
        });
      }
    } catch(e) {
      // 失敗時の処理
      setState(() {
        isLoading = false; // ローディング終了
      });
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

  // Controller 解除して、Memory漏水防止
  @override
  void dispose() {
    scrollController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // APIから取得した情報を出力（スクロールでページング可能）git gtgt
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
      body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const PageTitle(),
              const SizedBox(height: 16),
              const SearchText(),
              const SizedBox(height: 8),
              DateRangeInput(
                  startController: startDateController,
                  endController: endDateController
              ),
              const SizedBox(height: 8),
              StatusSelector(
                value: selectedStatus,
                onChanged: (val) => {
                  setState(() {
                    selectedStatus = val;
                  })
                },
              ),
              const SizedBox(height: 8),
              NameSearchInput(
                controller: searchController,
                onSearch: () {
                  page = 0;       // 検索時、ページ初期化
                  employees.clear();
                  hasMore = true;
                  _handleSearch(isRefresh: true);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  key: const PageStorageKey('employeeList'),
                  controller: scrollController,
                  itemCount: employees.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < employees.length) {
                      final emp = employees[index];
                      return EmployeeListItem(emp: emp);
                    } else {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                ),
              )
            ],
          ),
        ),
    );
  }
}

// 画面名
class PageTitle extends StatelessWidget {
  const PageTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'ユーザー勤怠一覧',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// キャレンダーラベル
class SearchText extends StatelessWidget {
  const SearchText({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text('勤怠日', style: TextStyle(fontSize: 16)),
    );
  }
}

// 検索日付Widget
class DateRangeInput extends StatefulWidget {
  final TextEditingController startController;
  final TextEditingController endController;

  const DateRangeInput({
    super.key,
    required this.startController,
    required this.endController,
  });

  @override
  State<DateRangeInput> createState() => _DateRangeInputState();
}

// 検索日付Widget
class _DateRangeInputState extends State<DateRangeInput> {

  Future<void> _selectDate(bool isStart) async {
    final initialDate = DateTime.tryParse(
      isStart ? widget.startController.text : widget.endController.text,
    ) ??
        DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      if (isStart) {
        widget.startController.text = formatted;
      } else {
        widget.endController.text = formatted;
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(true),
            child: AbsorbPointer(
              child: TextField(
                controller: widget.startController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text('〜'),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(false),
            child: AbsorbPointer(
              child: TextField(
                controller: widget.endController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ステータスセレクトボックス
class StatusSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const StatusSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Map<String, String> statusOptions = const {
    'すべて': '0',
    '欠勤': '1',
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: statusOptions.entries
          .map((entry) => DropdownMenuItem(
        value: entry.value,
        child: Text(entry.key),
      ))
          .toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// 検索テキストボックス
class NameSearchInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  const NameSearchInput({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'ユーザー氏名で検索',
              contentPadding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              border: OutlineInputBorder(),
              isDense: false,
            ),
          ),
        ),
        const SizedBox(width: 8),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('検索'),
          ),
        ),
      ],
    );
  }
}

// 勤怠一覧リストWidget
class EmployeeListItem extends StatelessWidget {
  final Map<String, dynamic> emp;

  const EmployeeListItem({Key? key, required this.emp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formatTime(String? time) {
      if (time == null) return '欠勤';
      try {
        final dt = DateTime.parse(time);
        return DateFormat('HH:mm').format(dt);
      } catch (e) {
        return time;
      }
    }

    final startTimeText = formatTime(emp['startTime'] as String?);
    final endTimeText = formatTime(emp['endTime'] as String?);
    final userId = emp['userId'] as int;

    String typeText(String? type) {
      switch (type) {
        case '1':
          return '出社';
        case '2':
          return '在宅';
        default:
          return '-';
      }
    }
    final type = typeText(emp['type']?.toString());

    return GestureDetector(
        onTap: () {
          context.push('/attend/details/$userId');
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp['userName'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('日付： ' + emp['date']),
                      Text('出勤時間： $startTimeText'),
                      Text('退勤時間： $endTimeText'),
                      Text('勤怠形態： $type'),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      (emp['type'] == null) ? '✕' : '〇',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: (emp['type'] == null) ? Colors.red : Colors.green,
                      ),
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
