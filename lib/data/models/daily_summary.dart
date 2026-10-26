class DailySummary {
  final String id; // yyyy-MM-dd
  final DateTime date;
  final String summary;

  const DailySummary({
    required this.id,
    required this.date,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'summary': summary,
  };

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    summary: json['summary'] as String,
  );
}
