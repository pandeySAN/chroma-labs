import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/page_transitions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../appointments/presentation/screens/appointment_list_screen.dart';
import '../../../appointments/presentation/screens/clinic_search_screen.dart';
import '../../../habits/presentation/screens/habit_tracker_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../todo/presentation/screens/todo_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final firstName = user?.firstName ?? 'there';
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(ref, theme, context),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  AnimatedListItem(
                    index: 0,
                    child: _buildGreeting(firstName, theme),
                  ),
                  const SizedBox(height: 24),
                  AnimatedListItem(
                    index: 1,
                    child: _buildProfileCard(user, theme),
                  ),
                  const SizedBox(height: 28),
                  AnimatedListItem(
                    index: 2,
                    child: Text('Quick Actions',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 14),
                  AnimatedListItem(
                    index: 3,
                    child: _buildQuickActions(context, theme),
                  ),
                  const SizedBox(height: 28),
                  AnimatedListItem(
                    index: 4,
                    child: Text('Upcoming',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 14),
                  AnimatedListItem(
                    index: 5,
                    child: _buildUpcomingCard(context, theme),
                  ),
                  const SizedBox(height: 28),
                  AnimatedListItem(
                    index: 6,
                    child: Text('Health Overview',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 14),
                  AnimatedListItem(
                    index: 7,
                    child: _buildHealthOverview(theme),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(WidgetRef ref, ThemeData theme, BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'images/cerebro.jpg',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            AppStrings.appName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined,
              color: theme.textTheme.bodyMedium?.color),
          onPressed: () {},
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert,
              color: theme.textTheme.bodyMedium?.color),
          onSelected: (v) {
            if (v == 'logout') ref.read(authProvider.notifier).logout();
            if (v == 'settings') {
              context.pushFadeSlide(const SettingsScreen());
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'settings', child: Text('Settings')),
            PopupMenuItem(
              value: 'logout',
              child: Text('Logout',
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting(String name, ThemeData theme) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting,',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15)),
        Text(name,
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildProfileCard(dynamic user, ThemeData theme) {
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(user?.fullName ?? 'U'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'User',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Patient',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : theme.dividerTheme.color ?? Colors.grey.shade200;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: [
        _actionCard(
          context: context,
          icon: Icons.calendar_month_rounded,
          label: 'Book\nAppointment',
          color: primary,
          cardColor: cardColor,
          borderColor: borderColor,
          onTap: () => context.pushFadeSlide(const ClinicSearchScreen()),
        ),
        _actionCard(
          context: context,
          icon: Icons.list_alt_rounded,
          label: 'My\nAppointments',
          color: theme.colorScheme.secondary,
          cardColor: cardColor,
          borderColor: borderColor,
          onTap: () =>
              context.pushFadeSlide(const AppointmentListScreen()),
        ),
        _actionCard(
          context: context,
          icon: Icons.checklist_rounded,
          label: 'To-Do\nList',
          color: const Color(0xFFF59E0B),
          cardColor: cardColor,
          borderColor: borderColor,
          onTap: () => context.pushFadeSlide(const TodoScreen()),
        ),
        _actionCard(
          context: context,
          icon: Icons.trending_up_rounded,
          label: 'Habit\nTracker',
          color: const Color(0xFF10B981),
          cardColor: cardColor,
          borderColor: borderColor,
          onTap: () =>
              context.pushFadeSlide(const HabitTrackerScreen()),
        ),
      ],
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color cardColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return AnimatedPressButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, ThemeData theme) {
    final primary = theme.colorScheme.primary;

    return GlassCard(
      blur: 8,
      opacity: 0.1,
      borderRadius: 18,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded,
              size: 42, color: primary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No upcoming appointments',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Book your first appointment to get started',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.pushFadeSlide(const ClinicSearchScreen()),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Find a Clinic'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthOverview(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            theme: theme,
            icon: Icons.favorite_rounded,
            label: 'Habits',
            value: '0',
            sublabel: 'active',
            color: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            theme: theme,
            icon: Icons.check_circle_rounded,
            label: 'To-Dos',
            value: '0',
            sublabel: 'pending',
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            theme: theme,
            icon: Icons.medical_services_rounded,
            label: 'Visits',
            value: '0',
            sublabel: 'total',
            color: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required String sublabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(sublabel, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
