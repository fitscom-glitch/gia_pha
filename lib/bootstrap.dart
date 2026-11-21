import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Khởi tạo chung: bắt lỗi toàn cục rồi chạy app.
/// Sau này gắn thêm crash reporting (Sentry/Crashlytics) tại đây.
Future<void> bootstrap(Widget Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Lỗi chưa xử lý: $error\n$stack');
    return true;
  };

  runApp(ProviderScope(child: builder()));
}
