import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../charge/charge_list.dart';
import '../main/home_page.dart';
import '../order/order_detail.dart';
import '../order/order.dart';
import '../order/cart.dart';
import '../auth/login_hq_access_page.dart';
import '../mypage/my_info.dart';
import '../mypage/inquiry_info.dart';
import '../../LogoutHandler.dart';
import '../../url.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  static final storage = FlutterSecureStorage();
  late final String _front_url;
  Map<String, dynamic> accountData = {};
  Map<String, dynamic> orderSummary = {};
  List<Map<String, dynamic>> orders = [];
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
    await getOrderHistory();

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

  // 주문내역 조회 API
  Future<void> getOrderHistory() async {
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
          '/api/v1/app/order/history?customerCode=$customerCode&deliveryRequestStartDt=$startDt&deliveryRequestEndDt=$endDt&page=0&size=10'));
      var resultData = jsonDecode(result.body);

      setState(() {
        if (resultData['data'] != null) {
          orderSummary = resultData['data']['summary'] ?? {};
          orders = List<Map<String, dynamic>>.from(
              resultData['data']['orders'] ?? []);
        } else {
          // 임시 데이터
          orderSummary = {"totalCount": 4, "totalAmount": 494144000};
          orders = [
            {
              "orderNo": "202512160001",
              "orderDt": "2025-12-16",
              "deliveryRequestDt": "2025-12-17",
              "deliveryStatus": "배송요청",
              "totalAmt": 123536000
            },
            {
              "orderNo": "202512160002",
              "orderDt": "2025-12-16",
              "deliveryRequestDt": "2025-12-17",
              "deliveryStatus": "배송요청",
              "totalAmt": 123536000
            },
            {
              "orderNo": "202512160003",
              "orderDt": "2025-12-16",
              "deliveryRequestDt": "2025-12-17",
              "deliveryStatus": "배송요청",
              "totalAmt": 123536000
            },
            {
              "orderNo": "202512160004",
              "orderDt": "2025-12-16",
              "deliveryRequestDt": "2025-12-17",
              "deliveryStatus": "배송요청",
              "totalAmt": 123536000
            },
          ];
        }
        _isLoading = false;
      });

      print('주문내역 조회 완료: ${orders.length}개');
    } catch (e) {
      print('주문내역 조회 실패: $e');
      setState(() {
        orders = [];
        orderSummary = {"totalCount": 0, "totalAmount": 0};
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
      await getOrderHistory(); // 날짜 변경 시 재조회
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
          // 날짜 선택 영역
          _buildDateSelection(),

          // 주문 요약 정보
          _buildOrderSummary(),

          // 주문 목록
          Expanded(
            child: _buildOrderList(),
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

  // 날짜 선택 영역
  Widget _buildDateSelection() {
    return Container(
      padding: EdgeInsets.all(16),
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
              onPressed: () {
                getOrderHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6272E0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
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

  // 주문 요약 정보
  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
      decoration: BoxDecoration(
        color: Color(0xFFECF3FF),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '총 주문건수 ' + '${orderSummary['totalCount'] ?? 0}건',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '총 주문 금액',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                Text(
                  '${NumberFormat('#,###,###').format(orderSummary['totalAmount'] ?? 0)}원',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6272E0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 주문 목록
  Widget _buildOrderList() {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Color(0xFFE5E5E5),
            ),
            SizedBox(height: 16),
            Text(
              '주문내역이 없습니다',
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
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderItem(orders[index]);
      },
    );
  }

  // 주문 아이템
  Widget _buildOrderItem(Map<String, dynamic> order) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailPage(orderNo: order['orderNo']),
            ),
          );
        },
        child: Container(
          // margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFE5E5E5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order['orderNo'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['deliveryStatus']),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order['deliveryStatus'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '주문일자: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    order['orderDt'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '납기요청일: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    order['deliveryRequestDt'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${NumberFormat('#,###,###').format(order['totalAmt'] ?? 0)}원',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  // 배송 상태에 따른 색상 반환
  Color _getStatusColor(String? status) {
    switch (status) {
      case '배송요청':
        return Color(0xFF6272E0);
      case '배송중':
        return Color(0xFFF59E0B);
      case '배송완료':
        return Color(0xFF10B981);
      case '취소':
        return Color(0xFFEF4444);
      default:
        return Color(0xFF6B7280);
    }
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
