import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../charge/charge_list.dart';
import '../order/order.dart';
import '../order/order_list.dart';
import '../order/cart.dart';
import '../main/home_page.dart';
import '../auth/login_hq_access_page.dart';
import '../mypage/inquiry_info.dart';
import '../../LogoutHandler.dart';

import '../../url.dart';

class MyInfoPage extends StatefulWidget {
  const MyInfoPage({super.key});

  @override
  State<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfoPage> {
  static final storage = FlutterSecureStorage();
  late final String _front_url;
  dynamic customerCode = '';
  dynamic customerUserCode = '';
  bool _isLoading = true;
  Map<String, dynamic> data = {};

  // 라벨 매핑
  Map<String, String> labelMapping = {
    'customerName': '상호명',
    'ownerName': '대표자',
    'bizNum': '사업자번호',
    'bizType': '업태',
    'bizSector': '업종',
    'accountInfo': '법인계좌',
    'mobileNum': '연락처',
    'zipCode': '우편번호',
    'addr': '주소',
    'email': '이메일',
    'telNum': '전화',
    'customerUserId': '아이디',
  };

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
    await getData();
    setState(() {
      _isLoading = false;
    });
  }

  getData() async {
    customerCode = await storage.read(key: 'customerCode');
    customerUserCode = await storage.read(key: 'customerUserCode');

    var result = await http.get(Uri.parse(_front_url +
        '/api/v1/app/mypage/info?customerCode=$customerCode&customerUserCode=$customerUserCode'));
    var resultData = jsonDecode(result.body);

    if (resultData['data'] != null) {
      data = resultData['data'];
    } else {
      // data가 null일 경우, 임의의 값 할당
      data = {
        "customerName": "브랜드1 서면점",
        "ownerName": "1서면대표",
        "bizNum": "123-45-67890",
        "bizType": "도소매업",
        "bizSector": "식품판매",
        "accountInfo": "국민은행 123-456-789012 1서면대표",
        "mobileNum": "010-1234-5678",
        "zipCode": "06292",
        "addr": "부산광역시 11-111",
        "email": "seomyeon1@gmail.com",
        "telNum": "02-1234-5678",
        "customerUserId": "hong123"
      };
      print('데이터가 null이어서 임의의 값으로 대체합니다.');
    }
    print('데이터확인');
    print(data);
  }

  // 나의 매장 정보 데이터 추출
  Map<String, String> get userInfo {
    return {
      labelMapping['customerName']!: data['customerName'] ?? '',
      labelMapping['ownerName']!: data['ownerName'] ?? '',
      labelMapping['bizNum']!: data['bizNum'] ?? '',
      labelMapping['bizType']!: data['bizType'] ?? '',
      labelMapping['bizSector']!: data['bizSector'] ?? '',
      labelMapping['accountInfo']!: data['accountInfo'] ?? '',
      labelMapping['mobileNum']!: data['mobileNum'] ?? '',
      labelMapping['zipCode']!: data['zipCode'] ?? '',
      labelMapping['addr']!: data['addr'] ?? '',
      labelMapping['email']!: data['email'] ?? '',
      labelMapping['telNum']!: data['telNum'] ?? '',
    };
  }

  // 계정정보 데이터 추출
  Map<String, String> get accountInfo {
    return {
      labelMapping['customerUserId']!: data['customerUserId'] ?? '',
    };
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
          '내 정보',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 15, 24, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 나의 매장 정보 섹션
              _buildSectionTitle('나의 매장 정보'),
              SizedBox(height: 12),
              _buildInfoCard(userInfo),

              SizedBox(height: 4),

              Column(
                children: [
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    child: FractionallySizedBox(
                      widthFactor: 1, // 80% 너비
                      child: Container(
                        height: 0.7,
                        color: Color(0xFFC4C4C4), // 회색
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                ],
              ),
              // 계정정보 섹션
              _buildSectionTitle('계정정보'),
              SizedBox(height: 4),
              _buildInfoCard(accountInfo),
              Column(
                children: [
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    child: FractionallySizedBox(
                      widthFactor: 1, // 80% 너비
                      child: Container(
                        height: 0.7,
                        color: Color(0xFFC4C4C4), // 회색
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                ],
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
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

  // 드로어 섹션 헤더
  Widget _buildDrawerSection({
    required String title,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    VoidCallback? onTap, // onTap 파라미터 추가
  }) {
    return GestureDetector(
      onTap: onTap, // 탭 기능 추가
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

  // 드로어 메뉴 아이템
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

  // 섹션 타이틀
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  // 정보 카드
  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      // padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: data.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: _buildInfoRow(entry.key, entry.value.toString()),
          );
        }).toList(),
      ),
    );
  }

  // 정보 행
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ),

        SizedBox(width: 20),

        // 값
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
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
                  // 스토리지 로그아웃
                  await logoutHandler.logout();
                  // 로그아웃 후 페이지 이동
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
                  print('선택됨');
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
