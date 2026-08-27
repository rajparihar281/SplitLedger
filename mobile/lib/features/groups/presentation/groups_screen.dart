import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Sticky Premium App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              title: Text(
                'SplitLedger',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                alignment: Alignment.topRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning,',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          username.toUpperCase(),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () async {
                  await widget.authController.signOut();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Dashboard Content
          SliverToBoxAdapter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _groupsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 16),
                    itemCount: 4,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, _) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: ShimmerLoading(width: double.infinity, height: 90, borderRadius: 20),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong',
                    subtitle: snapshot.error.toString(),
                  );
                }

                final groups = snapshot.data ?? [];
                if (groups.isEmpty) {
                  return EmptyState(
                    icon: Icons.group_add_outlined,
                    title: 'No groups yet',
                    subtitle: 'Create your first group to start splitting expenses with friends!',
                    actionLabel: 'Create Group',
                    action: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                      );
                      _refresh();
                    },
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
          _refresh();
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Group', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
