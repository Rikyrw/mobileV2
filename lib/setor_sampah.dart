import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetorSampahScreen extends StatefulWidget {
  const SetorSampahScreen({super.key});

  @override
  State<SetorSampahScreen> createState() => _SetorSampahScreenState();
}

class _SetorSampahScreenState extends State<SetorSampahScreen> {
  static const int _maxPhotosPerItem = 3;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  bool _showAjukanButton = false;
  final List<WasteItem> _wasteItems = [];
  final ImagePicker _picker = ImagePicker();

  static const _dummyData = SetorSampahDummyData(
    userName: 'User',
    saldo: 'Rp 0',
    totalHarga: 'Rp 0',
  );

  String? _fetchedUserName;
  String? _fetchedFullName;
  String? _fetchedAddress;
  bool _loadingProfile = false;
  String? _currentEmail;
  List<Map<String, dynamic>> _wasteTypes = [];
  bool _loadingWasteTypes = false;

  @override
  void initState() {
    super.initState();
    _loadWasteTypes();
    //a
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fetchedUserName == null && !_loadingProfile) {
      _loadUserName();
    }
  }

  Future<void> _loadUserName() async {
    setState(() => _loadingProfile = true);

    try {
      // Try to get email from route arguments (if provided)
      final args = ModalRoute.of(context)?.settings.arguments;
      String? emailArg;
      if (args is Map && args['email'] is String) {
        emailArg = args['email'] as String;
      }

      // Prefer route argument, otherwise use auth currentUser
      final user = Supabase.instance.client.auth.currentUser;
      final email = emailArg ?? user?.email;
      _currentEmail = email;

      if (email != null && email.isNotEmpty) {
        final res = await Supabase.instance.client
            .from('nasabah')
            .select('nama_lengkap,user_name,email,alamat')
            .eq('email', email)
            .limit(1);

        if (res.isNotEmpty) {
          final record = res.first;
          final fullName = record['nama_lengkap'] as String?;
          final userName = record['user_name'] as String?;
          final address = record['alamat'] as String?;
          setState(() {
            _fetchedUserName = fullName ?? userName;
            _fetchedFullName = fullName;
            _fetchedAddress = address;
          });
          if (_namaController.text.trim().isEmpty) {
            final nameToUse = fullName ?? userName;
            if (nameToUse != null && nameToUse.isNotEmpty) {
              _namaController.text = nameToUse;
            }
          }
          if (_alamatController.text.trim().isEmpty) {
            if (address != null && address.isNotEmpty) {
              _alamatController.text = address;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Load user name error: $e');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadWasteTypes() async {
    setState(() => _loadingWasteTypes = true);

    try {
      final res = await Supabase.instance.client
          .from('jenis_sampah')
          .select('nama_jenis, harga_per_kg');

      setState(() {
        _wasteTypes = res.map((e) => {
          'name': e['nama_jenis'] as String,
          'price': (e['harga_per_kg'] as num).toDouble()
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading waste types: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat jenis sampah')),
      );
    } finally {
      if (mounted) setState(() => _loadingWasteTypes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final senderName = _namaController.text.trim().isNotEmpty
        ? _namaController.text.trim()
        : (_fetchedFullName ?? _fetchedUserName ?? '');
    final senderAddress = _alamatController.text.trim().isNotEmpty
        ? _alamatController.text.trim()
        : (_fetchedAddress ?? '');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed('/profil', arguments: {'email': _currentEmail});
                                },
                                icon: const Icon(Icons.arrow_back),
                                iconSize: 24,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
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
                                _fetchedUserName ?? _dummyData.userName,
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
                      ),
                      const SizedBox(height: 16),
                      Container(
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
                              _dummyData.saldo,
                              style: const TextStyle(
                                color: Color(0xFF315A39),
                                fontSize: 24,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Data Pengirim',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 16,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
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
                      ),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Jenis Sampah',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 16,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.transparent,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            _showAddWasteDialog();
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: Color(0xFF315A39)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
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
                      ),
                      const SizedBox(height: 16),
                      if (_wasteItems.isNotEmpty)
                        Column(
                          children: _wasteItems.map((item) {
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
                                onChanged: (val) {
                                  item.selected = val ?? false;
                                  _updateShowAjukanButton();
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
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatRupiah(item.price.round()) + ' / kg',
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
                                              height: 36,
                                              child: TextField(
                                                  controller: item.weightController,
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  decoration: InputDecoration(
                                                    hintText: 'Berat (kg)',
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    border: const OutlineInputBorder(),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: ( () {
                                                          final raw = item.weightController.text.replaceAll(',', '.').trim();
                                                          final weight = double.tryParse(raw) ?? 0.0;
                                                          return (raw.isNotEmpty && weight < 1) ? Colors.red : const Color(0xFFE0E0E0);
                                                        } )(),
                                                      ),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: ( () {
                                                          final raw = item.weightController.text.replaceAll(',', '.').trim();
                                                          final weight = double.tryParse(raw) ?? 0.0;
                                                          return (raw.isNotEmpty && weight < 1) ? Colors.red : const Color(0xFF315A39);
                                                        } )(),
                                                        width: 2,
                                                      ),
                                                    ),
                                                    errorText: ( () {
                                                      final raw = item.weightController.text.replaceAll(',', '.').trim();
                                                      final weight = double.tryParse(raw);
                                                      if (raw.isNotEmpty && (weight == null || weight < 1)) return 'Minimal 1 kg';
                                                      return null;
                                                    } )(),
                                                  ),
                                                  onChanged: (_) {
                                                    _updateShowAjukanButton();
                                                  },
                                                ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('kg'),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            ...item.images.map((img) {
                                              return Stack(
                                                alignment: Alignment.topRight,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: kIsWeb
                                                        ? Image.network(
                                                            img.path,
                                                            width: 80,
                                                            height: 80,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Image.file(
                                                            File(img.path),
                                                            width: 80,
                                                            height: 80,
                                                            fit: BoxFit.cover,
                                                          ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      _confirmRemoveImage(item, img);
                                                    },
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
                                            }).toList(),
                                            if (item.selected && item.images.length < _maxPhotosPerItem)
                                              OutlinedButton.icon(
                                                onPressed: () => _showImageSourceOptions(item),
                                                icon: const Icon(Icons.camera_alt, size: 18, color: Color(0xFF315A39)),
                                                label: const Text('Tambah Foto', style: TextStyle(color: Color(0xFF315A39))),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Color(0xFF315A39)),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    secondary: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFBF360C)),
                                      onPressed: () {
                                        _confirmRemoveWaste(item);
                                      },
                                    ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 12),
                      Container(
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
                              _formatRupiah(_computeTotal()),
                              style: const TextStyle(
                                color: Color(0xFF315A39),
                                fontSize: 18,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF315A39),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
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
                      ),
                      const SizedBox(height: 12),
                      if (_showAjukanButton)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                            child: const Text(
                              'Ajukan Setor Sampah',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    for (var w in _wasteItems) {
      w.weightController.dispose();
    }
    super.dispose();
  }

  bool _hasValidSelection() {
    for (var w in _wasteItems) {
      if (w.selected) {
        final raw = w.weightController.text.replaceAll(',', '.').trim();
        final weight = double.tryParse(raw) ?? 0.0;
        if (weight >= 1) return true;
      }
    }
    return false;
  }

  void _updateShowAjukanButton() {
    setState(() {
      _showAjukanButton = _hasValidSelection();
    });
  }

  int _computeTotal() {
    double total = 0.0;
    for (var w in _wasteItems) {
      if (w.selected) {
        final raw = w.weightController.text.replaceAll(',', '.');
        final weight = double.tryParse(raw) ?? 0.0;
        if (weight >= 1) {
          total += w.price * weight;
        }
      }
    }
    return total.round();
  }

  String _formatRupiah(int value) {
    if (value == 0) return 'Rp 0';
    final s = value.toString();
    final reg = RegExp(r"\B(?=(\d{3})+(?!\d))");
    return 'Rp ' + s.replaceAllMapped(reg, (m) => '.');
  }

  void _showAddWasteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _loadingWasteTypes
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      const ListTile(
                        title: Text('Pilih Jenis Sampah'),
                      ),
                      ..._wasteTypes.map((p) {
                        return ListTile(
                          title: Text(p['name']),
                          subtitle: Text(_formatRupiah((p['price'] as double).round())),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showWeightDialogForPreset(p['name'], p['price']);
                          },
                        );
                      }).toList(),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _showWeightDialogForPreset(String name, double price) {
    final TextEditingController weightCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Berat untuk $name'),
          content: TextField(
            controller: weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Masukkan berat (kg), contoh: 1.5'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
                onPressed: () {
                final raw = weightCtrl.text.replaceAll(',', '.').trim();
                final w = double.tryParse(raw) ?? 0.0;
                if (w >= 1) {
                  setState(() {
                    final existing = _wasteItems.where((item) => item.name == name).toList();
                    if (existing.isNotEmpty) {
                      final item = existing.first;
                      final currentRaw = item.weightController.text.replaceAll(',', '.').trim();
                      final currentWeight = double.tryParse(currentRaw) ?? 0.0;
                      final newWeight = currentWeight + w;
                      item.weightController.text = newWeight.toString();
                      item.selected = true;
                    } else {
                      final item = WasteItem(name: name, price: price, selected: true);
                      item.weightController.text = raw;
                      _wasteItems.add(item);
                    }
                  });
                  _updateShowAjukanButton();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Minimal 1 kg.')),
                  );
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceOptions(WasteItem item) {
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
    try {
      if (item.images.length >= _maxPhotosPerItem) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maksimal $_maxPhotosPerItem foto per jenis sampah.')),
        );
        return;
      }
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
      if (picked != null) {
        setState(() => item.images.add(picked));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
    }
  }

  void _confirmRemoveImage(WasteItem item, XFile img) {
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF315A39)),
              onPressed: () {
                setState(() => item.images.remove(img));
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF315A39)),
              onPressed: () {
                setState(() {
                  _wasteItems.remove(item);
                });
                _updateShowAjukanButton();
                Navigator.of(context).pop();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

}

class SetorSampahDummyData {
  const SetorSampahDummyData({
    required this.userName,
    required this.saldo,
    required this.totalHarga,
  });

  final String userName;
  final String saldo;
  final String totalHarga;
}

class WasteItem {
  String name;
  double price; // in rupiah
  bool selected;
  final TextEditingController weightController;
  final List<XFile> images;

  WasteItem({
    required this.name,
    required this.price,
    this.selected = false,
    TextEditingController? weightController,
    List<XFile>? images,
  })  : weightController = weightController ?? TextEditingController(),
        images = images ?? [];
}