import 'package:flutter/material.dart';

/// Badge widget moderno para mostrar contadores en los tabs
class ModernBadge extends StatelessWidget {
  final int count;
  final bool isDot;
  final Color color;

  const ModernBadge({
    required this.count,
    this.isDot = false,
    this.color = const Color(0xFF830A09),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    if (isDot) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// TabBar de 3 pestañas consolidadas: En espera / En proceso / Finalizados
class ModernTabBar extends StatelessWidget {
  final TabController controller;
  final int waitCount;       // available + offer combinados
  final int inProgressCount;
  final int completedCount;  // completed + cancelled combinados
  final Color mainColor;

  const ModernTabBar({
    super.key,
    required this.controller,
    required this.waitCount,
    required this.inProgressCount,
    required this.completedCount,
    this.mainColor = const Color(0xFF830A09),
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: false,
      indicator: BoxDecoration(
        color: mainColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      labelColor: mainColor,
      unselectedLabelColor: Colors.grey,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      tabs: [
        _buildTab(
          icon: Icons.hourglass_empty_rounded,
          text: 'En espera',
          count: waitCount,
        ),
        _buildTab(
          icon: Icons.construction_rounded,
          text: 'En proceso',
          count: inProgressCount,
        ),
        _buildTab(
          icon: Icons.check_circle_outline_rounded,
          text: 'Finalizados',
          count: completedCount,
        ),
      ],
    );
  }

  Tab _buildTab({required IconData icon, required String text, required int count}) {
    return Tab(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final double iconSize = width > 90 ? 24 : 20;
          final double fontSize = width > 90 ? 13 : 11;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(clipBehavior: Clip.none, children: [
                Icon(icon, size: iconSize),
                if (count > 0)
                  const Positioned(
                    right: -2,
                    top: -2,
                    child: ModernBadge(count: 1, isDot: true),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fontSize, height: 1.1),
              ),
            ],
          );
        },
      ),
    );
  }
}