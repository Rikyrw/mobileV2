import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'viewmodels/setor_sampah_view_model.dart';

class SetorSampahScreen extends StatefulWidget {
  const SetorSampahScreen({super.key});

  @override
  State<SetorSampahScreen> createState() => _SetorSampahScreenState();
}

class _SetorSampahScreenState extends State<SetorSampahScreen> {
  final SetorSampahViewModel _viewModel = SetorSampahViewModel();
  bool _profileLoadRequested = false;

  @override
  void initState() {
    super.initState();
    _viewModel.loadWasteTypes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileLoadRequested) {
      _profileLoadRequested = true;
      _viewModel.loadUserProfile(emailArgument: _routeEmailArgument);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  String? get _routeEmailArgument {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['email'] is String) {
      return args['email'] as String;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final errorMessage = _viewModel.errorMessage;
        if (errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showSnack(errorMessage);
            _viewModel.clearError();
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _header(),
                      const SizedBox(height: 16),
                      _saldoCard(),
                      const SizedBox(height: 24),
                      _sectionTitle('Data Pengirim'),
                      const SizedBox(height: 8),
                      _senderCard(),
                      const SizedBox(height: 24),
                      _sectionTitle('Jenis Sampah'),
                      const SizedBox(height: 24),
                      _addWasteButton(),
                      const SizedBox(height: 16),
                      if (_viewModel.wasteItems.isNotEmpty) _wasteList(),
                      const SizedBox(height: 12),
                      _totalCard(),
                      const SizedBox(height: 24),
                      _calculateButton(),
                      const SizedBox(height: 12),
                      if (_viewModel.showAjukanButton) _submitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(
                  '/profil',
                  arguments: _viewModel.profileArguments,
                );
              },
              icon: const Icon(Icons.arrow_back),
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              color: const Color(0xFF333333),
            ),
          ),
          const Text(
            'Setor Sampah',
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 20,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _viewModel.userName,
              style: const TextStyle(
                color: Color(0xFF315A39),
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saldoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Anda',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            _viewModel.saldoText,
            style: const TextStyle(
              color: Color(0xFF315A39),
              fontSize: 24,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 16,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _senderCard() {
    final senderName = _viewModel.senderName;
    final senderAddress = _viewModel.senderAddress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nama Lengkap',
            style: TextStyle(
              color: Color(0xFF999999),
              fontSize: 12,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            senderName.isNotEmpty ? senderName : '-',
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 14,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Alamat Lengkap',
            style: TextStyle(
              color: Color(0xFF999999),
              fontSize: 12,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            senderAddress.isNotEmpty ? senderAddress : '-',
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 14,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addWasteButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _showAddWasteDialog,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: Color(0xFF315A39)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          backgroundColor: Colors.transparent,
        ),
        child: const Text(
          '+ Tambah Jenis Sampah',
          style: TextStyle(
            color: Color(0xFF315A39),
            fontSize: 14,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _wasteList() {
    return Column(
      children: _viewModel.wasteItems.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: CheckboxListTile(
            isThreeLine: true,
            value: item.selected,
            onChanged: (value) {
              _viewModel.toggleWasteItem(item, value ?? false);
            },
            title: Text(
              item.name,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: _wasteItemDetails(item),
            secondary: IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFBF360C)),
              onPressed: () => _confirmRemoveWaste(item),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _wasteItemDetails(WasteItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${SetorSampahViewModel.formatRupiah(item.price.round())} / kg',
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: TextField(
                controller: item.weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'Berat (kg)',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _isWeightInvalid(item)
                          ? Colors.red
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _isWeightInvalid(item)
                          ? Colors.red
                          : const Color(0xFF315A39),
                      width: 2,
                    ),
                  ),
                  errorText: _isWeightInvalid(item) ? 'Minimal 1 kg' : null,
                ),
                onChanged: (_) => _viewModel.refreshTotals(),
              ),
            ),
            const SizedBox(width: 8),
            const Text('kg'),
          ],
        ),
        const SizedBox(height: 10),
        _photoSection(item),
      ],
    );
  }

  Widget _photoSection(WasteItem item) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...item.images.map((image) {
          return Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: kIsWeb
                    ? Image.network(
                        image.path,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(image.path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
              ),
              GestureDetector(
                onTap: () => _confirmRemoveImage(item, image),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF315A39),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            ],
          );
        }),
        if (item.selected &&
            item.images.length < SetorSampahViewModel.maxPhotosPerItem)
          OutlinedButton.icon(
            onPressed: _viewModel.validatingPhoto
                ? null
                : () => _showImageSourceOptions(item),
            icon: _viewModel.validatingPhoto
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Color(0xFF315A39),
                  ),
            label: Text(
              _viewModel.validatingPhoto ? 'Memeriksa...' : 'Tambah Foto',
              style: TextStyle(
                color: _viewModel.validatingPhoto
                    ? const Color(0xFF7A867E)
                    : const Color(0xFF315A39),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF315A39)),
            ),
          ),
      ],
    );
  }

  Widget _totalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Total Harga',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            SetorSampahViewModel.formatRupiah(_viewModel.totalHarga),
            style: const TextStyle(
              color: Color(0xFF315A39),
              fontSize: 18,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _calculateButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _viewModel.refreshTotals,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF315A39),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        child: const Text(
          'Hitung Total',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _viewModel.submitting ? null : _submitSetorSampah,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        child: _viewModel.submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Ajukan Setor Sampah',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
      ),
    );
  }

  Future<void> _submitSetorSampah() async {
    final result = await _viewModel.submitSetorSampah();
    if (!mounted) return;

    if (result.message.isNotEmpty) {
      _showSnack(result.message);
    }

    if (result.success) {
      Navigator.of(
        context,
      ).pushReplacementNamed('/profil', arguments: result.profileArguments);
    }
  }

  void _showAddWasteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _viewModel.loadingWasteTypes
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 8),
                        children: [
                          const ListTile(title: Text('Pilih Jenis Sampah')),
                          ..._viewModel.wasteTypes.map((item) {
                            final price = _asDouble(item['price']);
                            final name = item['name']?.toString() ?? '-';
                            return ListTile(
                              title: Text(name),
                              subtitle: Text(
                                SetorSampahViewModel.formatRupiah(
                                  price.round(),
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                _showWeightDialogForPreset(
                                  _asInt(item['id']),
                                  name,
                                  price,
                                );
                              },
                            );
                          }),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showWeightDialogForPreset(
    int jenisId,
    String name,
    double price,
  ) async {
    final weightController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Berat untuk $name'),
          content: TextField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Masukkan berat (kg), contoh: 1.5',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final result = _viewModel.addOrUpdateWaste(
                  jenisId: jenisId,
                  name: name,
                  price: price,
                  rawWeight: weightController.text,
                );

                if (!result.success) {
                  _showSnack(result.message);
                  return;
                }

                Navigator.of(context).pop();
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
    weightController.dispose();
  }

  void _showImageSourceOptions(WasteItem item) {
    if (_viewModel.validatingPhoto) {
      _showSnack('Tunggu sampai pemeriksaan foto selesai.');
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(item, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil Foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(item, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(WasteItem item, ImageSource source) async {
    if (_viewModel.validatingPhoto) {
      _showSnack('Tunggu sampai pemeriksaan foto selesai.');
      return;
    }

    _showSnack('Memeriksa foto sampah...');
    final result = await _viewModel.pickAndValidateImage(item, source);
    if (!mounted) return;

    if (result.hasWarning) {
      _showInvalidPhotoWarning(result.warningMessage!);
      return;
    }

    if (result.hasMessage) {
      _showSnack(result.message);
    }
  }

  void _showInvalidPhotoWarning(String warningMessage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Foto tidak sesuai'),
          content: Text(warningMessage),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF315A39),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemoveImage(WasteItem item, XFile image) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus foto?'),
          content: const Text('Foto akan dihapus. Lanjutkan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF315A39),
              ),
              onPressed: () {
                _viewModel.removeImage(item, image);
                Navigator.of(context).pop();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemoveWaste(WasteItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus jenis sampah?'),
          content: Text('Hapus "${item.name}" dari daftar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF315A39),
              ),
              onPressed: () {
                _viewModel.removeWasteItem(item);
                Navigator.of(context).pop();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted || message.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isWeightInvalid(WasteItem item) {
    final raw = item.weightController.text.replaceAll(',', '.').trim();
    if (raw.isEmpty) return false;
    final weight = double.tryParse(raw);
    return weight == null || weight < 1;
  }

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
