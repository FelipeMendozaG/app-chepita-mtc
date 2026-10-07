import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discussion.dart';
import '../services/discussion_service.dart';

final discussionServiceProvider = Provider((ref) => DiscussionService());

final discussionsProvider = FutureProvider<List<Discussion>>((ref) {
  return ref.read(discussionServiceProvider).getDiscussions();
});
