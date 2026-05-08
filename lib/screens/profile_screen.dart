import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';

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
          SliverAppBar(
            backgroundColor: AppTheme.bg,
            floating: true,
            elevation: 0,
            titleSpacing: 20,
            title: const Text(
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
                    width: 90,
                    height: 90,
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
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppTheme.textMid,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('Lid sinds', _memberSince(user)),
                        _divider(),
                        _statItem('Account', 'Actief'),
                        _divider(),
                        _statItem('Verificatie', 'E-mail'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu items
                  Container(
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      children: [
                        _menuItem(
                          Icons.notifications_outlined,
                          'Meldingen',
                          'Beheer je notificaties',
                          () {},
                        ),
                        _dividerH(),
                        _menuItem(
                          Icons.shield_outlined,
                          'Privacy',
                          'Bekijk ons privacybeleid',
                          () {},
                        ),
                        _dividerH(),
                        _menuItem(
                          Icons.help_outline_rounded,
                          'Help & support',
                          'Vragen of problemen?',
                          () {},
                        ),
                        _dividerH(),
                        _menuItem(
                          Icons.info_outline_rounded,
                          'Over BuurtLeen',
                          'Versie 1.0.0',
                          () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  AppButton(
                    label: 'Uitloggen',
                    outlined: true,
                    icon: Icons.logout_rounded,
                    onTap: () => auth.logout(),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Account verwijderen',
                    danger: true,
                    outlined: true,
                    icon: Icons.delete_outline_rounded,
                    onTap: () => _confirmDelete(context, auth),
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

  Widget _statItem(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(color: AppTheme.textLight, fontSize: 11),
      ),
    ],
  );

  Widget _divider() => Container(width: 1, height: 32, color: AppTheme.border);

  Widget _dividerH() =>
      const Divider(height: 1, color: AppTheme.border, indent: 56);

  Widget _menuItem(
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap,
  ) => ListTile(
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

  void _confirmDelete(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Account verwijderen?'),
        content: const Text('Dit kan niet ongedaan worden gemaakt.'),
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
