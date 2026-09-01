import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/presentation/profile_screen.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'widgets/group_card.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late Future<List<Map<String, dynamic>>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  void _fetchGroups() {
    final supabase = Supabase.instance.client;
    _groupsFuture = supabase
        .from('groups')
        .select('id, name, created_at, group_members!inner(user_id)')
        .eq('group_members.user_id', supabase.auth.currentUser!.id)
        .order('created_at', ascending: false);
  }

  Future<void> _refresh() async {
    setState(() {
      _fetchGroups();
    });
    await _groupsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    final username = userEmail.split('@').first;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.paper,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.base,
              ),
              title: Text(
                'SplitLedger',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  letterSpacing: -0.3,
                  color: AppColors.ink,
                ),
              ),
              background: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  56,
                  AppSpacing.screenH,
                  0,
                ),
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Good morning,',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline_rounded, size: 22),
                color: AppColors.ink,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 22),
                color: AppColors.slate,
                onPressed: () async {
                  await widget.authController.signOut();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),

          // ── Section header ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.lg,
                AppSpacing.screenH,
                AppSpacing.md,
              ),
              child: Text(
                'Your groups',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.slate,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────
          SliverToBoxAdapter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _groupsFuture,
              builder: (context, snapshot) {
                // Loading shimmer
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    itemCount: 4,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                      child: ShimmerLoading(
                        width: double.infinity,
                        height: 80,
                        borderRadius: AppRadius.card,
                      ),
                    ),
                  );
                }

                // Error state
                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong',
                    subtitle: snapshot.error.toString(),
                  );
                }

                // Empty state
                final groups = snapshot.data ?? [];
                if (groups.isEmpty) {
                  return EmptyState(
                    icon: Icons.group_add_outlined,
                    title: 'No groups yet',
                    subtitle:
                        'Create your first group to start splitting expenses with friends.',
                    actionLabel: 'Create group',
                    action: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                      );
                      _refresh();
                    },
                  );
                }

                // Group list
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return GroupCard(
                      groupName: group['name'],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(
                              groupId: group['id'],
                              groupName: group['name'],
                            ),
                          ),
                        ).then((_) => _refresh());
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ── FAB – coral accent ─────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
          _refresh();
        },
        backgroundColor: AppColors.coral,
        foregroundColor: AppColors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'New group',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
