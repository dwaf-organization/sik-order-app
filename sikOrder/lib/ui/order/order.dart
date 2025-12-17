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
import '../order/cart.dart';
import '../auth/login_hq_access_page.dart';
import '../mypage/my_info.dart';
import '../mypage/inquiry_info.dart';
import '../../LogoutHandler.dart';
import '../../url.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  static final storage = FlutterSecureStorage();
  String selectedCategory = '전체';
  String selectedBrand = '전체';
  String searchText = '';
  TextEditingController searchController = TextEditingController();
  late final String _front_url;
  Map<String, dynamic> accountData = {};
  List<Map<String, dynamic>> itemCategoryData = [];
  List<Map<String, dynamic>> products = [];
  dynamic customerCode = '';
  dynamic hqCode = '';
  dynamic customerName = '';
  dynamic customerUserCode = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
    });

    await _storageUser();
    await getAccountData();
    await getItemCategoryData();
    await searchProducts();

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
        // data가 null일 경우, 임의의 값 할당
        accountData = {
          "virtualAccountNum": "1111-111-111111",
          "bankName": "국민",
          "virtualAccountStatus": "사용",
          "balanceAmt": 0,
          "creditLimit": 0
        };
        print('계좌 데이터가 null이어서 임의의 값으로 대체합니다.');
      }
      print('계좌 데이터확인: $accountData');
    } catch (e) {
      print('계좌 데이터 조회 실패: $e');
    }
  }

  getItemCategoryData() async {
    try {
      var result = await http.get(Uri.parse(
          _front_url + '/api/v1/erp/common/item-category-list?hqCode=$hqCode'));
      var resultData = jsonDecode(result.body);

      if (resultData['data'] != null) {
        itemCategoryData = List<Map<String, dynamic>>.from(resultData['data']);
      } else {
        // data가 null일 경우, 임의의 값 할당
        itemCategoryData = [
          {"value": 4, "label": "축산물-소고기"},
          {"value": 5, "label": "축산물-돼지고기"},
          {"value": 6, "label": "축산물-닭고기"},
          {"value": 7, "label": "농산물-채소류"},
          {"value": 8, "label": "농산물-과일류"},
          {"value": 9, "label": "농산물-곡물류"},
          {"value": 10, "label": "수산물-생선류"}
        ];
        print('카테고리 데이터가 null이어서 임의의 값으로 대체합니다.');
      }
      print('카테고리 데이터확인: $itemCategoryData');
    } catch (e) {
      print('카테고리 데이터 조회 실패: $e');
    }
  }

  // 상품 검색/조회 API
  Future<void> searchProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // API 파라미터 구성
      // 기본 API URL과 필수 파라미터
      String apiUrl = _front_url +
          '/api/v1/app/order/item-list?customerCode=$customerCode&customerUserCode=$customerUserCode';

      // itemType 파라미터 (전체 또는 위시리스트)
      apiUrl += '&itemType=$selectedCategory';

      // categoryCode 파라미터 (브랜드/카테고리)
      if (selectedBrand != '전체') {
        // itemCategoryData에서 선택된 카테고리의 value 찾기
        var categoryItem = itemCategoryData.firstWhere(
          (item) => item['label'] == selectedBrand,
          orElse: () => {'value': null},
        );
        if (categoryItem['value'] != null) {
          apiUrl += '&categoryCode=${categoryItem['value']}';
        }
      } else {
        // 전체일 경우 categoryCode는 빈 값
        apiUrl += '&categoryCode=전체';
      }

      // itemName 파라미터 (검색어)
      if (searchText.isNotEmpty) {
        apiUrl += '&itemName=$searchText';
      } else {
        // 검색어가 없을 경우 빈 값
        apiUrl += '&itemName=';
      }

      print('상품 조회 API 호출: $apiUrl');

      var result = await http.get(Uri.parse(apiUrl));
      var resultData = jsonDecode(result.body);

      if (resultData['data'] != null) {
        products = List<Map<String, dynamic>>.from(resultData['data']);
      } else {
        // 임시 데이터
        products = [
          {
            "itemCode": 1,
            "itemName": "소고기",
            "specification": "1KG",
            "unit": "EA",
            "vatType": "과세",
            "vatDetail": "VAT포함",
            "categoryCode": 4,
            "origin": "강원도",
            "priceType": 1,
            "customerPrice": 44000,
            "supplyPrice": 40000,
            "taxAmount": 4000,
            "taxableAmount": 40000,
            "dutyFreeAmount": 0,
            "totalAmt": 44000,
            "orderAvailableYn": 1,
            "minOrderQty": 1,
            "maxOrderQty": 100,
            "deadlineDay": 1,
            "deadlineTime": "18:00",
            "currentQuantity": -1,
            "warehouseCode": 1,
            "isWishlist": false
          }
        ];
        print('상품 데이터가 null이어서 임시 데이터로 대체합니다.');
      }
      print('상품 데이터확인: ${products.length}개');
    } catch (e) {
      print('상품 조회 실패: $e');
      // 에러 발생시 임시 데이터
      products = [
        {
          'name': '[아세웹] 토마토',
          'brand': 'Royal A',
          'price': 15000,
          'unit': 'EA',
          'quantity': 0,
          'isFavorite': true,
        },
      ];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 위시리스트 추가
  Future<void> addToWishlist(Map<String, dynamic> product) async {
    try {
      var body = {
        "customerCode": customerCode,
        "customerUserCode": customerUserCode,
        "itemCode": product['itemCode'],
        "currentStockQty": product['currentStockQty'] ?? 0,
        "warehouseCode": product['warehouseCode'] ?? 1
      };

      var result = await http.post(
        Uri.parse(_front_url + '/api/v1/app/wishlist/add'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      var resultData = jsonDecode(result.body);
      if (resultData['code'] == 1) {
        setState(() {
          product['isWishlist'] = true;
          product['customerWishlistCode'] =
              resultData['data']['customerWishlistCode'];
        });
        print('위시리스트 추가 성공');
      }
    } catch (e) {
      print('위시리스트 추가 실패: $e');
    }
  }

// 위시리스트 삭제
  Future<void> removeFromWishlist(Map<String, dynamic> product) async {
    try {
      var result = await http.delete(
        Uri.parse(_front_url +
            '/api/v1/app/wishlist/${product['customerWishlistCode']}'),
      );

      var resultData = jsonDecode(result.body);
      if (resultData['code'] == 1) {
        setState(() {
          product['isWishlist'] = false;
          product['customerWishlistCode'] = null;
        });
        print('위시리스트 삭제 성공');
      }
    } catch (e) {
      print('위시리스트 삭제 실패: $e');
    }
  }

  // 장바구니 추가
  Future<void> addToCart(Map<String, dynamic> product) async {
    try {
      int orderQty = product['minOrderQty'] ?? 1;

      if (orderQty <= 0) {
        // 수량이 0이면 알림 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수량을 선택해주세요.')),
        );
        return;
      }

      var body = {
        "customerUserCode": customerUserCode,
        "customerCode": customerCode,
        "itemCode": product['itemCode'],
        "warehouseCode": product['warehouseCode'] ?? 1,
        "orderQty": orderQty
      };

      print(body);
      var result = await http.post(
        Uri.parse(_front_url + '/api/v1/app/cart/add'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      var resultData = jsonDecode(result.body);
      if (resultData['code'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('장바구니에 추가되었습니다.')),
        );
        // 수량 초기화
        setState(() {
          product['quantity'] = 0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultData['message'])),
        );
      }
    } catch (e) {
      print('장바구니 추가 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('장바구니 추가 중 오류가 발생했습니다.')),
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

          // 필터 영역
          _buildFilterSection(),

          // 품목 수
          _buildProductCount(),

          // 상품 리스트
          Expanded(
            child: _buildProductList(),
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
            '충전잔액 : ${NumberFormat('#,###,###').format(accountData['balanceAmt'] ?? 0)}원',
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

  // 필터 섹션
  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 첫 번째 줄: 전체품목 드롭다운
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: selectedCategory,
                  items: ['전체', '위시리스트'],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                    searchProducts();
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // 두 번째 줄: 카테고리 드롭다운과 검색 필드
          Row(
            children: [
              // 카테고리 드롭다운 (itemCategoryData 사용)
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  value: selectedBrand,
                  items: ['전체'] +
                      itemCategoryData
                          .map<String>((item) => item['label'].toString())
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBrand = value!;
                    });
                    searchProducts(); // 필터 변경시 재조회
                  },
                ),
              ),

              SizedBox(width: 12),

              // 검색 필드 (돋보기 버튼에 GET 요청)
              Expanded(
                flex: 3,
                child: Container(
                  height: 40,
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '상품명을 검색하세요',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB0B0B0),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          searchProducts(); // 돋보기 클릭시 검색 실행
                        },
                        child: Icon(
                          Icons.search,
                          color: Color(0xFF6272E0),
                          size: 20,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Color(0xFF6272E0)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: TextStyle(fontSize: 12),
                    onSubmitted: (value) {
                      searchProducts(); // 엔터 키 입력시 검색 실행
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 드롭다운 위젯
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
          isExpanded: true,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 품목 수 표시
  Widget _buildProductCount() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '총 품목 수: ${products.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // 상품 리스트
  Widget _buildProductList() {
    return ListView.builder(
      // padding: EdgeInsets.symmetric(horizontal: 24),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductItem(products[index], index);
      },
    );
  }

  // 상품 아이템
  Widget _buildProductItem(Map<String, dynamic> product, int index) {
    return Container(
      // margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          // 상품 정보와 하트
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          product['itemName'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          product['specification'] + '/' + product['unit'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF909297),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '현재고량 ' +
                              product['currentQuantity'].toString() +
                              'EA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          product['priceType'].toString() == '1' ? '싯가' : '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${NumberFormat('#,###').format(product['totalAmt'])}원',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  if (product['isWishlist'] == true) {
                    removeFromWishlist(product);
                  } else {
                    addToWishlist(product);
                  }
                },
                icon: Icon(
                  (product['isWishlist'] ?? false)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: (product['isWishlist'] ?? false)
                      ? Colors.red
                      : Color(0xFFD0D0D0),
                  size: 24,
                ),
              ),
            ],
          ),

          SizedBox(height: 4),

          // 수량 조절과 장바구니 버튼
          Row(
            children: [
              // 수량 조절
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
                        setState(() {
                          if (product['minOrderQty'] > 0) {
                            product['minOrderQty']--;
                          }
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 32,
                      alignment: Alignment.center,
                      child: Text(
                        '${product['minOrderQty']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          product['minOrderQty']++;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Spacer(),

              // 장바구니 버튼
              Container(
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    addToCart(product);
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
                    '담기',
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
              SizedBox(height: 10),
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
