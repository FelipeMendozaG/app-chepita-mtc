import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attempt.dart';
import '../services/attempt_service.dart';

final attemptServiceProvider = Provider<AttemptService>((ref) {
  return AttemptService();
});

final attemptsProvider = FutureProvider<List<Attempt>>((ref) async {
  return ref.read(attemptServiceProvider).getAttempts();
});

final attemptDetailProvider = FutureProvider.family<Attempt, int>((
  ref,
  attemptId,
) async {
  return ref.read(attemptServiceProvider).getAttemptDetail(attemptId);
});
