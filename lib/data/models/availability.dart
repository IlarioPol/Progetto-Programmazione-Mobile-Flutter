import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a time range (e.g. 09:00 - 18:00).
class TimeRange {
  final String startTime;
  final String endTime;

  const TimeRange({
    this.startTime = '09:00',
    this.endTime = '18:00',
  });

  factory TimeRange.fromMap(Map<String, dynamic> data) {
    return TimeRange(
      startTime: data['startTime'] as String? ?? '09:00',
      endTime: data['endTime'] as String? ?? '18:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  TimeRange copyWith({String? startTime, String? endTime}) {
    return TimeRange(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

/// Represents the availability for a single day of the week.
class DayAvailability {
  final int dayOfWeek; // 1=Mon, 7=Sun
  final bool workDay;
  final List<TimeRange> timeRanges;

  const DayAvailability({
    this.dayOfWeek = 1,
    this.workDay = true,
    this.timeRanges = const [TimeRange()],
  });

  factory DayAvailability.fromMap(Map<String, dynamic> data) {
    return DayAvailability(
      dayOfWeek: (data['dayOfWeek'] as num?)?.toInt() ?? 1,
      workDay: data['workDay'] as bool? ?? true,
      timeRanges: (data['timeRanges'] as List<dynamic>?)
              ?.map((e) => TimeRange.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [const TimeRange()],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'workDay': workDay,
      'timeRanges': timeRanges.map((e) => e.toMap()).toList(),
    };
  }

  DayAvailability copyWith({
    int? dayOfWeek,
    bool? workDay,
    List<TimeRange>? timeRanges,
  }) {
    return DayAvailability(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      workDay: workDay ?? this.workDay,
      timeRanges: timeRanges ?? this.timeRanges,
    );
  }
}

/// Represents the weekly availability of a provider.
class ProviderAvailability {
  final String providerId;
  final List<DayAvailability> weeklyAvailability;

  const ProviderAvailability({
    this.providerId = '',
    this.weeklyAvailability = const [],
  });

  factory ProviderAvailability.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProviderAvailability.fromMap(data);
  }

  factory ProviderAvailability.fromMap(Map<String, dynamic> data) {
    return ProviderAvailability(
      providerId: data['providerId'] as String? ?? '',
      weeklyAvailability: (data['weeklyAvailability'] as List<dynamic>?)
              ?.map((e) => DayAvailability.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'weeklyAvailability': weeklyAvailability.map((e) => e.toMap()).toList(),
    };
  }

  /// Creates a default availability (Mon-Sun, 09:00-18:00, all work days).
  static ProviderAvailability getDefault(String providerId) {
    return ProviderAvailability(
      providerId: providerId,
      weeklyAvailability: List.generate(
        7,
        (index) => DayAvailability(dayOfWeek: index + 1),
      ),
    );
  }

  ProviderAvailability copyWith({
    String? providerId,
    List<DayAvailability>? weeklyAvailability,
  }) {
    return ProviderAvailability(
      providerId: providerId ?? this.providerId,
      weeklyAvailability: weeklyAvailability ?? this.weeklyAvailability,
    );
  }
}
