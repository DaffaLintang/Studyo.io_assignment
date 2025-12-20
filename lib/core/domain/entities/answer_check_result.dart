class AnswerCheckResult {
  final bool correct;
  final int? expectedBox1;
  final int? expectedBox2;
  final int? expectedBox3;
  final List<String> messages;

  const AnswerCheckResult({
    required this.correct,
    required this.expectedBox1,
    required this.expectedBox2,
    required this.expectedBox3,
    required this.messages,
  });
}
