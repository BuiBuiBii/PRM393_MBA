import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_api.dart';
import 'dio_client.dart';

/// Provider API tập trung — tách khỏi auth feature (tiêu chí tách logic).
final appApiProvider = Provider<AppApi>((ref) => AppApi(ref.watch(dioProvider)));
