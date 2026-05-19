import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ActivityType { idle, walking, running }

class ActivityService {
  ActivityType _currentActivity = ActivityType.idle;
  int _todaySteps = 0;
  double _todayCalories = 0;
  int _sedentaryMinutes = 0;
  DateTime? _lastMovementTime;

  final _activityController = StreamController<ActivityType>.broadcast();
  final _stepsController = StreamController<int>.broadcast();
  final _caloriesController = StreamController<double>.broadcast();
  final _sedentaryController = StreamController<int>.broadcast();
  final _warningController = StreamController<String>.broadcast();

  Stream<ActivityType> get activityStream => _activityController.stream;
  Stream<int> get stepsStream => _stepsController.stream;
  Stream<double> get caloriesStream => _caloriesController.stream;
  Stream<int> get sedentaryStream => _sedentaryController.stream;
  Stream<String> get warningStream => _warningController.stream;

  ActivityType get currentActivity => _currentActivity;
  int get todaySteps => _todaySteps;
  double get todayCalories => _todayCalories;
  int get sedentaryMinutes => _sedentaryMinutes;

  final List<double> _magnitudeBuffer = [];
  static const int _bufferSize = 15;

  Timer? _sedentaryCheckTimer;
  Timer? _analysisTimer;        // ← BARU: timer untuk analisis berkala
  StreamSubscription? _accelSub; // ← BARU: simpan subscription

  static const double _weightKg = 65.0;

  // BARU: simpan nilai sensor terbaru
  double _latestMagnitude = 0;

  void initialize() {
    _loadTodayData();
    _startAccelerometer();
    _startPedometer();
    _startSedentaryMonitor();
    _startAnalysisTimer(); // ← BARU
  }

  void _startAccelerometer() {
    // Pakai UI interval (lebih lambat dari normal/game)
    // Ini fix utama: kurangi frekuensi polling sensor
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval, // ~60ms sekali, bukan terus-terusan
    ).listen((AccelerometerEvent event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      // Hanya simpan nilai terbaru, analisis dilakukan timer terpisah
      _latestMagnitude = (magnitude - 9.8).abs();
    });
  }

  // BARU: analisis sensor setiap 500ms, bukan setiap event
  void _startAnalysisTimer() {
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_latestMagnitude == 0) return;

      _magnitudeBuffer.add(_latestMagnitude);
      if (_magnitudeBuffer.length > _bufferSize) {
        _magnitudeBuffer.removeAt(0);
      }

      if (_magnitudeBuffer.length >= 5) {
        _detectActivity();
      }
    });
  }

  void _detectActivity() {
    final avg = _magnitudeBuffer.reduce((a, b) => a + b) / _magnitudeBuffer.length;
    final variance = _magnitudeBuffer
        .map((v) => pow(v - avg, 2))
        .reduce((a, b) => a + b) / _magnitudeBuffer.length;

    ActivityType detected;

    if (variance < 0.3 && avg < 0.5) {
      detected = ActivityType.idle;
    } else if (variance < 2.0) {
      detected = ActivityType.walking;
      _lastMovementTime = DateTime.now();
    } else {
      detected = ActivityType.running;
      _lastMovementTime = DateTime.now();
    }

    if (detected != _currentActivity) {
      _currentActivity = detected;
      if (!_activityController.isClosed) {
        _activityController.add(_currentActivity);
      }
    }
  }

  void _startPedometer() {
    Pedometer.stepCountStream.listen(
      (StepCount event) {
        _todaySteps++;
        if (!_stepsController.isClosed) {
          _stepsController.add(_todaySteps);
        }

        final caloriesPerStep = _currentActivity == ActivityType.running
            ? _weightKg * 0.0008
            : _weightKg * 0.0005;

        _todayCalories += caloriesPerStep;
        if (!_caloriesController.isClosed) {
          _caloriesController.add(_todayCalories);
        }
        _saveTodayData();
      },
      onError: (error) {
        print('Pedometer error: $error');
      },
    );
  }

  void _startSedentaryMonitor() {
    _sedentaryCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      final lastMove = _lastMovementTime;

      if (lastMove == null || now.difference(lastMove).inMinutes >= 1) {
        _sedentaryMinutes++;
        if (!_sedentaryController.isClosed) {
          _sedentaryController.add(_sedentaryMinutes);
        }

        if (_sedentaryMinutes > 0 && _sedentaryMinutes % 30 == 0) {
          if (!_warningController.isClosed) {
            _warningController.add(
              '⚠️ Kamu udah diem $_sedentaryMinutes menit! '
              'Gerak dikit dong, scroll doang ga bakar kalori 😅',
            );
          }
        }
      } else {
        if (_sedentaryMinutes > 0) {
          _sedentaryMinutes = 0;
          if (!_sedentaryController.isClosed) {
            _sedentaryController.add(0);
          }
        }
      }
    });
  }

  Future<void> _saveTodayData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    prefs.setInt('steps_$today', _todaySteps);
    prefs.setDouble('calories_$today', _todayCalories);
  }

  Future<void> _loadTodayData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    _todaySteps = prefs.getInt('steps_$today') ?? 0;
    _todayCalories = prefs.getDouble('calories_$today') ?? 0;
    if (!_stepsController.isClosed) _stepsController.add(_todaySteps);
    if (!_caloriesController.isClosed) _caloriesController.add(_todayCalories);
  }

  void dispose() {
    _accelSub?.cancel();       // ← cancel subscription dengan benar
    _analysisTimer?.cancel();
    _sedentaryCheckTimer?.cancel();
    _activityController.close();
    _stepsController.close();
    _caloriesController.close();
    _sedentaryController.close();
    _warningController.close();
  }
}