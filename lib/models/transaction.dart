class Transaction {
  final String merchant;
  final String category;
  final int amount;
  final String time;
  final String icon;

  const Transaction(this.merchant, this.category, this.amount, this.time, this.icon);

  factory Transaction.fromJson(Map<String, dynamic> j) =>
      Transaction(j['merchant'], j['category'], j['amount'], j['time'], j['icon']);
}
