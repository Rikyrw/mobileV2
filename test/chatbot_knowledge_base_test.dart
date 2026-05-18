import 'package:flutter_test/flutter_test.dart';
import 'package:mob_2/services/chatbot_knowledge_base.dart';

void main() {
  const knowledgeBase = ChatbotKnowledgeBase();

  test('registration intent beats generic app overview', () {
    final answer = knowledgeBase.answerFor(
      'cara daftar di aplikasi green point bagaimana ya?',
    );

    expect(answer, contains('Untuk daftar akun Green Point'));
    expect(answer, contains('Password minimal 8 karakter'));
  });

  test('registration typo still matches the registration flow', () {
    final answer = knowledgeBase.answerFor('cara daftarya gimana?');

    expect(answer, contains('Untuk daftar akun Green Point'));
  });

  test('setor sampah question returns app-specific flow', () {
    final answer = knowledgeBase.answerFor('gimana cara setor sampah?');

    expect(answer, contains('Transaksi Setor Sampah'));
    expect(answer, contains('Ajukan Setor Sampah'));
  });

  test(
    'generic app question still returns overview when no stronger intent exists',
    () {
      final answer = knowledgeBase.answerFor('Green Point itu aplikasi apa?');

      expect(answer, contains('Green Point adalah aplikasi'));
      expect(answer, contains('E-Money'));
    },
  );
}
