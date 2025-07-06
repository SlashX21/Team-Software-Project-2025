import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import 'analysis/analysis_result_screen.dart';
import 'history/history_record_page.dart';
import 'sugar_tracking/sugar_tracking_page.dart';
import 'monthly_overview/monthly_overview_screen.dart';
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
                child: SingleChildScrollView(
                  child: Column(
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
                    SizedBox(height: 16),

                    // Sugar Tracking Card
                    _buildActionCard(
                      context: context,
                      icon: Icons.monitor_heart,
                      title: 'Sugar Tracking',
                      subtitle: 'Monitor your daily sugar intake',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SugarTrackingPage(),
                          ),
                        );
                      },
                    ),
                    
                    // Analytics Section
                    SizedBox(height: 24),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.analytics_outlined, 
                               size: 20, 
                               color: AppColors.textLight),
                          SizedBox(width: 8),
                          Text(
                            'Analytics & Insights',
                            style: AppStyles.bodyBold.copyWith(
                              color: AppColors.textLight,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),

                    // Monthly Overview Card
                    _buildActionCard(
                      context: context,
                      icon: Icons.insights,
                      title: 'Monthly Overview',
                      subtitle: 'View your monthly nutrition insights',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MonthlyOverviewScreen(),
                          ),
                        );
                      },
                      isPrimary: false,
                      isHighlight: true,
                    ),
                    SizedBox(height: 16),

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
                            builder: (context) => HistoryRecordPage(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),

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
                    SizedBox(height: 20), // 底部间距
                  ],
                  ),
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
    bool isHighlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary 
              ? AppColors.primary 
              : isHighlight 
                  ? AppColors.primary.withOpacity(0.05)
                  : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: isHighlight 
              ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
              : null,
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
                    : AppColors.primary.withOpacity(isHighlight ? 0.2 : 0.1),
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