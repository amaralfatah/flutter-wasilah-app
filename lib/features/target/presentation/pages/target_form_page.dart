import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/asset_category_l10n.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_management_controller.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_text_field.dart';
import 'package:flutter_wasilah_app/shared/widgets/confirm_dialog.dart';
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
    final l10n = context.l10n;
    final targetId = widget.targetId;
    final targetsValue = ref.watch(allocationTargetProvider);
    return targetsValue.when(
      data: (targets) {
        if (targetId != null) {
          final target = _findTarget(targets, targetId);
          if (target == null) {
            return Scaffold(
              body: AppErrorView(message: l10n.targetNotFoundMessage),
            );
          }

          _populateFromTarget(target);
          // Kategori dikunci saat edit: id target diturunkan dari kategori,
          // dan satu kategori hanya boleh punya satu target.
          return _TargetFormScaffold(
            title: l10n.editTargetTitle,
            child: _buildForm(context, target, [target.category]),
          );
        }

        // Kategori yang sudah punya target tidak ditawarkan lagi; menyimpan
        // kategori yang sama akan menimpa target lamanya.
        final taken = {for (final target in targets) target.category};
        final available = AssetCategory.values
            .where((category) => !taken.contains(category))
            .toList(growable: false);
        if (available.isEmpty) {
          return _TargetFormScaffold(
            title: l10n.addTargetTitle,
            child: AppErrorView(message: l10n.allCategoriesHaveTargetMessage),
          );
        }
        if (!available.contains(_category)) {
          _category = available.first;
        }
        return _TargetFormScaffold(
          title: l10n.addTargetTitle,
          child: _buildForm(context, null, available),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (error, stackTrace) => const Scaffold(body: AppErrorView()),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AllocationTarget? editingTarget,
    List<AssetCategory> categories,
  ) {
    final submitState = ref.watch(targetManagementControllerProvider);
    final l10n = context.l10n;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          DropdownButtonFormField<AssetCategory>(
            initialValue: _category,
            decoration: InputDecoration(labelText: l10n.commonCategoryLabel),
            items: categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.localizedLabel(l10n)),
                  ),
                )
                .toList(),
            onChanged: submitState.isLoading || _isEditing
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
            label: l10n.targetAllocationLabel,
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
            label: _isEditing ? l10n.commonSaveChanges : l10n.addTargetTitle,
            isLoading: submitState.isLoading,
            onPressed: _submit,
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
              child: Text(l10n.deleteTargetButton),
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
    // Desimal dipertahankan (12,5 tetap 12,5, bukan dibulatkan jadi 13).
    _percentageController.text = formatQuantity(target.targetPercentage);
    _didPopulate = true;
  }

  String? _validatePercentage(String? value) {
    final l10n = context.l10n;
    if (value == null || value.trim().isEmpty) {
      return l10n.targetPercentageRequired;
    }

    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) {
      return l10n.targetPercentageInvalid;
    }

    if (parsed < 0 || parsed > 100) {
      return l10n.targetPercentageRange;
    }

    return null;
  }

  Future<void> _submit() async {
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
            category: _category,
            targetPercentage: percentage,
          );
      if (!mounted) {
        return;
      }
      context.pop();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final l10n = context.l10n;
      final message = switch (error) {
        InvalidTargetPercentageException() => l10n.targetPercentageRange,
        TargetPercentageExceededException() =>
          l10n.targetPercentageExceededMessage,
        ValidationException(:final failure) => validationMessage(l10n, failure),
        _ => l10n.targetSaveFailedMessage,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteTarget(AllocationTarget target) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteTargetTitle,
      message: l10n.deleteTargetMessage(target.category.localizedLabel(l10n)),
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );

    if (!confirmed) {
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
    } on Object {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.targetDeleteFailedMessage),
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
      body: SafeArea(child: child),
    );
  }
}
