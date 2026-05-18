class SavingsGoal {
  final int id;
  final String name;
  final String emoji;
  final int current;
  final int target;
  final String deadline;
  final String status;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.current,
    required this.target,
    required this.deadline,
    required this.status,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
        id: j['id'],
        name: j['name'],
        emoji: j['emoji'],
        current: j['current'],
        target: j['target'],
        deadline: j['deadline'],
        status: j['status'],
      );
}
