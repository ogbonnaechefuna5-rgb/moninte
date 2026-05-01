/// A single financial transaction.
class Transaction {
  final String merchant;
  final String category;
  final int amount;
  final String time;
  final String icon;

  const Transaction(this.merchant, this.category, this.amount, this.time, this.icon);
}
