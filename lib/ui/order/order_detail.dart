import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../main/home_page.dart';
import '../charge/charge_list.dart';
import '../order/order.dart';
import '../order/order_list.dart';
import '../order/cart.dart';
import '../auth/login_hq_access_page.dart';
import '../mypage/my_info.dart';
import '../mypage/inquiry_info.dart';
import '../../LogoutHandler.dart';
import '../../url.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderNo;

  const OrderDetailPage({super.key, required this.orderNo});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  static final storage = FlutterSecureStorage();
  late final String _front_url;
  Map<String, dynamic> orderDetail = {};
  List<Map<String, dynamic>> orderItems = [];
  dynamic customerCode = '';
  dynamic customerName = '';
  bool _isLoading = false;
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    loadData();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
    });

    await _storageUser();
    await getOrderDetail();

    setState(() {
      _isLoading = false;
    });
  }

  _storageUser() async {
    customerName = await storage.read(key: 'customerName');
    customerCode = await storage.read(key: 'customerCode');
  }

  // 주문상세 조회 API
  Future<void> getOrderDetail() async {
    try {
      var result = await http.get(Uri.parse(_front_url +
          '/api/v1/app/order/detail?orderNo=${widget.orderNo}&customerCode=$customerCode'));
      var resultData = jsonDecode(result.body);

      setState(() {
        if (resultData['data'] != null) {
          orderDetail = resultData['data']['order'] ?? {};
          orderItems = List<Map<String, dynamic>>.from(
              resultData['data']['items'] ?? []);
          messageController.text = orderDetail['orderMessage'] ?? '';
        } else {
          // 임시 데이터
          orderDetail = {
            "orderNo": "202509080030",
            "orderDt": "2025.09.08",
            "deliveryRequestDt": "2025.09.09",
            "deliveryDt": "2025.09.09",
            "deliveryStatus": "배송완료",
            "orderMessage": "",
            "totalAmt": 150000,
            "totalItemCount": 6
          };
          orderItems = [
            {
              "itemCode": 1010013512,
              "itemName": "[아세웹] 토마토",
              "specification": "1kg/EA",
              "unit": "EA",
              "orderQty": 15,
              "priceType": "싯가",
              "orderUnitPrice": 15000,
              "totalAmt": 150000
            },
            {
              "itemCode": 1010013513,
              "itemName": "[아세웹] 토마토",
              "specification": "1kg/EA",
              "unit": "EA",
              "orderQty": 15,
              "priceType": "싯가",
              "orderUnitPrice": 15000,
              "totalAmt": 150000
            }
          ];
        }
      });

      print('주문상세 조회 완료: ${orderItems.length}개 아이템');
    } catch (e) {
      print('주문상세 조회 실패: $e');
      setState(() {
        orderDetail = {};
        orderItems = [];
      });
    }
  }

  // 수령확인 API
  Future<void> confirmDelivery() async {
    try {
      setState(() {
        _isLoading = true;
      });

      var body = {
        "orderNo": widget.orderNo,
        "customerCode": customerCode,
      };

      var result = await http.post(
        Uri.parse(_front_url + '/api/v1/app/order/confirm-delivery'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      var resultData = jsonDecode(result.body);

      setState(() {
        _isLoading = false;
      });

      if (resultData['code'] == 1) {
        setState(() {
          orderDetail['deliveryStatus'] = '배송완료';
          orderDetail['deliveryDt'] = resultData['data']['deliveryDt'] ??
              DateTime.now().toString().substring(0, 10);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수령확인이 완료되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수령확인에 실패했습니다.')),
        );
      }
    } catch (e) {
      print('수령확인 실패: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수령확인 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && orderDetail.isEmpty) {
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 주문 기본 정보
            _buildOrderInfo(),

            // 총 주문 금액
            _buildTotalAmount(),

            // 주문 메시지
            _buildOrderMessage(),

            // 수령확인 버튼
            _buildConfirmButton(),

            Column(
              children: [
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  child: FractionallySizedBox(
                    widthFactor: 1, // 80% 너비
                    child: Container(
                      height: 1.0,
                      color: Color(0xFFC4C4C4), // 회색
                    ),
                  ),
                ),
              ],
            ),

            // 주문 품목 리스트
            _buildOrderItemList(),
          ],
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

  // 주문 기본 정보
  Widget _buildOrderInfo() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
      color: Color(0xFFECF3FF),
      child: Column(
        children: [
          _buildInfoRow('주문번호', orderDetail['orderNo'] ?? ''),
          _buildInfoRow('주문일자', orderDetail['orderDt'] ?? ''),
          _buildInfoRow('납기요청일', orderDetail['deliveryRequestDt'] ?? ''),
          _buildInfoRow('배송일자', orderDetail['deliveryDt'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                if (label == '배송일자')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(orderDetail['deliveryStatus']),
                    ),
                    child: Text(
                      orderDetail['deliveryStatus'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 총 주문 금액
  Widget _buildTotalAmount() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Color(0xFFE5E5E5),
          width: 2.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '총 주문 금액',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          Text(
            '${NumberFormat('#,###,###').format(orderDetail['totalAmt'] ?? 0)}원',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6272E0),
            ),
          ),
        ],
      ),
    );
  }

  // 주문 메시지
  Widget _buildOrderMessage() {
    return Container(
      margin: EdgeInsets.fromLTRB(24, 10, 24, 10),
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
            height: 100,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(4),
              color: Color(0xFFF9F9F9),
            ),
            child: Text(
              orderDetail['orderMessage']?.isEmpty ?? true
                  ? '메시지가 없습니다.'
                  : orderDetail['orderMessage'],
              style: TextStyle(
                fontSize: 12,
                color: orderDetail['orderMessage']?.isEmpty ?? true
                    ? Color(0xFFB0B0B0)
                    : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 수령확인 버튼
  Widget _buildConfirmButton() {
    bool canConfirm = orderDetail['deliveryStatus'] != '배송완료';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: canConfirm && !_isLoading
                  ? () {
                      _showConfirmDialog();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canConfirm ? Color(0xFF6272E0) : Color(0xFFD0D0D0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      canConfirm ? '수령확인' : '수령확인 완료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          if (canConfirm)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '* 수령완료 버튼을 클릭하시면 취소가 불가능합니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 주문 품목 리스트
  Widget _buildOrderItemList() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              '주문 품목 ${orderItems.length}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          ...orderItems.map((item) => _buildOrderItem(item)).toList(),
        ],
      ),
    );
  }

  // 주문 품목 아이템
  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '품목코드: ${item['itemCode']}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 2),
          Row(
            children: [
              Text(
                item['itemName'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${item['specification'] ?? ''} / ${item['unit'] ?? ''}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Row(
            children: [
              Text(
                '주문수량: ${item['orderQty']}${item['unit']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              SizedBox(width: 10),
              Text(
                item['priceType'] == '납품단가' ? '' : '싯가',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${NumberFormat('#,###').format(item['orderUnitPrice'] ?? 0)}원',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Text(
                '합계  ${NumberFormat('#,###').format(item['totalAmt'] ?? 0)}원',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6272E0),
                ),
              ),
            ],
          ),
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
              SizedBox(height: 6),
            ],
          ),
        ],
      ),
    );
  }

  // 수령확인 다이얼로그
  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            '수령확인',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            '수령확인을 완료하시겠습니까?\n완료 후에는 취소할 수 없습니다.',
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
                    Navigator.of(context).pop();
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
                    '취소',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    confirmDelivery();
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
                    '확인',
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
