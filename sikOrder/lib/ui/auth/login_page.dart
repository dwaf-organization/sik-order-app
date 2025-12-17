import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main/home_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../url.dart';

class LoginPage extends StatefulWidget {
  final Map<String, dynamic> dataList;
  const LoginPage({super.key, required this.dataList});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController idController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  static final storage = FlutterSecureStorage();
  late final String _front_url;
  bool _isPasswordVisible = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    setState(() {
      _isLoading = false;
    });
    print(widget.dataList);
  }

  Future<void> _handleLogin() async {
    String id = idController.text.trim();
    String password = passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) return;

    try {
      // API 요청
      final response = await http.post(
        Uri.parse(_front_url + '/api/v1/app/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'customerUserId': id,
          'customerUserPw': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['code'] == 1) {
          // 로그인 성공
          final data = responseData['data'];
          // 사용자 정보 저장
          await storage.write(
              key: 'customerUserCode',
              value: data['customerUserCode'].toString());
          await storage.write(
              key: 'customerCode', value: data['customerCode'].toString());
          await storage.write(
              key: 'customerUserName', value: data['customerUserName']);
          await storage.write(
              key: 'virtualAccountCode',
              value: data['virtualAccountCode'].toString());

          // 홈페이지로 이동
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
            );
          }
        } else {
          // 로그인 실패
          _showErrorDialog(responseData['message'] ?? '로그인에 실패했습니다.');
        }
      } else {
        _showErrorDialog('서버 연결에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      _showErrorDialog('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('로그인 실패'),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 148),
                    Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '회원 서비스 이용을 위해 로그인 해주세요.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF717171),
                      ),
                    ),
                    SizedBox(height: 80),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: idController,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: "아이디",
                              hintStyle: TextStyle(
                                color: Color(0xFFD0D0D0),
                                fontSize: 15,
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
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "아이디는 필수 입력 항목입니다.";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: passwordController,
                            obscureText: !_isPasswordVisible,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: "비밀번호",
                              hintStyle: TextStyle(
                                color: Color(0xFFD0D0D0),
                                fontSize: 15,
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
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "비밀번호는 필수 입력 항목입니다.";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),

                          // 도움말 텍스트 - 가운데 정렬 수정
                          Container(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: double.infinity,
                                  child: Text(
                                    '로그인에 문제가 있으시면 본사에 문의해주세요.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Container(
                                  width: double.infinity,
                                  child: Text(
                                    '본사 연락처 : ${widget.dataList['inquiryTelNum']}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Spacer(),

                    // 로그인 버튼
                    Padding(
                      padding: EdgeInsets.only(bottom: 30),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _handleLogin();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFD0D0D0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
