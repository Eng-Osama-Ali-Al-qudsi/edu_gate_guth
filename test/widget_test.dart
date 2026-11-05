import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_gate_guth/controllers/auth_controller.dart';
import 'package:edu_gate_guth/main.dart';
import 'package:edu_gate_guth/models/register_request.dart';
import 'package:edu_gate_guth/repositories/auth_repository_impl.dart';

void main() {
  late AuthController controller;
  late AuthRepositoryImpl repository;

  setUp(() {
    repository = AuthRepositoryImpl(requestDelay: Duration.zero);
    controller = AuthController(repository: repository);
  });

  testWidgets('shows Arabic RTL login page and validates empty fields', (tester) async {
    await tester.pumpWidget(EduGateApp(controller: controller));

    expect(find.text('بوابة الطالب'), findsOneWidget);
    expect(find.text('الرقم الأكاديمي أو البريد الإلكتروني'), findsOneWidget);
    expect(find.text('تذكر معرّف الحساب على هذا الجهاز'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.text('يرجى إدخال الرقم الأكاديمي أو البريد الإلكتروني.'), findsOneWidget);
    expect(find.text('يرجى إدخال كلمة المرور.'), findsOneWidget);
  });

  testWidgets('navigates from login to registration page', (tester) async {
    await tester.pumpWidget(EduGateApp(controller: controller));
    await tester.tap(find.text('إنشاء حساب جديد').last);
    await tester.pumpAndSettle();

    expect(find.text('الاسم الكامل'), findsOneWidget);
    expect(find.text('الرقم الأكاديمي'), findsOneWidget);
    expect(find.text('أوافق على الشروط والأحكام'), findsOneWidget);
  });

  testWidgets('rejects registration until academic terms are accepted', (tester) async {
    await tester.pumpWidget(EduGateApp(controller: controller));
    await tester.tap(find.text('إنشاء حساب جديد').last);
    await tester.pumpAndSettle();

    final submitButton = find.widgetWithText(ElevatedButton, 'إنشاء الحساب');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(
      find.text('يجب الموافقة على الشروط والأحكام للمتابعة.'),
      findsOneWidget,
    );
  });

  testWidgets('Remember Me checkbox updates controller state', (tester) async {
    await tester.pumpWidget(EduGateApp(controller: controller));
    expect(controller.rememberMe, isFalse);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(controller.rememberMe, isTrue);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(controller.rememberMe, isFalse);
  });

  testWidgets('registers through the registration screen and returns to login', (tester) async {
    await tester.pumpWidget(EduGateApp(controller: controller));
    await tester.tap(find.text('إنشاء حساب جديد').last);
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    final registrationValues = <String>[
      'Ali Mohammed',
      '202612345',
      'ali.student@example.edu',
      'Student123',
      'Student123',
    ];
    for (var index = 0; index < registrationValues.length; index++) {
      final field = fields.at(index);
      await tester.ensureVisible(field);
      await tester.enterText(field, registrationValues[index]);
    }

    final terms = find.byType(CheckboxListTile);
    await tester.ensureVisible(terms);
    await tester.tap(terms);
    await tester.pump();

    final submitButton = find.widgetWithText(ElevatedButton, 'إنشاء الحساب');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(repository.registeredStudentCount, 1);
    expect(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('completes password recovery, rejects old password, and accepts new password',
      (tester) async {
    await controller.register(
      request: const RegisterRequest(
        fullName: 'Ali Mohammed',
        academicId: '202612345',
        email: 'ali.student@example.edu',
        password: 'Student123',
      ),
    );
    await tester.pumpWidget(EduGateApp(controller: controller));

    await tester.tap(find.text('نسيت كلمة المرور؟'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '202612345');
    await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء رمز التحقق'));
    await tester.pumpAndSettle();

    expect(find.text('تعيين كلمة مرور جديدة'), findsOneWidget);
    expect(find.text('الحساب: 202612345'), findsOneWidget);

    final resetFields = find.byType(TextFormField);
    final resetValues = <String>['000000', 'Updated123', 'Updated123'];
    for (var index = 0; index < resetValues.length; index++) {
      final field = resetFields.at(index);
      await tester.ensureVisible(field);
      await tester.enterText(field, resetValues[index]);
    }
    final resetButton = find.widgetWithText(ElevatedButton, 'تحديث كلمة المرور');
    await tester.ensureVisible(resetButton);
    await tester.tap(resetButton);
    await tester.pumpAndSettle();
    expect(find.text('رمز التحقق غير صحيح.'), findsOneWidget);

    await tester.enterText(resetFields.at(0), '123456');
    await tester.tap(resetButton);
    await tester.pumpAndSettle();
    expect(find.text('تم تحديث كلمة المرور'), findsOneWidget);

    await tester.tap(find.text('العودة لتسجيل الدخول'));
    await tester.pumpAndSettle();
    expect(find.text('بوابة الطالب'), findsOneWidget);

    final loginFields = find.byType(TextFormField);
    await tester.ensureVisible(loginFields.at(0));
    await tester.enterText(loginFields.at(0), '202612345');
    await tester.ensureVisible(loginFields.at(1));
    await tester.enterText(loginFields.at(1), 'Student123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));
    await tester.pumpAndSettle();
    expect(
      find.text('بيانات الدخول غير صحيحة. تحقق من المعرّف وكلمة المرور.'),
      findsOneWidget,
    );

    await tester.enterText(loginFields.at(1), 'Updated123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));
    await tester.pumpAndSettle();
    expect(find.text('تم تسجيل الدخول'), findsOneWidget);
  });
}
