import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LogoutHandler {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> logout() async {
    try {
      // 특정 키 'login' 삭제
      await _storage.delete(key: 'hqCode');
      await _storage.delete(key: 'customerUserCode');
      await _storage.delete(key: 'customerCode');
      await _storage.delete(key: 'customerName');
      await _storage.delete(key: 'customerUserName');
      await _storage.delete(key: 'virtualAccountCode');

      // 로그아웃 후 필요한 추가 작업 수행
      print('로그아웃 완료: login 키 삭제됨');
    } catch (e) {
      print('로그아웃 중 에러 발생: $e');
    }
  }
}
