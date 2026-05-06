import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'pages/home_page.dart';
import 'pages/library_page.dart';
import 'pages/ai_input_page.dart';
import 'pages/reminder_center_page.dart';
import 'pages/settings_page.dart';
import 'pages/ai_config_list_page.dart';
import 'pages/item_detail_page.dart';

/// 主应用
class GuoQilLeMeApp extends StatelessWidget {
  final GlobalKey<NavigatorState>? navigatorKey;

  const GuoQilLeMeApp({super.key, this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: '过期了么',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const MainNavigator(),
        routes: {
          '/ai-config': (context) => const AIConfigListPage(),
          '/item-detail': (context) {
            final itemId = ModalRoute.of(context)?.settings.arguments as String?;
            if (itemId != null) {
              return ItemDetailPage(itemId: itemId);
            }
            return const MainNavigator();
          },
        },
      ),
    );
  }
}

/// 主导航页面
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    LibraryPage(),
    AIInputPage(),
    ReminderCenterPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, '首页'),
              _buildNavItem(1, Icons.inventory_2_outlined, Icons.inventory_2_rounded, '物品库'),
              _buildAIButton(),
              _buildNavItem(3, Icons.notifications_outlined, Icons.notifications_rounded, '提醒'),
              _buildNavItem(4, Icons.settings_outlined, Icons.settings_rounded, '设置'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIButton() {
    final isSelected = _currentIndex == 2;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    AppColors.primary,
                    AppColors.primaryFixed,
                  ]
                : [
                    AppColors.primaryFixed,
                    AppColors.primary,
                  ],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha:0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.photo_camera_rounded,
          color: AppColors.onPrimary,
          size: 26,
        ),
      ),
    );
  }
}
