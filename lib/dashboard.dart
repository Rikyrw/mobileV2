import 'package:flutter/material.dart';
import 'package:mob_2/email_verification_notice.dart';
import 'package:mob_2/viewmodels/dashboard_view_model.dart';

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

        return ColoredBox(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20,
                      40,
                      20,
                      30,
                    ),
                    decoration: const BoxDecoration(color: Color(0xFF315A39)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Opacity(
                          opacity: 0.8,
                          child: Text(
                            DashboardViewModel.greeting,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          viewModel.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Opacity(
                          opacity: 0.8,
                          child: Text(
                            viewModel.currentDateText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                          children: [
                            _DashboardMetricCard(
                              title: 'Setor Bulan Ini',
                              value: stats.setorCount.toString(),
                              caption: 'Transaksi',
                              icon: Icons.recycling_outlined,
                              onTap: _openRiwayat,
                            ),
                            _DashboardMetricCard(
                              title: 'Berat Bulan Ini',
                              value: DashboardViewModel.formatWeight(
                                stats.totalWeightKg,
                              ),
                              caption: 'Total sampah',
                              icon: Icons.scale_outlined,
                              onTap: _openRiwayat,
                            ),
                            _DashboardMetricCard(
                              title: 'Saldo Masuk',
                              value: DashboardViewModel.formatRupiah(
                                stats.completedSetorValue,
                              ),
                              caption: 'Dari setor selesai',
                              icon: Icons.savings_outlined,
                              onTap: _openRiwayat,
                            ),
                            _DashboardMetricCard(
                              title: 'PPOB Bulan Ini',
                              value: DashboardViewModel.formatRupiah(
                                stats.ppobAmount,
                              ),
                              caption: '${stats.ppobCount} transaksi',
                              icon: Icons.receipt_long_outlined,
                              onTap: _openTransaksi,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _DashboardImpactCard(
                          currentWeightText: DashboardViewModel.formatWeight(
                            stats.totalWeightKg,
                          ),
                          targetWeightText: DashboardViewModel.formatWeight(
                            DashboardViewModel.monthlyWeightTargetKg,
                          ),
                          progress: progress,
                        ),
                        const SizedBox(height: 24),
                        const _DashboardSectionTitle(
                          title: 'Ringkasan Bulan Ini',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8F6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE4EAE4)),
                          ),
                          child: Column(
                            children: [
                              _DashboardSummaryRow(
                                label: 'Setor bulan ini',
                                value: '${stats.setorCount} transaksi',
                              ),
                              _DashboardSummaryRow(
                                label: 'Total berat bulan ini',
                                value: DashboardViewModel.formatWeight(
                                  stats.totalWeightKg,
                                ),
                              ),
                              _DashboardSummaryRow(
                                label: 'Saldo masuk dari setor',
                                value: DashboardViewModel.formatRupiah(
                                  stats.completedSetorValue,
                                ),
                              ),
                              _DashboardSummaryRow(
                                label: 'PPOB bulan ini',
                                value: DashboardViewModel.formatRupiah(
                                  stats.ppobAmount,
                                ),
                              ),
                              if (stats.withdrawalCount > 0)
                                _DashboardSummaryRow(
                                  label: 'Penarikan saldo',
                                  value:
                                      '${DashboardViewModel.formatRupiah(stats.withdrawalAmount)} (${stats.withdrawalCount})',
                                  isLast: true,
                                )
                              else
                                const _DashboardSummaryRow(
                                  label: 'Penarikan saldo',
                                  value: 'Belum ada',
                                  isLast: true,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _DashboardSectionTitle(title: 'Status Setor'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DashboardStatusTile(
                                label: 'Menunggu',
                                value: stats.waitingSetorCount,
                                color: const Color(0xFFB7791F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DashboardStatusTile(
                                label: 'Selesai',
                                value: stats.completedSetorCount,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DashboardStatusTile(
                                label: 'Ditolak',
                                value: stats.rejectedSetorCount,
                                color: const Color(0xFFB71C1C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _DashboardRecentSection(
                          title: 'Transaksi Setor Terbaru',
                          emptyText: 'Belum ada transaksi setor.',
                          onTap: _openRiwayat,
                          children: viewModel.recentSetor
                              .map(
                                (item) => _DashboardRecentTile(
                                  title: item.title,
                                  subtitle: item.subtitle,
                                  amount: item.amount,
                                  date: item.date,
                                  icon: Icons.recycling_rounded,
                                  onTap: _openRiwayat,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        _DashboardRecentSection(
                          title: 'Transaksi PPOB Terbaru',
                          emptyText: 'Belum ada transaksi PPOB.',
                          onTap: _openTransaksi,
                          children: viewModel.recentPpob
                              .map(
                                (item) => _DashboardRecentTile(
                                  title: item.title,
                                  subtitle: item.subtitle,
                                  amount: item.amount,
                                  date: item.date,
                                  icon: Icons.receipt_long_rounded,
                                  onTap: _openTransaksi,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
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
    Navigator.of(
      context,
    ).pushReplacementNamed('/topup-saldo', arguments: _routeArguments);
  }

  void _openEmoney() {
    Navigator.of(
      context,
    ).pushReplacementNamed('/emoney', arguments: _routeArguments);
  }

  void _openPln() {
    Navigator.of(
      context,
    ).pushReplacementNamed('/pln', arguments: _routeArguments);
  }

  void _openPulsa() {
    Navigator.of(
      context,
    ).pushReplacementNamed('/pulsa', arguments: _routeArguments);
  }
}

class _DashboardSectionTitle extends StatelessWidget {
  const _DashboardSectionTitle({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onTap != null)
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.chevron_right_rounded),
            color: const Color(0xFF315A39),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
      ],
    );
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

class _DashboardImpactCard extends StatelessWidget {
  const _DashboardImpactCard({
    required this.currentWeightText,
    required this.targetWeightText,
    required this.progress,
  });

  final String currentWeightText;
  final String targetWeightText;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9EADB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF315A39),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Dampak Lingkungan',
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$currentWeightText sampah terkumpul bulan ini',
            style: const TextStyle(
              color: Color(0xFF315A39),
              fontSize: 17,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              color: const Color(0xFF315A39),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Target bulanan $targetWeightText',
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4EAE4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF7A867E),
                      size: 20,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7A867E),
                  fontSize: 11,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSummaryRow extends StatelessWidget {
  const _DashboardSummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 13,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE4EAE4)),
          ),
      ],
    );
  }
}

class _DashboardStatusTile extends StatelessWidget {
  const _DashboardStatusTile({
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
      height: 78,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
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
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 12,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardRecentSection extends StatelessWidget {
  const _DashboardRecentSection({
    required this.title,
    required this.emptyText,
    required this.children,
    required this.onTap,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardSectionTitle(title: title, onTap: onTap),
        const SizedBox(height: 12),
        if (children.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4EAE4)),
            ),
            child: Text(
              emptyText,
              style: const TextStyle(
                color: Color(0xFF7A867E),
                fontSize: 13,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
              ),
            ),
          )
        else
          Column(children: children),
      ],
    );
  }
}

class _DashboardRecentTile extends StatelessWidget {
  const _DashboardRecentTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4EAE4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF315A39), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7A867E),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF315A39),
                        fontSize: 13,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Color(0xFF7A867E),
                        fontSize: 11,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF7A867E),
                ),
              ],
            ),
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

    // Responsive height: 7-9% of screen height, with min 56 and max 80
    final navHeight = fixedHeight ?? (screenHeight * 0.08).clamp(56.0, 80.0);

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

// Optional: Enhanced _BottomNavItem with responsive sizing
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

    // Responsive icon size
    final iconSize = isTablet ? 28.0 : 24.0;

    // Responsive font size
    final fontSize = isTablet ? 14.0 : 12.0;

    // Active color - you can customize this
    final activeColor = const Color.fromARGB(255, 33, 90, 36);
    final inactiveColor = const Color.fromARGB(255, 187, 186, 186);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Image.asset(
                iconAsset,
                key: ValueKey(iconAsset),
                width: iconSize,
                height: iconSize,
                color: isActive ? activeColor : inactiveColor,
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  size: iconSize,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Label with animation
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
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
