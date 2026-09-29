import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meet/src/backend/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('student login succeeds with saved student credentials', () async {
    final auth = AuthService();

    final result = await auth.login('student', 'student123');

    expect(result.isSuccess, isTrue);
    expect(result.role, UserRole.student);
  });

  test('staff login succeeds with saved staff credentials', () async {
    final auth = AuthService();

    final result = await auth.login('staff', 'staff123');

    expect(result.isSuccess, isTrue);
    expect(result.role, UserRole.staff);
  });

  test('invalid credentials fail with an error message', () async {
    final auth = AuthService();

    final result = await auth.login('unknown', 'wrong');

    expect(result.isSuccess, isFalse);
    expect(result.message, isNotEmpty);
  });
}
