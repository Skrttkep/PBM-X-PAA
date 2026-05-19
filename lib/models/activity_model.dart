class ActivityData {
  final String type; // 'walking', 'running', 'idle'
  final int steps;
  final double caloriesBurned;
  final DateTime timestamp;
  final Duration duration;

  ActivityData({
    required this.type,
    required this.steps,
    required this.caloriesBurned,
    required this.timestamp,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'steps': steps,
    'caloriesBurned': caloriesBurned,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration.inSeconds,
  };

  factory ActivityData.fromJson(Map<String, dynamic> json) => ActivityData(
    type: json['type'],
    steps: json['steps'],
    caloriesBurned: json['caloriesBurned'],
    timestamp: DateTime.parse(json['timestamp']),
    duration: Duration(seconds: json['duration']),
  );
}