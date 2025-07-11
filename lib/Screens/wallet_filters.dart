import 'package:flutter/material.dart';

class WalletFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedStatus;
  final DateTimeRange? selectedDateRange;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;

  const WalletFilters({
    Key? key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedDateRange,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2022),
                lastDate: DateTime.now(),
                initialDateRange: selectedDateRange,
              );
              onDateRangeChanged(picked);
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: const Text('Fechas'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      cursorColor: Colors.black,
      decoration: InputDecoration(
        labelText: 'Buscar por ID o cliente',
        labelStyle: const TextStyle(color: Colors.black),
        prefixIcon: const Icon(Icons.search, color: Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black),
        ),
      ),
      style: const TextStyle(color: Colors.black),
      onChanged: onSearchChanged,
    );
  }
}
