import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/auth/login_hq_access_page.dart';
import 'ui/main/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 앱 실행
  runApp(const OrderReturnApp());
}

class OrderReturnApp extends StatelessWidget {
  const OrderReturnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '주문반품 관리 앱',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // 기본 배경색 흰색
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, // 앱바 배경색 흰색
          elevation: 0,
        ),
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: NoGlowScrollBehavior(), // 스크롤 효과 제거
          child: child!,
        );
      },
      home: LoginHqAccessPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 스크롤 글로우 효과 제거 클래스
class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}