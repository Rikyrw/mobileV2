import 'package:flutter_test/flutter_test.dart';
import 'package:mob_2/services/password_policy.dart';

void main() {
  test('password policy accepts strong passwords', () {
    expect(PasswordPolicy.validate('Green123!'), isNull);
    expect(PasswordPolicy.isStrong('BankSampah9#'), isTrue);
  });

  test('password policy rejects missing requirements', () {
    expect(PasswordPolicy.validate('Green1!'), isNotNull);
    expect(PasswordPolicy.validate('greenpoint1!'), isNotNull);
    expect(PasswordPolicy.validate('GREENPOINT1!'), isNotNull);
    expect(PasswordPolicy.validate('GreenPoint!'), isNotNull);
    expect(PasswordPolicy.validate('GreenPoint1'), isNotNull);
  });
}
