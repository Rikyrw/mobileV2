import 'package:flutter/material.dart';

import 'dashboard.dart';
import 'viewmodels/riwayat_view_model.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final RiwayatViewModel _viewModel = RiwayatViewModel();
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
      _viewModel.loadProfile(emailArgument: _routeEmailArgument);
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

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final lastAllowed = DateTime(now.year, now.month, now.day);
    final firstAllowed = lastAllowed.subtract(const Duration(days: 31));
    final initial = isFrom
        ? (_viewModel.fromDate ?? lastAllowed)
        : (_viewModel.toDate ?? lastAllowed);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstAllowed) ? firstAllowed : initial,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
    );

    if (picked == null) return;

    _viewModel.applyPickedDate(isFrom: isFrom, picked: picked);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final dummyData = RiwayatViewModel.dummyData;
        final visibleItems = _viewModel.visibleItems;
        final errorMessage = _viewModel.errorMessage;
        if (errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(errorMessage)));
            _viewModel.clearError();
          });
        }

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
                            dummyData.greeting,
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
                          _viewModel.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
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
                              const Text(
                                'Periode Mutasi',
                                style: TextStyle(
                                  color: Color(0xFF333333),
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Dari Tanggal:',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _DateField(
                                value: _viewModel.fromDate == null
                                    ? 'Pilih tanggal'
                                    : RiwayatViewModel.formatDate(
                                        RiwayatViewModel.formatDateQuery(
                                          _viewModel.fromDate!,
                                        ),
                                      ),
                                onTap: () => _pickDate(isFrom: true),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Sampai Tanggal:',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _DateField(
                                value: _viewModel.toDate == null
                                    ? 'Pilih tanggal'
                                    : RiwayatViewModel.formatDate(
                                        RiwayatViewModel.formatDateQuery(
                                          _viewModel.toDate!,
                                        ),
                                      ),
                                onTap: () => _pickDate(isFrom: false),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                dummyData.note,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 12,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: !_viewModel.canSearch
                                ? null
                                : () async {
                                    final message = _viewModel
                                        .validateSearchRange();
                                    if (message != null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(message)),
                                      );
                                      return;
                                    }
                                    await _viewModel.search();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF315A39),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              dummyData.buttonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_viewModel.loadingRiwayat)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                dummyData.emptyState,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          )
                        else if (!_viewModel.hasSearched &&
                            visibleItems.isNotEmpty)
                          Column(
                            children:
                                visibleItems.map<Widget>((item) {
                                  final details =
                                      item['details'] as List<dynamic>? ?? [];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    RiwayatViewModel.formatDate(
                                                      item['tanggal']
                                                          as String?,
                                                    ),
                                                    style: const TextStyle(
                                                      color: Color(0xFF333333),
                                                      fontSize: 14,
                                                      fontFamily: 'Roboto',
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Total ${RiwayatViewModel.formatRupiah((item['total'] as double).round())}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF666666),
                                                      fontSize: 12,
                                                      fontFamily: 'Roboto',
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              (item['status'] as String)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Color(0xFF315A39),
                                                fontSize: 12,
                                                fontFamily: 'Roboto',
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (details.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Column(
                                            children: details.map((d) {
                                              final name = (d['nama'] ?? '-')
                                                  .toString();
                                              final weight =
                                                  d['berat'] as double? ?? 0.0;
                                              final subtotal =
                                                  d['subtotal'] as double? ??
                                                  0.0;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '$name - ${RiwayatViewModel.formatWeight(weight)} kg',
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFF666666,
                                                          ),
                                                          fontSize: 12,
                                                          fontFamily: 'Roboto',
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      RiwayatViewModel.formatRupiah(
                                                        subtotal.round(),
                                                      ),
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF333333,
                                                        ),
                                                        fontSize: 12,
                                                        fontFamily: 'Roboto',
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList()..addAll([
                                  if (_viewModel.currentPage > 0 ||
                                      _viewModel.hasNextPage)
                                    PaginationControls(
                                      currentPage: _viewModel.currentPage,
                                      hasNextPage: _viewModel.hasNextPage,
                                      isLoading: _viewModel.loadingRiwayat,
                                      onPrevious: _viewModel.loadPreviousPage,
                                      onNext: _viewModel.loadNextPage,
                                    ),
                                ]),
                          )
                        else if (!_viewModel.hasSearched)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'Belum ada riwayat pending.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          )
                        else if (visibleItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'Belum ada riwayat setor sampah.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            children:
                                visibleItems.map<Widget>((item) {
                                  final details =
                                      item['details'] as List<dynamic>? ?? [];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    RiwayatViewModel.formatDate(
                                                      item['tanggal']
                                                          as String?,
                                                    ),
                                                    style: const TextStyle(
                                                      color: Color(0xFF333333),
                                                      fontSize: 14,
                                                      fontFamily: 'Roboto',
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Total ${RiwayatViewModel.formatRupiah((item['total'] as double).round())}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF666666),
                                                      fontSize: 12,
                                                      fontFamily: 'Roboto',
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              (item['status'] as String)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Color(0xFF315A39),
                                                fontSize: 12,
                                                fontFamily: 'Roboto',
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (details.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Column(
                                            children: details.map((d) {
                                              final name = (d['nama'] ?? '-')
                                                  .toString();
                                              final weight =
                                                  d['berat'] as double? ?? 0.0;
                                              final subtotal =
                                                  d['subtotal'] as double? ??
                                                  0.0;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '$name - ${RiwayatViewModel.formatWeight(weight)} kg',
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFF666666,
                                                          ),
                                                          fontSize: 12,
                                                          fontFamily: 'Roboto',
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      RiwayatViewModel.formatRupiah(
                                                        subtotal.round(),
                                                      ),
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF333333,
                                                        ),
                                                        fontSize: 12,
                                                        fontFamily: 'Roboto',
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList()..addAll([
                                  if (_viewModel.currentPage > 0 ||
                                      _viewModel.hasNextPage)
                                    PaginationControls(
                                      currentPage: _viewModel.currentPage,
                                      hasNextPage: _viewModel.hasNextPage,
                                      isLoading: _viewModel.loadingRiwayat,
                                      onPrevious: _viewModel.loadPreviousPage,
                                      onNext: _viewModel.loadNextPage,
                                    ),
                                ]),
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
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }
}
