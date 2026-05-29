import 'package:flutter/material.dart';

import 'perbarui_profil.dart';
import 'viewmodels/profile_view_model.dart';
import 'widgets/greenpoint_header.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ProfileViewModel _viewModel = ProfileViewModel();
  bool _profileLoadRequested = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileLoadRequested) {
      _profileLoadRequested = true;
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _loadProfile({bool forceRefresh = false}) {
    return _viewModel.loadProfile(
      emailArgument: _routeEmailArgument,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> _refreshProfile() {
    return _loadProfile(forceRefresh: true);
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
        final dummyData = ProfileViewModel.dummyData;
        final viewModel = _viewModel;

        return ColoredBox(
          color: Colors.white,
          child: RefreshIndicator(
            color: const Color(0xFF315A39),
            backgroundColor: Colors.white,
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GreenPointHeader(
                      eyebrow: dummyData.greeting,
                      title: viewModel.userName,
                      subtitle: 'Kelola akun Green Point',
                      avatarText: viewModel.userName,
                      trailing: GreenPointHeaderIconButton(
                        icon: Icons.logout_rounded,
                        tooltip: 'Keluar',
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Konfirmasi'),
                              content: const Text(
                                'Apakah Anda yakin ingin keluar?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Keluar'),
                                ),
                              ],
                            ),
                          );

                          if (shouldLogout == true) {
                            await _viewModel.signOut();
                            if (!mounted) return;
                            navigator.pushNamedAndRemoveUntil(
                              '/welcome',
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dummyData.title,
                            style: const TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 20,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dummyData.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  viewModel.fullName,
                                  style: const TextStyle(
                                    color: Color(0xFF333333),
                                    fontSize: 18,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  viewModel.username,
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Saldo',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 14,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      viewModel.saldo,
                                      style: const TextStyle(
                                        color: Color(0xFF315A39),
                                        fontSize: 16,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Alamat',
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  viewModel.address,
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 12,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Email',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 14,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        viewModel.email,
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          color: Color(0xFF333333),
                                          fontSize: 14,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Expanded(
                                      flex: 2,
                                      child: Text(
                                        'No HP',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 14,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        viewModel.phone,
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          color: Color(0xFF333333),
                                          fontSize: 14,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _profileActionButton(
                                  icon: Icons.edit_outlined,
                                  title: 'Perbarui Profil',
                                  subtitle: 'Ubah data diri dan kontak',
                                  accentColor: const Color(0xFF315A39),
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PerbaruiProfilScreen(
                                                  userData: viewModel
                                                      .editableUserData,
                                                ),
                                          ),
                                        )
                                        .then((result) {
                                          if (result == true) {
                                            _loadProfile(forceRefresh: true);
                                          }
                                        });
                                  },
                                ),
                                const SizedBox(height: 85),
                                _profileActionButton(
                                  icon: Icons.recycling,
                                  title: 'Setor Sampah',
                                  subtitle: 'Ajukan setoran baru',
                                  accentColor: const Color(0xFF315A39),
                                  isPrimary: true,
                                  onTap: () async {
                                    final result = await Navigator.of(context)
                                        .pushNamed(
                                          '/setor-sampah',
                                          arguments: viewModel.routeArguments,
                                        );
                                    if (!mounted) return;
                                    if (result == true) {
                                      _loadProfile(forceRefresh: true);
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                _profileActionButton(
                                  icon: Icons.account_balance_wallet_outlined,
                                  title: 'Top Up Saldo',
                                  subtitle: 'Isi saldo untuk transaksi',
                                  accentColor: const Color(0xFFB26A00),
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      '/topup-saldo',
                                      arguments: viewModel.routeArguments,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _profileActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    const radius = 10.0;
    final titleColor = isPrimary ? Colors.white : const Color(0xFF26362B);
    final subtitleColor = isPrimary
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF68736B);
    final iconBackground = isPrimary
        ? Colors.white.withValues(alpha: 0.18)
        : accentColor.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? const Color(0x33315A39)
                : const Color(0x14000000),
            blurRadius: isPrimary ? 18 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: isPrimary ? null : Colors.white,
            gradient: isPrimary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF315A39), Color(0xFF39744B)],
                  )
                : null,
            borderRadius: BorderRadius.circular(radius),
            border: isPrimary
                ? null
                : Border.all(color: const Color(0xFFDCE6DE), width: 1.1),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isPrimary ? Colors.white : accentColor,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.9)
                          : accentColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
