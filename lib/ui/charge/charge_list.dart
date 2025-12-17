import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../main/home_page.dart';
import '../order/order.dart';
import '../order/order_list.dart';
import '../order/cart.dart';
import '../auth/login_hq_access_page.dart';
import '../mypage/my_info.dart';
import '../mypage/inquiry_info.dart';
import '../../LogoutHandler.dart';
import '../../url.dart';

class ChargeListPage extends StatefulWidget {
  const ChargeListPage({super.key});

  @override
  State<ChargeListPage> createState() => _ChargeListPageState();
}

class _ChargeListPageState extends State<ChargeListPage> {
  static final storage = FlutterSecureStorage();
  late final String _front_url;
  Map<String, dynamic> accountData = {};
  Map<String, dynamic> chargeSummary = {};
  List<Map<String, dynamic>> transactions = [];
  dynamic customerCode = '';
  dynamic hqCode = '';
  dynamic customerName = '';
  dynamic customerUserCode = '';
  bool _isLoading = false;
  DateTime startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
    });

    await _storageUser();
    await getAccountData();
    await getChargeHistory();

    setState(() {
      _isLoading = false;
    });
  }

  _storageUser() async {
    hqCode = await storage.read(key: 'hqCode');
    customerName = await storage.read(key: 'customerName');
    customerCode = await storage.read(key: 'customerCode');
    customerUserCode = await storage.read(key: 'customerUserCode');
  }

  getAccountData() async {
    try {
      var result = await http.get(Uri.parse(_front_url +
          '/api/v1/app/order/account-info?customerCode=$customerCode'));
      var resultData = jsonDecode(result.body);

      if (resultData['data'] != null) {
        accountData = resultData['data'];
      } else {
        accountData = {
          "virtualAccountNum": "123-456-789012",
          "bankName": "국민은행",
          "virtualAccountStatus": "사용",
          "balanceAmt": 123000000,
          "creditLimit": 123456000
        };
      }
    } catch (e) {
      print('계좌 데이터 조회 실패: $e');
    }
  }

  // 충전내역 조회 API
  Future<void> getChargeHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });

      String startDt = startDate.year.toString() +
          startDate.month.toString().padLeft(2, '0') +
          startDate.day.toString().padLeft(2, '0');
      String endDt = endDate.year.toString() +
          endDate.month.toString().padLeft(2, '0') +
          endDate.day.toString().padLeft(2, '0');

      var result = await http.get(Uri.parse(_front_url +
          '/api/v1/app/charge/transaction-history?customerCode=$customerCode&startTransactionDate=$startDt&endTransactionDate=$endDt&page=0&size=10'));
      var resultData = jsonDecode(result.body);

      setState(() {
        if (resultData['data'] != null) {
          chargeSummary = resultData['data']['summary'] ?? {};
          transactions = List<Map<String, dynamic>>.from(
              resultData['data']['transactions'] ?? []);
        } else {
          // 임시 데이터
          chargeSummary = {
            "totalDeposit": 15000000,
            "totalOrder": 0,
            "totalAdjustment": 0,
            "totalReturn": 0,
            "totalCount": 13
          };
          transactions = [
            {
              "transactionDate": "2025.10.31",
              "transactionType": "입금",
              "amount": 350000000,
              "balance": 450000000,
              "description": "거래 후 잔액"
            },
            {
              "transactionDate": "2025.10.31",
              "transactionType": "입금",
              "amount": 350000000,
              "balance": 450000000,
              "description": "거래 후 잔액"
            }
          ];
        }
        _isLoading = false;
      });

      print('충전내역 조회 완료: ${transactions.length}개');
    } catch (e) {
      print('충전내역 조회 실패: $e');
      setState(() {
        transactions = [];
        chargeSummary = {
          "totalDeposit": 0,
          "totalOrder": 0,
          "totalAdjustment": 0,
          "totalReturn": 0,
          "totalCount": 0
        };
        _isLoading = false;
      });
    }
  }

  // 날짜 선택 함수
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF6272E0),
            colorScheme: ColorScheme.light(primary: Color(0xFF6272E0)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      await getChargeHistory(); // 날짜 변경 시 재조회
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && transactions.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildCategoryDrawer(),
      appBar: AppBar(
        leading: Container(
          padding: EdgeInsets.fromLTRB(16, 0, 0, 0),
          child: Builder(
            builder: (context) => IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: Icon(
                Icons.menu,
                size: 28,
                color: Colors.black,
              ),
            ),
          ),
        ),
        title: Text(
          customerName ?? '거래처명',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            padding: EdgeInsets.fromLTRB(0, 0, 16, 0),
            child: IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartPage(),
                  ),
                );
              },
              icon: Icon(
                Icons.shopping_cart_sharp,
                size: 28,
                color: Color(0xFF6272E0),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 헤더 정보
          _buildHeader(),

          // 날짜 선택 영역
          _buildDateSelection(),

          // 거래 요약 정보
          _buildChargeSummary(),

          // 거래 내역
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  // 카테고리 드로어 메뉴
  Widget _buildCategoryDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '메뉴',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.black),
                    ),
                  ],
                ),
              ),

              // 메뉴 항목들
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // 메인 섹션
                    _buildDrawerSection(
                      title: '홈',
                      icon: Icons.home_filled,
                      color: Color(0xFFFFFFFF),
                      backgroundColor: Color(0xFF8979E2),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(),
                          ),
                        );
                      },
                    ),
                    // 주문관리 섹션
                    _buildDrawerSection(
                      title: '주문관리',
                      icon: Icons.shopping_cart_outlined,
                      color: Color(0xFF6366F1),
                      backgroundColor: Color(0xFFEDE9FE),
                    ),
                    _buildDrawerItem(
                        title: '주문하기',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderPage(),
                            ),
                          );
                        }),
                    _buildDrawerItem(
                        title: '주문내역',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderListPage(),
                            ),
                          );
                        }),
                    _buildDrawerItem(
                        title: '장바구니',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CartPage(),
                            ),
                          );
                        }),
                    // 반품 추후에 주석 풀어서 만들어야함!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    // 반품관리 섹션
                    // _buildDrawerSection(
                    //   title: '반품관리',
                    //   icon: Icons.undo_outlined,
                    //   color: Color(0xFF6366F1),
                    //   backgroundColor: Color(0xFFEDE9FE),
                    // ),
                    // _buildDrawerItem(title: '반품하기', onTap: () {}),
                    // _buildDrawerItem(title: '반품내역', onTap: () {}),
                    // 반품 추후에 주석 풀어서 만들어야함!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

                    // 충전관리 섹션
                    _buildDrawerSection(
                      title: '충전관리',
                      icon: Icons.wallet_outlined,
                      color: Color(0xFF6366F1),
                      backgroundColor: Color(0xFFEDE9FE),
                    ),
                    _buildDrawerItem(
                        title: '충전관리',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChargeListPage(),
                            ),
                          );
                        }),

                    // 마이페이지 섹션
                    _buildDrawerSection(
                      title: '마이페이지',
                      icon: Icons.person_outline,
                      color: Color(0xFF6366F1),
                      backgroundColor: Color(0xFFEDE9FE),
                    ),
                    _buildDrawerItem(
                        title: '내 정보',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyInfoPage()),
                          );
                        }),
                    _buildDrawerItem(
                        title: '문의 정보',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => InquiryInfoPage()),
                          );
                        }),

                    SizedBox(height: 20),
                    _buildDrawerItem(
                      title: '로그아웃',
                      onTap: () {
                        _showLogOutDialog(context);
                      },
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

  Widget _buildDrawerSection({
    required String title,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF374151),
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      dense: true,
    );
  }

  // 헤더 정보
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Color(0xFF8979E2),
      padding: EdgeInsets.fromLTRB(24, 15, 24, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '계좌번호 : ${accountData['bankName'] ?? ''} ${accountData['virtualAccountNum'] ?? ''}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '여신한도 : ${NumberFormat('#,###,###').format(accountData['creditLimit'] ?? 0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '충전잔액 : ${NumberFormat('#,###,###').format(accountData['balanceAmt'] ?? 0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 날짜 선택 영역
  Widget _buildDateSelection() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDateRange(),
              child: Container(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFE5E5E5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')} ~ ${endDate.year}.${endDate.month.toString().padLeft(2, '0')}.${endDate.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            height: 40,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      getChargeHistory();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF718EBF),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 10),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      '조회하기',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // 거래 요약 정보
  Widget _buildChargeSummary() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '건수 ${chargeSummary['totalCount'] ?? 0}건',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // 헤더
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFECF3FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '합계',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                // 첫 번째 행
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 입금액
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                  color: Color(0xFFE5E5E5), width: 1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '입금액',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,###,###').format(chargeSummary['totalDeposit'] ?? 0)}원',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 주문배송
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '주문배송',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,###,###').format(chargeSummary['totalOrder'] ?? 0)}원',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 두 번째 행
                Row(
                  children: [
                    // 조정
                    Expanded(
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            right:
                                BorderSide(color: Color(0xFFE5E5E5), width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '조정금액',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,###,###').format(chargeSummary['totalAdjustment'] ?? 0)}원',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 반품공제
                    Expanded(
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '반품금액',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,###,###').format(chargeSummary['totalReturn'] ?? 0)}원',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 거래 내역
  Widget _buildTransactionList() {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Color(0xFFE5E5E5),
            ),
            SizedBox(height: 16),
            Text(
              '거래내역이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(transactions[index]);
      },
    );
  }

  // 거래 아이템
  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return Container(
      margin: EdgeInsets.only(bottom: 1),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '일자 ${transaction['transactionDate']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                '${NumberFormat('#,###,###').format(transaction['amount'] ?? 0)}원',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                transaction['transactionType'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                '거래후 잔액  ${NumberFormat('#,###,###').format(transaction['balanceAfter'] ?? 0)}원',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showLogOutDialog(BuildContext context) async {
  final storage = FlutterSecureStorage();
  final LogoutHandler logoutHandler = LogoutHandler();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
            child: Text(
          '로그아웃하시겠습니까?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        )),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await logoutHandler.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginHqAccessPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffD0D0D0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  fixedSize: Size(107, 25),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  '로그아웃',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff2A7FFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  fixedSize: Size(107, 25),
                  padding: EdgeInsets.zero,
                ),
                child: Text('취소', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      );
    },
  );
}
