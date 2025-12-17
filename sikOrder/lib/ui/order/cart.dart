import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../charge/charge_list.dart';
import '../main/home_page.dart';
import '../order/order.dart';
import '../order/order_list.dart';
import '../auth/login_hq_access_page.dart';
import '../mypage/my_info.dart';
import '../mypage/inquiry_info.dart';
import '../../LogoutHandler.dart';
import '../../url.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  TextEditingController orderMessageController = TextEditingController();
  static final storage = FlutterSecureStorage();
  late final String _front_url;
  Map<String, dynamic> accountData = {};
  List<Map<String, dynamic>> cartItems = [];
  dynamic customerCode = '';
  dynamic hqCode = '';
  dynamic customerName = '';
  dynamic customerUserCode = '';
  bool _isLoading = false;
  String totalProducts = '0원';
  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    orderMessageController.dispose();
    super.dispose();
  }

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
    await getCartItems();

    setState(() {
      _isLoading = false;
    });
  }

  // 날짜 선택 함수
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF6272E0),
            colorScheme: ColorScheme.light(primary: Color(0xFF6272E0)),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
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
          "virtualAccountNum": "1111-111-111111",
          "bankName": "국민",
          "virtualAccountStatus": "사용",
          "balanceAmt": 123456000,
          "creditLimit": 0
        };
      }
    } catch (e) {
      print('계좌 데이터 조회 실패: $e');
    }
  }

  // 장바구니 목록 조회 API
  Future<void> getCartItems() async {
    try {
      var result = await http.get(Uri.parse(_front_url +
          '/api/v1/app/cart/list?customerCode=$customerCode&customerUserCode=$customerUserCode'));
      var resultData = jsonDecode(result.body);

      if (resultData['data'] != null) {
        cartItems = List<Map<String, dynamic>>.from(resultData['data']);
      } else {
        // 임시 데이터
        cartItems = [
          {
            'customerCartCode': 1,
            'itemName': '[아세웹] 토마토',
            'specification': '1kg/EA',
            'unit': 'EA',
            'quantity': 1,
            'unitPrice': 15000,
            'totalPrice': 15000,
            'customerPrice': 15000,
            'itemCode': 1,
            'warehouseCode': 1,
          },
          {
            'customerCartCode': 2,
            'itemName': '[아세웹] 토마토',
            'specification': '1kg/EA',
            'unit': 'EA',
            'quantity': 1,
            'unitPrice': 15000,
            'totalPrice': 15000,
            'customerPrice': 15000,
            'itemCode': 2,
            'warehouseCode': 1,
          }
        ];
      }

      // 총 금액 계산
      int total = cartItems.fold(
          0,
          (sum, item) =>
              sum + ((item['orderUnitPrice'] * item['orderQty'] ?? 0) as int));
      totalProducts = NumberFormat('#,###원').format(total);

      print('장바구니 데이터확인: ${cartItems.length}개');
    } catch (e) {
      print('장바구니 조회 실패: $e');
      cartItems = [];
    }
  }

  // 장바구니 아이템 삭제
  Future<void> removeCartItem(int customerCartCode) async {
    try {
      var result = await http.delete(
        Uri.parse(_front_url + '/api/v1/app/cart/$customerCartCode'),
      );

      var resultData = jsonDecode(result.body);
      if (resultData['code'] == 1) {
        setState(() {
          cartItems.removeWhere(
              (item) => item['customerCartCode'] == customerCartCode);
          // 총 금액 재계산
          int total = cartItems.fold(
              0,
              (sum, item) =>
                  sum +
                  ((item['orderUnitPrice'] * item['orderQty'] ?? 0) as int));
          totalProducts = NumberFormat('#,###원').format(total);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상품이 삭제되었습니다.')),
        );
      }
    } catch (e) {
      print('장바구니 삭제 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제에 실패했습니다.')),
      );
    }
  }

  // 삭제 확인 다이얼로그
  void _showDeleteDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            '삭제하시겠습니까?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            '선택한 상품을 장바구니에서 삭제합니다.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD0D0D0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    fixedSize: Size(100, 36),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    '아니요',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                    removeCartItem(item['customerCartCode']); // 삭제 실행
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6272E0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    fixedSize: Size(100, 36),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    '예',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // 장바구니 아이템 수량 업데이트
  Future<void> updateCartItemQuantity(
      int customerCartCode, int newQuantity) async {
    if (newQuantity <= 0) {
      removeCartItem(customerCartCode);
      return;
    }

    // API 호출 없이 로컬에서만 수량과 총액 업데이트
    setState(() {
      var item = cartItems
          .firstWhere((item) => item['customerCartCode'] == customerCartCode);
      item['orderQty'] = newQuantity;

      // 총 금액 재계산
      int total = cartItems.fold(
          0,
          (sum, item) =>
              sum +
              (((item['orderUnitPrice'] ?? 0) * newQuantity ?? 0) as int));
      totalProducts = NumberFormat('#,###원').format(total);
    });
  }

  // 주문 생성 함수
  Future<void> createOrder() async {
    try {
      // 1. 납기요청일 포맷팅 (YYYYMMDD)
      String deliveryRequestDt = selectedDate.year.toString() +
          selectedDate.month.toString().padLeft(2, '0') +
          selectedDate.day.toString().padLeft(2, '0');

      // 2. 주문 메시지 가져오기 (TextField에서)
      String orderMessage = orderMessageController.text ?? '';

      // 3. 전체 합계 계산
      int totalTaxableAmt = 0;
      int totalTaxFreeAmt = 0;
      int totalSupplyAmt = 0;
      int totalVatAmt = 0;
      int totalOrderAmt = 0;
      int totalOrderQty = 0;

      // 4. orderItems 배열 생성
      List<Map<String, dynamic>> orderItems = [];

      for (var item in cartItems) {
        int orderQty = int.tryParse(item['orderQty'].toString()) ?? 1;
        int itemTotalAmt = (item['orderUnitPrice'] ?? 0) * orderQty;
        int itemSupplyPrice = item['supplyPrice'] ?? 0;
        int itemTaxAmount = item['taxAmount'] ?? 0;

        // 개별 아이템 총액 계산 (수량 반영)
        int itemSupplyTotal = itemSupplyPrice * orderQty;
        int itemTaxTotal = itemTaxAmount * orderQty;

        totalTaxableAmt += itemTotalAmt;
        totalSupplyAmt += itemSupplyTotal;
        totalVatAmt += itemTaxTotal;
        totalTaxFreeAmt += itemTotalAmt;
        totalOrderAmt += itemTotalAmt;
        totalOrderQty += orderQty;

        // orderItems 배열에 추가
        orderItems.add({
          "itemCode": item['itemCode'],
          "warehouseCode": item['warehouseCode'],
          "itemName": item['itemName'],
          "specification": item['specification'],
          "unit": item['unit'],
          "priceType": item['priceType'],
          "orderUnitPrice": item['orderUnitPrice'],
          "currentStockQty": item['currentStockQty'],
          "orderQty": item['orderQty'],
          "taxTarget": item['taxTarget'],
          "taxableAmt": itemTotalAmt,
          "taxFreeAmt": itemTotalAmt,
          "supplyAmt": itemSupplyTotal,
          "vatAmt": itemTaxTotal,
          "totalAmt": itemTotalAmt,
          "totalQty": item['orderQty']
        });
      }

      // 5. 최종 요청 데이터 구성
      Map<String, dynamic> orderData = {
        "customerCode": customerCode,
        "customerUserCode": customerUserCode,
        "deliveryRequestDt": deliveryRequestDt,
        "orderMessage": orderMessage,
        "taxableAmt": totalTaxableAmt,
        "taxFreeAmt": totalTaxFreeAmt,
        "supplyAmt": totalSupplyAmt,
        "vatAmt": totalVatAmt,
        "totalAmt": totalOrderAmt,
        "totalQty": totalOrderQty,
        "orderItems": orderItems
      };

      // 6. 데이터 확인용 출력 (나중에 제거)
      print('=== 주문 데이터 확인 ===');
      print('납기요청일: $deliveryRequestDt');
      print('주문메시지: $orderMessage');
      print('과세금액: $totalTaxableAmt');
      print('면세금액: $totalTaxFreeAmt');
      print('공급가액: $totalSupplyAmt');
      print('부가세: $totalVatAmt');
      print('총주문금액: $totalOrderAmt');
      print('총수량: $totalOrderQty');
      print('주문아이템 수: ${orderItems.length}개');
      print('전체 데이터: ${jsonEncode(orderData)}');

      // 7. API 호출 (주석처리)
      var result = await http.post(
        Uri.parse(_front_url + '/api/v1/app/order/create'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(orderData),
      );

      var resultData = jsonDecode(result.body);
      if (resultData['code'] == 1) {
        // 주문 성공 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주문이 완료되었습니다.')),
        );
        // 장바구니 비우기 또는 주문내역으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderListPage(),
          ),
        );
      } else {
        // 주문 실패 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultData['message'])),
        );
      }
    } catch (e) {
      print('주문 생성 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주문 중 오류가 발생했습니다.')),
      );
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
          // 헤더 정보
          _buildHeader(),

          // 날짜 및 배송지 영역
          _buildDateAndLocation(),

          // 주문 메시지 영역
          _buildOrderMessage(),

          // 총 주문금액
          _buildTotalAmount(),

          // 상품 목록
          Expanded(
            child: _buildCartItemList(),
          ),

          // 주문하기 버튼
          _buildOrderButton(),
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
            '계좌번호 : ${accountData['bankName'] ?? ''} ${accountData['virtualAccountNum'] ?? ''}원',
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
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 날짜 및 배송지 영역
  Widget _buildDateAndLocation() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: Column(
        children: [
          // 첫 번째 행: 납기요청일
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  '납기요청일',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context),
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
                          '${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                        Icon(Icons.calendar_today,
                            color: Color(0xFF6272E0), size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // 두 번째 행: 배송지
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  '배송지',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 40,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(4),
                    color: Color(0xFFF9F9F9), // 수정 불가능한 느낌을 주는 배경색
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      customerName ?? '배송지 정보 없음',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 주문 메시지 영역
  Widget _buildOrderMessage() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주문 메시지',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 80,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              controller: orderMessageController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: '주문 메시지를 입력하세요.',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB0B0B0),
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 총 주문금액
  Widget _buildTotalAmount() {
    return Container(
      margin: EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '총 주문금액',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Text(
            totalProducts,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6272E0),
            ),
          ),
        ],
      ),
    );
  }

  // 상품 목록
  Widget _buildCartItemList() {
    return ListView.builder(
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        return _buildCartItem(cartItems[index]);
      },
    );
  }

  // 장바구니 아이템
  Widget _buildCartItem(Map<String, dynamic> item) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        children: [
          // 상품 정보와 삭제 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상품 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item['itemName'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          item['specification'] ??
                              '' + '/' + item['unit'] ??
                              '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${NumberFormat('#,###').format(item['orderUnitPrice'] ?? 0)}원',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // 삭제 버튼 (오른쪽 위)
              GestureDetector(
                onTap: () {
                  _showDeleteDialog(item);
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // 수량 조절 (오른쪽 정렬)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFE5E5E5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        int currentQty =
                            int.tryParse(item['orderQty'].toString()) ?? 1;
                        updateCartItemQuantity(
                            item['customerCartCode'], currentQty - 1);
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.remove,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Container(
                      width: 35,
                      height: 28,
                      alignment: Alignment.center,
                      child: Text(
                        (item['orderQty'] ?? 1).toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        int currentQty =
                            int.tryParse(item['orderQty'].toString()) ?? 1;
                        updateCartItemQuantity(
                            item['customerCartCode'], currentQty + 1);
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.add,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 주문하기 버튼
  Widget _buildOrderButton() {
    return Container(
      padding: EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            if (cartItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('장바구니가 비어있습니다.')),
              );
              return;
            }
            createOrder();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6272E0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            '주문하기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
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
