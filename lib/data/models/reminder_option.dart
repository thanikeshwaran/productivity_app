enum ReminderType {
  none,
  fiveMinutes,
  fifteenMinutes,
  thirtyMinutes,
  oneDay,
  twoDays,
  oneWeek,
  custom;

  /// Defensive lookup for persisted data: any value saved by an older build
  /// (e.g. the removed `threeDays`) or otherwise unrecognized falls back to
  /// `none` instead of throwing and losing the whole task/note on load.
  static ReminderType fromName(String name) {
    for (final t in ReminderType.values) {
      if (t.name == name) return t;
    }
    return ReminderType.none;
  }
}

enum ReminderUnit { minutes, days, weeks }

class ReminderOption {
  final ReminderType type;
  final int? customAmount;
  final ReminderUnit? customUnit;

  const ReminderOption(this.type, {this.customAmount, this.customUnit});

  static const none = ReminderOption(ReminderType.none);

  String get label {
    switch (type) {
      case ReminderType.none:
        return 'None';
      case ReminderType.fiveMinutes:
        return '5 mins';
      case ReminderType.fifteenMinutes:
        return '15 mins';
      case ReminderType.thirtyMinutes:
        return '30 min';
      case ReminderType.oneDay:
        return '1 day';
      case ReminderType.twoDays:
        return '2 day';
      case ReminderType.oneWeek:
        return '1 week';
      case ReminderType.custom:
        final unit = switch (customUnit ?? ReminderUnit.days) {
          ReminderUnit.minutes => 'min',
          ReminderUnit.days => 'day',
          ReminderUnit.weeks => 'week',
        };
        final amount = customAmount ?? 0;
        return '$amount $unit${amount == 1 ? '' : 's'} before';
    }
  }

  Duration? get leadTime {
    switch (type) {
      case ReminderType.none:
        return null;
      case ReminderType.fiveMinutes:
        return const Duration(minutes: 5);
      case ReminderType.fifteenMinutes:
        return const Duration(minutes: 15);
      case ReminderType.thirtyMinutes:
        return const Duration(minutes: 30);
      case ReminderType.oneDay:
        return const Duration(days: 1);
      case ReminderType.twoDays:
        return const Duration(days: 2);
      case ReminderType.oneWeek:
        return const Duration(days: 7);
      case ReminderType.custom:
        final amount = customAmount ?? 0;
        return switch (customUnit ?? ReminderUnit.days) {
          ReminderUnit.minutes => Duration(minutes: amount),
          ReminderUnit.days => Duration(days: amount),
          ReminderUnit.weeks => Duration(days: amount * 7),
        };
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'customAmount': customAmount,
    'customUnit': customUnit?.name,
  };

  factory ReminderOption.fromJson(Map<String, dynamic> json) => ReminderOption(
    ReminderType.fromName(json['type'] as String? ?? 'none'),
    customAmount: json['customAmount'] as int? ?? json['customDays'] as int?,
    customUnit: json['customUnit'] == null
        ? (json['customDays'] != null ? ReminderUnit.days : null)
        : ReminderUnit.values.byName(json['customUnit'] as String),
  );
}
