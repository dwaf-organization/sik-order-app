import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_page.dart';
import '../main/home_page.dart';

import '../../url.dart';

class LoginHqAccessPage extends StatefulWidget {
  const LoginHqAccessPage({super.key});

  @override
  State<LoginHqAccessPage> createState() => _LoginHqAccessPageState();
}

class _LoginHqAccessPageState extends State<LoginHqAccessPage> {
  TextEditingController hqAccessCodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  static final storage = FlutterSecureStorage();
  late final String _front_url;
  dynamic hqCode = '';
  dynamic customerUserCode = '';
  bool _isLoading = true;
  bool _isButtonActive = false;
  final Map<String, dynamic> dataList = {};

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    setState(() {
      _isLoading = true;
    });
    //스토리지에 본사 및 유저정보가 있으면 HOME으로 가기
    _storageUser();

    // 텍스트 입력 감지
    hqAccessCodeController.addListener(() {
      setState(() {
        _isButtonActive = hqAccessCodeController.text.trim().isNotEmpty;
      });
    });
  }

  _storageUser() async {
    setState(() {
      _isLoading = true;
    });
    hqCode = await storage.read(key: 'hqCode');
    customerUserCode = await storage.read(key: 'customerUserCode');
    print(hqCode);
    print(customerUserCode);
    if (hqCode != null && customerUserCode != null) {
      print("로그인 완료");
      // 로그인 성공
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      print("로그인이 필요합니다.");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleHqCodeAccess() async {
    String hqAccessCode = hqAccessCodeController.text.trim();
    if (hqAccessCode.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // API 요청
      final response = await http.post(
        Uri.parse(
            _front_url + '/api/v1/app/verify-hq?hq_access_code=$hqAccessCode'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['code'] == 1) {
          // 성공 응답 처리
          final data = responseData['data'];

          // hqCode를 세션에 저장
          await storage.write(key: 'hqCode', value: data['hqCode'].toString());

          dataList['hqCode'] = hqAccessCode;
          dataList['companyName'] = data['companyName'];
          dataList['inquiryTelNum'] = data['inquiryTelNum'];

          // 로그인 페이지로 이동하면서 회사명과 연락처 전달
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPage(dataList: dataList),
              ),
            );
          }
        } else {
          // 실패 응답 처리
          _showErrorDialog(responseData['message'] ?? '본사 코드 인증에 실패했습니다.');
        }
      } else {
        _showErrorDialog('서버 연결에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      _showErrorDialog('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('오류'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
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
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 29),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 148),

              // 타이틀
              Text(
                '접속하실 본사코드를 입력해주세요.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),

              SizedBox(height: 30),

              // 본사코드 입력 폼
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 본사코드 입력 필드
                    TextFormField(
                      controller: hqAccessCodeController,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: "본사코드를 입력해주세요.",
                        hintStyle: TextStyle(
                          color: Color(0xFFD0D0D0),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFFE5E5E5),
                            width: 1,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF6366F1),
                            width: 2,
                          ),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "본사코드는 필수 입력 항목입니다.";
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 40),

                    // 접속하기 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // 본사코드 검증 후 로그인 페이지로 이동
                            _handleHqCodeAccess();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD0D0D0), // 비활성화된 상태
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '인증하기',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    hqAccessCodeController.dispose();
    super.dispose();
  }
}
