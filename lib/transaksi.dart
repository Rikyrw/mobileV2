import 'package:flutter/material.dart';

import 'dashboard.dart';
import 'viewmodels/transactions_view_model.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final TransaksiViewModel _viewModel = TransaksiViewModel();
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
        final dummyData = TransaksiViewModel.dummyData;
        final visibleTransactions = _viewModel.visibleTransactions;
        final hasTransactionData = visibleTransactions.isNotEmpty;
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
                                    : TransaksiViewModel.formatDate(
                                        TransaksiViewModel.formatDateQuery(
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
                                    : TransaksiViewModel.formatDate(
                                        TransaksiViewModel.formatDateQuery(
                                          _viewModel.toDate!,
                                        ),
                                      ),
                                onTap: () => _pickDate(isFrom: false),
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
                            child: const Text(
                              'Tampilkan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_viewModel.loadingTransaksi)
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
                        else if (!_viewModel.hasSearched && hasTransactionData)
                          Column(
                            children: [
                              ...visibleTransactions.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TransactionCard(item: item),
                                ),
                              ),
                              if (_viewModel.currentPage > 0 ||
                                  _viewModel.hasNextPage)
                                PaginationControls(
                                  currentPage: _viewModel.currentPage,
                                  hasNextPage: _viewModel.hasNextPage,
                                  isLoading: _viewModel.loadingTransaksi,
                                  onPrevious: _viewModel.loadPreviousPage,
                                  onNext: _viewModel.loadNextPage,
                                ),
                            ],
                          )
                        else if (!_viewModel.hasSearched)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'Belum ada transaksi pending.',
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
                        else if (hasTransactionData)
                          Column(
                            children: [
                              ...visibleTransactions.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TransactionCard(item: item),
                                ),
                              ),
                              if (_viewModel.currentPage > 0 ||
                                  _viewModel.hasNextPage)
                                PaginationControls(
                                  currentPage: _viewModel.currentPage,
                                  hasNextPage: _viewModel.hasNextPage,
                                  isLoading: _viewModel.loadingTransaksi,
                                  onPrevious: _viewModel.loadPreviousPage,
                                  onNext: _viewModel.loadNextPage,
                                ),
                            ],
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'Belum ada transaksi PPOB.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
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
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.item});

  final TransaksiItem item;

  @override
  Widget build(BuildContext context) {
    final statusValue = item.status.toLowerCase();
    final isSuccess =
        statusValue == 'berhasil' ||
        statusValue == 'approved' ||
        statusValue == 'sukses';
    final statusBackground = isSuccess
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);
    final statusTextColor = isSuccess
        ? const Color(0xFF2E7D32)
        : const Color(0xFFF57C00);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.target} - ${item.transactionId}',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.date,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 11,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.amount,
                style: const TextStyle(
                  color: Color(0xFF315A39),
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 11,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
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
