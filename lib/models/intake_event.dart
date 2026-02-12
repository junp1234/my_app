class IntakeEvent {
  const IntakeEvent({
    required this.id,
    required this.timestamp,
    required this.amountMl,
  });

  final int? id;
  final DateTime timestamp;
  final int amountMl;

  Map<String, Object?> toMap() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'amount_ml': amountMl,
      };

  factory IntakeEvent.fromMap(Map<String, Object?> map) => IntakeEvent(
        id: map['id'] as int?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        amountMl: map['amount_ml'] as int,
      );
}
