import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_text_field.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_management_controller.dart';
import 'package:go_router/go_router.dart';

class TargetFormPage extends ConsumerStatefulWidget {
  const TargetFormPage({super.key, this.targetId});

  final String? targetId;

  @override
  ConsumerState<TargetFormPage> createState() => _TargetFormPageState();
}

class _TargetFormPageState extends ConsumerState<TargetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _percentageController = TextEditingController();
  AssetCategory _category = AssetCategory.cash;
  bool _didPopulate = false;

  bool get _isEditing => widget.targetId != null;

  @override
  void dispose() {
    _percentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetId = widget.targetId;
    if (targetId != null) {
      final targetsValue = ref.watch(allocationTargetProvider);
      return targetsValue.when(
        data: (targets) {
          final target = _findTarget(targets, targetId);
          if (target == null) {
            return const Scaffold(
              body: AppErrorView(message: 'Target tidak ditemukan.'),
            );
          }

          _populateFromTarget(target);
          return _TargetFormScaffold(
            title: 'Edit target',
            child: _buildForm(context, target),
          );
        },
        loading: () => const Scaffold(body: AppLoading()),
        error: (error, stackTrace) => const Scaffold(body: AppErrorView()),
      );
    }

    return _TargetFormScaffold(
      title: 'Tambah target',
      child: _buildForm(context, null),
    );
  }

  Widget _buildForm(BuildContext context, AllocationTarget? editingTarget) {
    final submitState = ref.watch(targetManagementControllerProvider);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          DropdownButtonFormField<AssetCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: AssetCategory.values
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
                )
                .toList(),
            onChanged: submitState.isLoading
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _category = value;
                    });
                  },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Target alokasi',
            controller: _percentageController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffixIcon: const Padding(
              padding: EdgeInsetsDirectional.only(end: AppSpacing.md),
              child: Center(widthFactor: 1, child: Text('%')),
            ),
            validator: _validatePercentage,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: _isEditing ? 'Simpan perubahan' : 'Tambah target',
            isLoading: submitState.isLoading,
            onPressed: () => _submit(editingTarget),
          ),
          if (_isEditing && editingTarget != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: submitState.isLoading
                  ? null
                  : () => _deleteTarget(editingTarget),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Hapus target'),
            ),
          ],
        ],
      ),
    );
  }

  AllocationTarget? _findTarget(List<AllocationTarget> targets, String id) {
    for (final target in targets) {
      if (target.id == id) {
        return target;
      }
    }

    return null;
  }

  void _populateFromTarget(AllocationTarget target) {
    if (_didPopulate) {
      return;
    }

    _category = target.category;
    _percentageController.text = target.targetPercentage.toStringAsFixed(0);
    _didPopulate = true;
  }

  String? _validatePercentage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Target alokasi wajib diisi.';
    }

    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) {
      return 'Target alokasi tidak valid.';
    }

    if (parsed < 0 || parsed > 100) {
      return 'Target alokasi harus di antara 0 sampai 100%.';
    }

    return null;
  }

  Future<void> _submit(AllocationTarget? editingTarget) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final percentage = double.parse(
      _percentageController.text.trim().replaceAll(',', '.'),
    );

    try {
      await ref
          .read(targetManagementControllerProvider.notifier)
          .saveTarget(
            id: editingTarget?.id,
            category: _category,
            targetPercentage: percentage,
          );
      if (!mounted) {
        return;
      }
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ArgumentError
          ? error.message.toString()
          : 'Target belum berhasil disimpan. Coba lagi.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteTarget(AllocationTarget target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus target?'),
        content: Text('Target ${target.category.label} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(targetManagementControllerProvider.notifier)
          .deleteTarget(target.id);
      if (!mounted) {
        return;
      }
      context.go(RouteNames.target);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Target belum berhasil dihapus. Coba lagi.'),
        ),
      );
    }
  }
}

class _TargetFormScaffold extends StatelessWidget {
  const _TargetFormScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
    );
  }
}
