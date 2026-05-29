import 'package:flutter/material.dart';
import 'package:mob_2/email_verification_notice.dart';
import 'package:mob_2/viewmodels/dashboard_view_model.dart';
import 'package:mob_2/widgets/greenpoint_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardViewModel _viewModel = DashboardViewModel();
  bool _profileLoadRequested = false;

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileLoadRequested) {
      _profileLoadRequested = true;
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    final redirect = await _viewModel.loadUserProfile(
      emailArgument: _routeEmailArgument,
    );
    _handleVerificationRedirect(redirect);
  }

  Future<void> _refreshDashboard() async {
    final redirect = await _viewModel.refreshDashboard(
      emailArgument: _routeEmailArgument,
    );
    _handleVerificationRedirect(redirect);
  }

  void _handleVerificationRedirect(DashboardVerificationRedirect? redirect) {
    if (!mounted || redirect == null) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            EmailVerificationNoticeScreen(email: redirect.email),
      ),
    );
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
        final viewModel = _viewModel;
        final stats = viewModel.stats;
        final saldoText = viewModel.saldoText;
        final level = viewModel.level;
        final progress = viewModel.monthlyWeightProgress;
        final recentSetor = viewModel.recentSetor;
        final recentPpob = viewModel.recentPpob;

        return ColoredBox(
          color: Colors.white,
          child: RefreshIndicator(
            color: const Color(0xFF315A39),
            backgroundColor: Colors.white,
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GreenPointHeader(
                      eyebrow: DashboardViewModel.greeting,
                      title: viewModel.userName,
                      subtitle: 'Siap setor sampah hari ini?',
                      metaText: viewModel.currentDateText,
                      avatarText: viewModel.userName,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 20,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            DashboardViewModel.welcomeMessage,
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (viewModel.loadingDashboard)
                            const LinearProgressIndicator(
                              minHeight: 3,
                              color: Color(0xFF315A39),
                              backgroundColor: Color(0xFFE8F5E9),
                            ),
                          if (viewModel.loadingDashboard)
                            const SizedBox(height: 17),
                          _DashboardHeroBalance(
                            saldoText: saldoText,
                            level: level,
                            monthWeight: DashboardViewModel.formatWeight(
                              stats.totalWeightKg,
                            ),
                            onTopup: _openTopupSaldo,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _DashboardQuickAction(
                                  label: 'E-Money',
                                  icon: Icons.account_balance_wallet_rounded,
                                  onTap: _openEmoney,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DashboardQuickAction(
                                  label: 'PLN',
                                  icon: Icons.bolt_rounded,
                                  onTap: _openPln,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DashboardQuickAction(
                                  label: 'Pulsa',
                                  icon: Icons.phone_android_rounded,
                                  onTap: _openPulsa,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _DashboardMonthlySummaryCard(
                            totalWeightText: DashboardViewModel.formatWeight(
                              stats.totalWeightKg,
                            ),
                            targetWeightText: DashboardViewModel.formatWeight(
                              DashboardViewModel.monthlyWeightTargetKg,
                            ),
                            saldoMasukText: DashboardViewModel.formatRupiah(
                              stats.completedSetorValue,
                            ),
                            ppobAmountText: DashboardViewModel.formatRupiah(
                              stats.ppobAmount,
                            ),
                            progress: progress,
                            setorCount: stats.setorCount,
                            ppobCount: stats.ppobCount,
                            onRiwayat: _openRiwayat,
                            onTransaksi: _openTransaksi,
                          ),
                          const SizedBox(height: 14),
                          _DashboardSetorStatusCard(
                            waitingCount: stats.waitingSetorCount,
                            completedCount: stats.completedSetorCount,
                            rejectedCount: stats.rejectedSetorCount,
                          ),
                          const SizedBox(height: 14),
                          _DashboardLatestActivityCard(
                            setor: recentSetor.isEmpty
                                ? null
                                : recentSetor.first,
                            ppob: recentPpob.isEmpty ? null : recentPpob.first,
                            onRiwayat: _openRiwayat,
                            onTransaksi: _openTransaksi,
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

  Object? get _routeArguments {
    return _viewModel.routeArguments;
  }

  void _openRiwayat() {
    Navigator.of(
      context,
    ).pushReplacementNamed('/riwayat', arguments: _routeArguments);
  }

  void _openTransaksi() {
    Navigator.of(
      context,
    ).pushReplacementNamed('/transaksi', arguments: _routeArguments);
  }

  void _openTopupSaldo() {
    Navigator.of(context).pushNamed('/topup-saldo', arguments: _routeArguments);
  }

  void _openEmoney() {
    Navigator.of(context).pushNamed('/emoney', arguments: _routeArguments);
  }

  void _openPln() {
    Navigator.of(context).pushNamed('/pln', arguments: _routeArguments);
  }

  void _openPulsa() {
    Navigator.of(context).pushNamed('/pulsa', arguments: _routeArguments);
  }
}

class _DashboardHeroBalance extends StatelessWidget {
  const _DashboardHeroBalance({
    required this.saldoText,
    required this.level,
    required this.monthWeight,
    required this.onTopup,
  });

  final String saldoText;
  final String level;
  final String monthWeight;
  final VoidCallback onTopup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF315A39),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF315A39).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Saldo Saat Ini',
                  style: TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontSize: 13,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              saldoText,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      color: Color(0xFFBFE6C6),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$monthWeight bulan ini',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8F5E9),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: onTopup,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Top Up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF315A39),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardQuickAction extends StatelessWidget {
  const _DashboardQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4EAE4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF315A39), size: 24),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 12,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMonthlySummaryCard extends StatelessWidget {
  const _DashboardMonthlySummaryCard({
    required this.totalWeightText,
    required this.targetWeightText,
    required this.saldoMasukText,
    required this.ppobAmountText,
    required this.progress,
    required this.setorCount,
    required this.ppobCount,
    required this.onRiwayat,
    required this.onTransaksi,
  });

  final String totalWeightText;
  final String targetWeightText;
  final String saldoMasukText;
  final String ppobAmountText;
  final double progress;
  final int setorCount;
  final int ppobCount;
  final VoidCallback onRiwayat;
  final VoidCallback onTransaksi;

  @override
  Widget build(BuildContext context) {
    final progressPercent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE9D9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF315A39).withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF315A39),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Bulan Ini',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 15,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pantau setor dan pemakaian saldo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF68756B),
                        fontSize: 11,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$progressPercent%',
                  style: const TextStyle(
                    color: Color(0xFF8A5B00),
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DashboardHighlightStat(
                  label: 'Sampah',
                  value: totalWeightText,
                  caption: 'Target $targetWeightText',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardHighlightStat(
                  label: 'Saldo Masuk',
                  value: saldoMasukText,
                  caption: 'Dari setor selesai',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: const Color(0xFF315A39),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DashboardMiniActionStat(
                  icon: Icons.recycling_rounded,
                  label: 'Setor Sampah',
                  value: '$setorCount kali',
                  caption: 'Bulan ini',
                  onTap: onRiwayat,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardMiniActionStat(
                  icon: Icons.receipt_long_rounded,
                  label: 'PPOB',
                  value: '$ppobCount kali',
                  caption: ppobAmountText,
                  onTap: onTransaksi,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardHighlightStat extends StatelessWidget {
  const _DashboardHighlightStat({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2EAE1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF68756B),
              fontSize: 11,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF315A39),
                fontSize: 19,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7A867E),
              fontSize: 10,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMiniActionStat extends StatelessWidget {
  const _DashboardMiniActionStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF315A39), size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 11,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      caption ?? value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF315A39),
                        fontSize: 12,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF68756B),
                  fontSize: 10,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSetorStatusCard extends StatelessWidget {
  const _DashboardSetorStatusCard({
    required this.waitingCount,
    required this.completedCount,
    required this.rejectedCount,
  });

  final int waitingCount;
  final int completedCount;
  final int rejectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4EAE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Setor',
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 14,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DashboardStatusChip(
                  label: 'Menunggu',
                  value: waitingCount,
                  color: Color(0xFFB7791F),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DashboardStatusChip(
                  label: 'Selesai',
                  value: completedCount,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DashboardStatusChip(
                  label: 'Ditolak',
                  value: rejectedCount,
                  color: Color(0xFFB71C1C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardStatusChip extends StatelessWidget {
  const _DashboardStatusChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value.toString(),
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 21,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 11,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLatestActivityCard extends StatelessWidget {
  const _DashboardLatestActivityCard({
    required this.setor,
    required this.ppob,
    required this.onRiwayat,
    required this.onTransaksi,
  });

  final DashboardSetorPreview? setor;
  final DashboardPpobPreview? ppob;
  final VoidCallback onRiwayat;
  final VoidCallback onTransaksi;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4EAE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivitas Terbaru',
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 14,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _DashboardLatestActivityRow(
            icon: Icons.recycling_rounded,
            title: setor?.title ?? 'Setor Sampah',
            subtitle: setor?.subtitle ?? 'Belum ada transaksi setor',
            amount: setor?.amount ?? '-',
            date: setor?.date,
            onTap: onRiwayat,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 9),
            child: Divider(height: 1, color: Color(0xFFE4EAE4)),
          ),
          _DashboardLatestActivityRow(
            icon: Icons.receipt_long_rounded,
            title: ppob?.title ?? 'Transaksi PPOB',
            subtitle: ppob?.subtitle ?? 'Belum ada transaksi PPOB',
            amount: ppob?.amount ?? '-',
            date: ppob?.date,
            onTap: onTransaksi,
          ),
        ],
      ),
    );
  }
}

class _DashboardLatestActivityRow extends StatelessWidget {
  const _DashboardLatestActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.date,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final String? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF315A39), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 13,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A867E),
                        fontSize: 11,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 86,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF315A39),
                        fontSize: 12,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        date!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7A867E),
                          fontSize: 10,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF7A867E),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardBottomNavigation extends StatelessWidget {
  const DashboardBottomNavigation({
    super.key,
    this.items = _defaultItems,
    this.backgroundColor = const Color.fromARGB(255, 255, 255, 255),
    this.bottom = 0,
    this.fixedHeight,
    this.useSafeArea = true,
    this.safeAreaBottomSpacing = 8,
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
    ),
    this.elevation = 8,
    this.paddingHorizontal = 4,
    this.marginHorizontal = 0,
  });

  static const List<BottomNavigationItemConfig> _defaultItems = [
    BottomNavigationItemConfig(
      iconAsset: 'assets/home11.png',
      label: 'Home',
      isActive: true,
      fallbackIcon: Icons.home,
    ),
    BottomNavigationItemConfig(
      iconAsset: 'assets/riwayat1.png',
      label: 'Transaksi',
      isActive: false,
      fallbackIcon: Icons.swap_horiz,
    ),
    BottomNavigationItemConfig(
      iconAsset: 'assets/chat_ai.png',
      label: 'Chat AI',
      isActive: false,
      fallbackIcon: Icons.smart_toy,
    ),
    BottomNavigationItemConfig(
      iconAsset: 'assets/history.png',
      label: 'Riwayat',
      isActive: false,
      fallbackIcon: Icons.history,
    ),
    BottomNavigationItemConfig(
      iconAsset: 'assets/person.png',
      label: 'Profil',
      isActive: false,
      fallbackIcon: Icons.person,
    ),
  ];

  final List<BottomNavigationItemConfig> items;
  final Color backgroundColor;
  final double bottom;
  final double? fixedHeight;
  final bool useSafeArea;
  final double safeAreaBottomSpacing;
  final BorderRadius borderRadius;
  final double elevation;
  final double paddingHorizontal;
  final double marginHorizontal;

  @override
  Widget build(BuildContext context) {
    // Get responsive screen dimensions
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Keep enough room for the active circular item without making the bar tall.
    final navHeight = fixedHeight ?? (screenHeight * 0.086).clamp(72.0, 84.0);

    // Responsive padding: larger padding on wider screens
    final responsivePaddingHorizontal = screenWidth > 600
        ? paddingHorizontal + 8
        : paddingHorizontal;

    // Responsive margin: add margin on tablets
    final responsiveMarginHorizontal = screenWidth > 600
        ? marginHorizontal + 16
        : marginHorizontal;

    final navBar = Container(
      margin: EdgeInsets.symmetric(horizontal: responsiveMarginHorizontal),
      height: navHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: elevation,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsivePaddingHorizontal,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            // Optional: Add subtle gradient for premium look
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor,
                backgroundColor.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: Row(
            children: items
                .map(
                  (item) => Expanded(
                    child: _BottomNavItem(
                      iconAsset: item.iconAsset,
                      label: item.label,
                      isActive: item.isActive,
                      fallbackIcon: item.fallbackIcon,
                      onTap: item.onTap,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );

    final navChild = useSafeArea
        ? SafeArea(
            top: false,
            minimum: EdgeInsets.only(bottom: safeAreaBottomSpacing),
            child: navBar,
          )
        : navBar;

    if (bottom <= 0) {
      return navChild;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: navChild,
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.iconAsset,
    required this.label,
    required this.isActive,
    required this.fallbackIcon,
    this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool isActive;
  final IconData fallbackIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth > 600;

    final activeBubbleSize = isTablet ? 48.0 : 42.0;
    final inactiveBubbleSize = isTablet ? 32.0 : 30.0;
    final bubbleSize = isActive ? activeBubbleSize : inactiveBubbleSize;

    final activeIconSize = isTablet ? 25.0 : 22.0;
    final inactiveIconSize = isTablet ? 23.0 : 21.0;
    final iconSize = isActive ? activeIconSize : inactiveIconSize;

    final activeFontSize = isTablet ? 12.5 : 10.8;
    final inactiveFontSize = isTablet ? 11.5 : 10.0;
    final fontSize = isActive ? activeFontSize : inactiveFontSize;

    final activeColor = const Color(0xFF254B2E);
    final inactiveColor = const Color(0xFFA8AFA8);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 72.0;

          return SizedBox(
            height: itemHeight,
            child: Center(
              child: AnimatedSlide(
                offset: isActive ? const Offset(0, -0.04) : Offset.zero,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      width: bubbleSize,
                      height: bubbleSize,
                      decoration: BoxDecoration(
                        color: isActive ? activeColor : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: Image.asset(
                            iconAsset,
                            key: ValueKey(iconAsset),
                            width: iconSize,
                            height: iconSize,
                            color: isActive ? Colors.white : inactiveColor,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              fallbackIcon,
                              size: iconSize,
                              color: isActive ? Colors.white : inactiveColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: isTablet ? 15 : 13,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isActive ? activeColor : inactiveColor,
                            height: 1,
                          ),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: isActive ? 16 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: activeColor.withValues(
                          alpha: isActive ? 0.9 : 0,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BottomNavigationItemConfig {
  const BottomNavigationItemConfig({
    required this.iconAsset,
    required this.label,
    required this.isActive,
    required this.fallbackIcon,
    this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool isActive;
  final IconData fallbackIcon;
  final VoidCallback? onTap;
}

class PaginationControls extends StatelessWidget {
  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.hasNextPage,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final bool hasNextPage;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final canGoBack = currentPage > 0 && !isLoading;
    final canGoNext = hasNextPage && !isLoading;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 42,
            child: OutlinedButton(
              onPressed: canGoBack ? onPrevious : null,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 42),
              ),
              child: const Icon(Icons.chevron_left_rounded, size: 22),
            ),
          ),
          Expanded(
            child: Text(
              'Halaman ${currentPage + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 13,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 42,
            child: ElevatedButton(
              onPressed: canGoNext ? onNext : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 42),
              ),
              child: const Icon(Icons.chevron_right_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
