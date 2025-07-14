import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WalletIncomeList extends StatelessWidget {
  final List<double> ingresos;
  final List<QueryDocumentSnapshot> services;
  final String selectedIncomePeriod;
  final Map<String, double> monthlyIncome;
  final double totalIncome;
  final double averageIncome;
  final double bestMonthIncome;
  final String bestMonth;
  final void Function(String?) onPeriodChanged;
  final void Function(Map<String, dynamic>) onShowIncomeDetails;

  const WalletIncomeList({
    Key? key,
    required this.ingresos,
    required this.services,
    required this.selectedIncomePeriod,
    required this.monthlyIncome,
    required this.totalIncome,
    required this.averageIncome,
    required this.bestMonthIncome,
    required this.bestMonth,
    required this.onPeriodChanged,
    required this.onShowIncomeDetails,
  }) : super(key: key);

  Widget buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Selector de período
    Widget buildPeriodSelector() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: Color(0xFF84090D), size: 20),
            const SizedBox(width: 8),
            const Text('Período:',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF84090D))),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String>(
                value: selectedIncomePeriod,
                isExpanded: true,
                underline: Container(),
                items: const [
                  DropdownMenuItem(value: '3', child: Text('Últimos 3 meses')),
                  DropdownMenuItem(value: '6', child: Text('Últimos 6 meses')),
                  DropdownMenuItem(
                      value: '12', child: Text('Últimos 12 meses')),
                ],
                onChanged: onPeriodChanged,
              ),
            ),
          ],
        ),
      );
    }

    // Estadísticas principales
    Widget buildIncomeStatistics() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  buildStatCard(
                    'Total',
                    'Bs ${totalIncome.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: buildStatCard(
                          'Promedio',
                          'Bs ${averageIncome.toStringAsFixed(2)}',
                          Icons.trending_up,
                          const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: buildStatCard(
                          'Mejor mes',
                          bestMonth.isNotEmpty ? bestMonth : 'N/A',
                          Icons.star,
                          const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: buildStatCard(
                    'Total',
                    'Bs ${totalIncome.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buildStatCard(
                    'Promedio',
                    'Bs ${averageIncome.toStringAsFixed(2)}',
                    Icons.trending_up,
                    const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buildStatCard(
                    'Mejor mes',
                    bestMonth.isNotEmpty ? bestMonth : 'N/A',
                    Icons.star,
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    Widget buildMonthlyChart() {
      if (monthlyIncome.isEmpty) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'No hay datos de ingresos para mostrar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        );
      }
      final monthsWithIncome =
          monthlyIncome.entries.where((entry) => entry.value > 0).toList();
      if (monthsWithIncome.isEmpty) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'No hay ingresos registrados en este período',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        );
      }
      final maxIncome =
          monthsWithIncome.map((e) => e.value).reduce((a, b) => a > b ? a : b);
      final sortedMonths = monthsWithIncome.map((e) => e.key).toList()..sort();
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFF84090D)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Historial de Ingresos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF84090D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxWidth < 400 ? 100.0 : 120.0;
                final barWidth = constraints.maxWidth < 400 ? 16.0 : 20.0;
                return SizedBox(
                  height: chartHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: sortedMonths.map((month) {
                      final income = monthlyIncome[month] ?? 0.0;
                      if (income <= 0) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    width: barWidth,
                                    color: Colors.transparent,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat('MMM', 'es').format(
                                      DateFormat('MMM yyyy', 'es')
                                          .parse(month)),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[400],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'Bs0',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[400],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final height = maxIncome > 0 ? (income / maxIncome) : 0.0;
                      final isCurrentMonth = month ==
                          DateFormat('MMM yyyy', 'es').format(DateTime.now());
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: barWidth,
                                  decoration: BoxDecoration(
                                    color: isCurrentMonth
                                        ? const Color(0xFF84090D)
                                        : const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.bottomCenter,
                                    heightFactor: height,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isCurrentMonth
                                            ? const Color(0xFF84090D)
                                            : const Color(0xFF4CAF50),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('MMM', 'es').format(
                                    DateFormat('MMM yyyy', 'es').parse(month)),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Bs${income.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF84090D),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    Widget buildIncomeTransactionsList() {
      if (services.isEmpty) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No hay transacciones de ingresos',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Transacciones (${services.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF84090D),
                ),
              ),
            ),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: services.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final service = services[index];
                  final commission = service['commission'] ?? 0.0;
                  final offeredPrice = service['offeredPrice'] ?? 0.0;
                  final netIncome = offeredPrice - commission;
                  final serviceId = service['serviceId'] ?? 'Sin ID';
                  final status = service['status'] ?? 'Desconocido';
                  final createdAtData = service['createdAt'];
                  DateTime createdAt;
                  if (createdAtData is Timestamp) {
                    createdAt = createdAtData.toDate();
                  } else if (createdAtData is String) {
                    createdAt =
                        DateTime.tryParse(createdAtData) ?? DateTime.now();
                  } else if (createdAtData is Map &&
                      createdAtData['_seconds'] != null) {
                    createdAt = DateTime.fromMillisecondsSinceEpoch(
                      (createdAtData['_seconds'] as int) * 1000,
                    );
                  } else {
                    createdAt = DateTime.now();
                  }
                  final isNew =
                      DateTime.now().difference(createdAt).inMinutes < 10;
                  final monthName =
                      DateFormat('MMM yyyy', 'es').format(createdAt);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: Color(0xFF4CAF50),
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Bs${netIncome.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                          if (isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE8E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NUEVO',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF84090D),
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10),
                          ),
                          Text(
                            'Mes: $monthName',
                            style: const TextStyle(
                              color: Color(0xFF84090D),
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'INGRESO',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => onShowIncomeDetails(
                          service.data() as Map<String, dynamic>),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          buildPeriodSelector(),
          buildIncomeStatistics(),
          buildMonthlyChart(),
          buildIncomeTransactionsList(),
        ],
      ),
    );
  }
}
