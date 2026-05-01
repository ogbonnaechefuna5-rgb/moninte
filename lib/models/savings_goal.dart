/// A savings goal tracked on the savings screen.
class SavingsGoal {
  final int id;
  final String name;
  final String emoji;
  final int current;
  final int target;
  final String deadline;
  final String status; // 'active' | 'completed'

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.current,
    required this.target,
    required this.deadline,
    required this.status,
  });
}
