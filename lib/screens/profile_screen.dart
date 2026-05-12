import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            backgroundColor: AppTheme.bg,
            floating: true,
            elevation: 0,
            titleSpacing: 20,
            title: Text(
              'Mijn profiel',
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.greenLight, AppTheme.green],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.green.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppTheme.textMid,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Lid sinds badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.greenPale,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Lid sinds ${_memberSince(user)}',
                      style: const TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Menu
                  Container(
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      children: [
                        _menuItem(
                          icon: Icons.shield_outlined,
                          title: 'Privacy & voorwaarden',
                          sub: 'Bekijk ons beleid',
                          onTap: () => _infoDialog(
                            context,
                            'Privacy',
                            'BuurtLeen slaat alleen noodzakelijke gegevens op. Jouw data wordt nooit verkocht aan derden.',
                          ),
                        ),
                        const Divider(
                          height: 1,
                          color: AppTheme.border,
                          indent: 56,
                        ),
                        _menuItem(
                          icon: Icons.info_outline_rounded,
                          title: 'Over BuurtLeen',
                          sub: 'Versie 1.0.0',
                          onTap: () => _infoDialog(
                            context,
                            'Over BuurtLeen',
                            'BuurtLeen is een app om huishoudelijke toestellen te delen en te verhuren in je buurt. Geïnspireerd door Peerby.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Knoppen — compact, naast elkaar
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: 'Uitloggen',
                          icon: Icons.logout_rounded,
                          color: AppTheme.green,
                          onTap: () => auth.logout(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionButton(
                          label: 'Verwijderen',
                          icon: Icons.delete_outline_rounded,
                          color: AppTheme.red,
                          onTap: () => _confirmDelete(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _memberSince(User? user) {
    if (user?.metadata.creationTime == null) return '–';
    final d = user!.metadata.creationTime!;
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) => ListTile(
    onTap: onTap,
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.greenPale,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppTheme.green, size: 18),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppTheme.textDark,
      ),
    ),
    subtitle: Text(
      sub,
      style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
    ),
    trailing: const Icon(
      Icons.chevron_right,
      color: AppTheme.textLight,
      size: 18,
    ),
  );

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );

  void _infoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(content, style: const TextStyle(color: AppTheme.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Sluiten',
              style: TextStyle(color: AppTheme.green),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Account verwijderen?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Dit verwijdert je account permanent. Dit kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuleren',
              style: TextStyle(color: AppTheme.textMid),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.currentUser?.delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Verwijderen',
              style: TextStyle(color: AppTheme.red),
            ),
          ),
        ],
      ),
    );
  }
}
