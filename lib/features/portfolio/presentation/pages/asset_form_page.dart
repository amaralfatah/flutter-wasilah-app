import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/rupiah_input_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_text_field.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/asset_management_controller.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetId = widget.assetId;
    if (assetId != null) {
      final assetValue = ref.watch(assetDetailProvider(assetId));
      return assetValue.when(
        data: (asset) {
          if (asset == null) {
            return const Scaffold(
              body: AppErrorView(message: 'Aset tidak ditemukan.'),
            );
          }

          _populateFromAsset(asset);
          return _AssetFormScaffold(
            title: 'Edit aset',
            child: _buildForm(context, asset),
          );
        },
        loading: () => const Scaffold(body: AppLoading()),
        error: (error, stackTrace) => const Scaffold(body: AppErrorView()),
      );
    }

    return _AssetFormScaffold(
      title: 'Tambah aset',
      child: _buildForm(context, null),
    );
  }

  Widget _buildForm(BuildContext context, Asset? editingAsset) {
    final submitState = ref.watch(assetManagementControllerProvider);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppTextField(
            label: 'Nama aset',
            controller: _nameController,
            validator: (value) =>
                validateRequiredText(value, message: 'Nama aset wajib diisi.'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Kode aset',
            controller: _codeController,
            validator: (value) =>
                validateRequiredText(value, message: 'Kode aset wajib diisi.'),
          ),
          const SizedBox(height: AppSpacing.lg),
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
          if (!_isEditing) ...[
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Nilai awal',
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
                decoration: const InputDecoration(
                  labelText: 'Tanggal pencatatan',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(formatFullDate(_recordedAt)),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: _isEditing ? 'Simpan perubahan' : 'Tambah aset',
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
              child: const Text('Hapus aset'),
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
            );
      } else {
        await ref
            .read(assetManagementControllerProvider.notifier)
            .updateAsset(
              editingAsset.copyWith(
                name: _nameController.text,
                code: _codeController.text,
                category: _category,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus aset?'),
        content: Text('Aset ${asset.name} dan histori nilainya akan dihapus.'),
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
    final message = error is ArgumentError
        ? error.message.toString()
        : 'Aset belum berhasil disimpan. Coba lagi.';
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
