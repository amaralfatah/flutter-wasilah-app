import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';

void main() {
  testWidgets('keeps showing data while a dependency reloads the provider', (
    tester,
  ) async {
    // Bentuk AsyncValue saat provider dibangun ulang karena dependensinya
    // berubah: loading, tapi masih membawa data sebelumnya.
    final reloading = const AsyncLoading<int>().copyWithPrevious(
      const AsyncData(1),
      isRefresh: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AsyncValueView<int>(
          value: reloading,
          data: (value) => Text('value $value'),
        ),
      ),
    );

    expect(find.text('value 1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
