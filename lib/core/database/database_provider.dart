import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/database/app_database.dart';

final appDatabaseProvider =
    Provider<AppDatabase>((ref) => AppDatabase.instance);
