import '../entities/answer_check_result.dart';

class CheckAnswerUseCase {
  AnswerCheckResult execute(String assignmentText, {required int c1, required int c2, required int c3}) {
    final expected = _expectedPerBox(assignmentText);
    bool correct = false;
    final messages = <String>[];

    if (expected != null && expected.$1 != null && expected.$2 != null && expected.$3 != null) {
      correct = (c1 == expected.$1 && c2 == expected.$2 && c3 == expected.$3);
      if (!correct) {
        if (c1 != expected.$1) messages.add('Answer Box 1 wrong number of marbles');
        if (c2 != expected.$2) messages.add('Answer Box 2 wrong number of marbles');
        if (c3 != expected.$3) messages.add('Answer Box 3 wrong number of marbles');
      }
    } else {
      messages.add('Division result is not an integer; cannot distribute exactly');
    }

    return AnswerCheckResult(
      correct: correct,
      expectedBox1: expected?.$1,
      expectedBox2: expected?.$2,
      expectedBox3: expected?.$3,
      messages: messages,
    );
  }

  (int?, int?, int?)? _expectedPerBox(String text) {
    final exp = text.replaceAll(' ', '');
    final match = RegExp(r'^(\d+)([+\-*/])(\d+)$').firstMatch(exp);
    if (match == null) return null;
    final a = int.parse(match.group(1)!);
    final op = match.group(2)!;
    final b = int.parse(match.group(3)!);
    switch (op) {
      case '+':
        final r = a + b;
        return (r, r, r);
      case '-':
        final r = a - b;
        return (r, r, r);
      case '*':
        final r = a * b;
        return (r, r, r);
      case '/':
        if (b == 0) return (null, null, null);
        if (a % b != 0) return (null, null, null);
        final r = a ~/ b;
        return (r, r, r);
      default:
        return null;
    }
  }
}
