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

  test('administrator login succeeds with seeded credentials', () async {
    final auth = AuthService();

    final result = await auth.login('admin', 'admin123');

    expect(result.isSuccess, isTrue);
    expect(result.role, UserRole.admin);
  });

  test('administrator can create a student account that can sign in', () async {
    final auth = AuthService();
    await auth.login('admin', 'admin123');

    final created = await auth.createManagedAccount(
      username: 'newstudent',
      password: 'secret123',
      role: UserRole.student,
      displayName: 'New Student',
      email: 'newstudent@college.edu',
      department: 'CSE',
      studentId: '2026CS001',
    );

    expect(created.isSuccess, isTrue);
    expect(created.user?.role, UserRole.student);
    await auth.logout();
    final login = await auth.login('newstudent', 'secret123');
    expect(login.isSuccess, isTrue);
    expect(login.role, UserRole.student);
  });

  test('administrator can create a staff account that can sign in', () async {
    final auth = AuthService();
    await auth.login('admin', 'admin123');

    final created = await auth.createManagedAccount(
      username: 'newstaff',
      password: 'secret123',
      role: UserRole.staff,
      displayName: 'New Staff',
      email: 'newstaff@college.edu',
      department: 'ECE',
      designation: 'Lecturer',
    );

    expect(created.isSuccess, isTrue);
    expect(created.user?.role, UserRole.staff);
    await auth.logout();
    final login = await auth.login('newstaff', 'secret123');
    expect(login.isSuccess, isTrue);
    expect(login.role, UserRole.staff);
  });

  test('non-administrator cannot create managed accounts', () async {
    final auth = AuthService();
    await auth.login('staff', 'staff123');

    final result = await auth.createManagedAccount(
      username: 'unauthorized',
      password: 'secret123',
      role: UserRole.student,
      displayName: 'Unauthorized',
      email: 'unauthorized@college.edu',
      department: 'CSE',
      studentId: '2026CS002',
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, contains('administrators'));
  });

  test('administrator cannot reuse a username or email', () async {
    final auth = AuthService();
    await auth.login('admin', 'admin123');

    final result = await auth.createManagedAccount(
      username: 'student',
      password: 'secret123',
      role: UserRole.student,
      displayName: 'Duplicate Account',
      email: 'different@college.edu',
      department: 'CSE',
      studentId: '2026CS003',
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, contains('already in use'));
  });

  test('invalid credentials fail with an error message', () async {
    final auth = AuthService();

    final result = await auth.login('unknown', 'wrong');

    expect(result.isSuccess, isFalse);
    expect(result.message, isNotEmpty);
  });
}
