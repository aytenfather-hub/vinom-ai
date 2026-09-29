/// Money in fils (1 AED = 100 fils). Integer math only.
class Money implements Comparable<Money> {
  const Money(this.fils);
  factory Money.fromAed(num aed) => Money((aed * 100).round());
  static const zero = Money(0);

  final int fils;

  Money operator +(Money o) => Money(fils + o.fils);
  Money operator -(Money o) => Money(fils - o.fils);
  Money operator *(int q) => Money(fils * q);
  bool get isZero => fils == 0;
  bool operator >(Money o) => fils > o.fils;
  bool operator >=(Money o) => fils >= o.fils;
  bool operator <(Money o) => fils < o.fils;
  bool operator <=(Money o) => fils <= o.fils;

  /// "30 د.إ" / "22.50 د.إ" (ar) — "AED 30" / "AED 22.50" (en). Western digits
  /// are used in both languages for consistency with Talabat and receipts.
  String format(String locale) {
    final whole = fils ~/ 100;
    final frac = fils.abs() % 100;
    final n = frac == 0 ? '$whole' : '$whole.${frac.toString().padLeft(2, '0')}';
    return locale == 'ar' ? '$n د.إ' : 'AED $n';
  }

  @override
  int compareTo(Money other) => fils.compareTo(other.fils);
  @override
  bool operator ==(Object other) => other is Money && other.fils == fils;
  @override
  int get hashCode => fils.hashCode;
  @override
  String toString() => 'Money($fils fils)';
}
