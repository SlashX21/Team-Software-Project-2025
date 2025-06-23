import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import 'analysis/analysis_result_screen.dart';
import 'history/history_screen.dart';
import 'profile/profile_screen.dart';
import '../../domain/entities/product_analysis.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Logo Section
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // TODO: Add logo image when available
                      Icon(
                        Icons.eco,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Grocery Guardian',
                        style: AppStyles.logo,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your personal nutrition assistant',
                        style: AppStyles.bodyRegular.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Cards Section
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Scan Product Card
                    _buildActionCard(
                      context: context,
                      icon: Icons.qr_code_scanner,
                      title: 'Scan Product',
                      subtitle: 'Analyze ingredients and get health insights',
                      onTap: () {
                        // Navigate to analysis screen (which now includes scanning)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnalysisResultScreen(
                              productAnalysis: _getDemoProductAnalysis(),
                            ),
                          ),
                        );
                      },
                      isPrimary: true,
                    ),

                    // History Card
                    _buildActionCard(
                      context: context,
                      icon: Icons.history,
                      title: 'History',
                      subtitle: 'View your previous scans and analyses',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),

                    // Profile Card
                    _buildActionCard(
                      context: context,
                      icon: Icons.person_outline,
                      title: 'Profile',
                      subtitle: 'Manage your health preferences',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary 
                    ? AppColors.white.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isPrimary ? AppColors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.bodyBold.copyWith(
                      color: isPrimary ? AppColors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppStyles.bodyRegular.copyWith(
                      color: isPrimary 
                          ? AppColors.white.withOpacity(0.8)
                          : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isPrimary 
                  ? AppColors.white.withOpacity(0.7)
                  : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  // TODO: Remove this demo data when real scanning is implemented
  ProductAnalysis _getDemoProductAnalysis() {
    return ProductAnalysis(
      name: 'Sample Product',
      imageUrl: 'https://via.placeholder.com/300x200',
      ingredients: ['Water', 'Sugar', 'Natural Flavoring', 'Citric Acid'],
      detectedAllergens: ['May contain traces of nuts'],
    );
  }
}