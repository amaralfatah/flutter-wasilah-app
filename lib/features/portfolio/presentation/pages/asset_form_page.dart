import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/rupiah_input_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/asset_management_controller.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_text_field.dart';
import 'package:flutter_wasilah_app/shared/widgets/confirm_dialog.dart';
import 'package:go_router/go_router.dart';

class AssetFormPage extends ConsumerStatefulWidget {
  const AssetFormPage({super.key, this.assetId});

  final String? assetId;

  @override
  ConsumerState<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends ConsumerState<AssetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _valueController = TextEditingController();
  final _costController = TextEditingController();
  late DateTime _recordedAt;
  AssetCategory _category = AssetCategory.other;
  bool _didPopulate = false;

  bool get _isEditing => widget.assetId != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _recordedAt = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _valueController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final assetId = widget.assetId;
    if (assetId != null) {
      final assetValue = ref.watch(assetDetailProvider(assetId));
      return assetValue.when(
        data: (asset) {
          if (asset == null) {
            return Scaffold(
              body: AppErrorView(message: l10n.assetNotFoundFormMessage),
            );
          }

          _populateFromAsset(asset);
          return _AssetFormScaffold(
            title: l10n.editAssetTitle,
            child: _buildForm(context, asset),
          );
        },
        loading: () => const Scaffold(body: AppLoading()),
        error: (error, stackTrace) => const Scaffold(body: AppErrorView()),
      );
    }

    return _AssetFormScaffold(
      title: l10n.addAssetTitle,
      child: _buildForm(context, null),
    );
  }

  Widget _buildForm(BuildContext context, Asset? editingAsset) {
    final submitState = ref.watch(assetManagementControllerProvider);
    final l10n = context.l10n;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppTextField(
            label: l10n.assetNameLabel,
            controller: _nameController,
            validator: (value) => validateRequiredText(
              value,
              message: l10n.assetNameRequired,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.assetCodeLabel,
            controller: _codeController,
            validator: (value) => validateRequiredText(
              value,
              message: l10n.assetCodeRequired,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<AssetCategory>(
            initialValue: _category,
            decoration: InputDecoration(labelText: l10n.commonCategoryLabel),
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
          if (!_isEditing) ...[
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.initialValueLabel,
              controller: _valueController,
              keyboardType: TextInputType.number,
              prefixText: 'Rp',
              inputFormatters: const [RupiahInputFormatter()],
              validator: validateCurrencyValue,
            ),
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              onTap: submitState.isLoading ? null : _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.commonRecordedAtLabel,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  formatFullDate(_recordedAt, Localizations.localeOf(context)),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.commonTotalCostOptionalLabel,
            helperText: l10n.totalCostOptionalHelper,
            controller: _costController,
            keyboardType: TextInputType.number,
            prefixText: 'Rp',
            inputFormatters: const [RupiahInputFormatter()],
            validator: validateOptionalCurrencyValue,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: _isEditing ? l10n.commonSaveChanges : l10n.addAssetTitle,
            isLoading: submitState.isLoading,
            onPressed: () => _submit(editingAsset),
          ),
          if (_isEditing && editingAsset != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: submitState.isLoading
                  ? null
                  : () => _deleteAsset(editingAsset),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.deleteAssetButton),
            ),
          ],
        ],
      ),
    );
  }

  void _populateFromAsset(Asset asset) {
    if (_didPopulate) {
      return;
    }

    _nameController.text = asset.name;
    _codeController.text = asset.code;
    _category = asset.category;
    final totalCost = asset.totalCost;
    if (totalCost != null) {
      _costController.text = formatCurrency(totalCost).replaceFirst('Rp', '');
    }
    _didPopulate = true;
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(_recordedAt.year - 10),
      lastDate: DateTime(_recordedAt.year + 1),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _recordedAt = pickedDate;
    });
  }

  Future<void> _submit(Asset? editingAsset) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final totalCost = parseCurrencyInput(_costController.text);

    try {
      if (editingAsset == null) {
        final value = parseCurrencyInput(_valueController.text);
        if (value == null) {
          return;
        }

        await ref
            .read(assetManagementControllerProvider.notifier)
            .createAsset(
              name: _nameController.text,
              code: _codeController.text,
              category: _category,
              currentValue: value,
              recordedAt: _recordedAt,
              totalCost: totalCost,
            );
      } else {
        await ref
            .read(assetManagementControllerProvider.notifier)
            .updateAsset(
              editingAsset.copyWith(
                name: _nameController.text,
                code: _codeController.text,
                category: _category,
                totalCost: totalCost,
              ),
            );
      }

      if (!mounted) {
        return;
      }
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    }
  }

  Future<void> _deleteAsset(Asset asset) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteAssetTitle,
      message: l10n.deleteAssetMessage(asset.name),
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );

    if (!confirmed) {
      return;
    }

    try {
      await ref
          .read(assetManagementControllerProvider.notifier)
          .deleteAsset(asset.id);
      if (!mounted) {
        return;
      }
      context.go(RouteNames.assets);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    }
  }

  void _showError(Object error) {
    final l10n = context.l10n;
    final message = switch (error) {
      InvalidCurrentValueException() => l10n.invalidCurrentValueMessage,
      InvalidTotalCostException() => l10n.invalidTotalCostMessage,
      ArgumentError() => error.message.toString(),
      _ => l10n.assetSaveFailedMessage,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AssetFormScaffold extends StatelessWidget {
  const _AssetFormScaffold({required this.title, required this.child});

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
