import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    super.key,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // Beri transisi antar state supaya konten tidak berkedip muncul
    // menggantikan spinner dalam satu frame.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: value.when(
        data: (data) => KeyedSubtree(
          key: const ValueKey('data'),
          child: this.data(data),
        ),
        loading: () => const AppLoading(key: ValueKey('loading')),
        error: (error, stackTrace) => AppErrorView(
          key: const ValueKey('error'),
          onRetry: onRetry,
        ),
      ),
    );
  }
}
