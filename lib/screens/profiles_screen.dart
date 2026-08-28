import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/account_service.dart';
import '../services/firebase_bootstrap.dart';
import '../services/profile_service.dart';
import 'account_screen.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final ProfileService profiles = ProfileService.instance;
  final AccountService accounts = AccountService.instance;

  static const List<Color> avatarColors = [
    Color(0xFFE53935),
    Color(0xFF7E57C2),
    Color(0xFF42A5F5),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
    Color(0xFFEC407A),
    Color(0xFF66BB6A),
    Color(0xFF78909C),
  ];

  @override
  Widget build(BuildContext context) {
    final activeId = profiles.activeProfile.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who’s watching?',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Every profile keeps its own movies, TV progress, ratings, rewatches, diary, and watch-time statistics.',
                  style: TextStyle(color: Colors.white60, fontSize: 15),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    ...profiles.profiles.map(
                      (profile) => _profileCard(
                        profile,
                        isActive: profile.id == activeId,
                      ),
                    ),
                    _addProfileCard(),
                  ],
                ),
                const SizedBox(height: 28),
                _cloudAccountCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cloudAccountCard() {
    final configured = FirebaseBootstrap.isConfigured;
    final user = accounts.currentUser;
    final signedIn = user != null;

    final IconData icon;
    final Color iconColor;
    final String title;
    final String description;
    final String buttonLabel;

    if (!configured) {
      icon = Icons.cloud_off_rounded;
      iconColor = Colors.white54;
      title = 'Local profiles are active';
      description =
          'Cloud account support is now built into Movie Tracker. Connect a Firebase project to enable real email/password sign-in and cloud backup across devices.';
      buttonLabel = 'Open Cloud Setup';
    } else if (signedIn) {
      icon = Icons.cloud_done_rounded;
      iconColor = Colors.greenAccent;
      title = 'Signed in${user.email == null ? '' : ' • ${user.email}'}';
      description =
          'Back up or restore all of these profiles from your private cloud account.';
      buttonLabel = 'Account & Cloud Sync';
    } else {
      icon = Icons.cloud_queue_rounded;
      iconColor = Colors.lightBlueAccent;
      title = 'Cloud accounts are ready';
      description =
          'Sign in or create an account to keep these profiles backed up and available on another device.';
      buttonLabel = 'Sign In / Create Account';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          final info = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white60,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final button = FilledButton.icon(
            onPressed: _openAccount,
            icon: const Icon(Icons.manage_accounts_rounded),
            label: Text(buttonLabel),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: 16),
                button,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 20),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _profileCard(UserProfile profile, {required bool isActive}) {
    final color = avatarColors[profile.avatarIndex % avatarColors.length];

    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.8) : Colors.white10,
          width: isActive ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: color.withValues(alpha: 0.18),
                child: Text(
                  profile.initials,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isActive)
                const Positioned(
                  right: -2,
                  bottom: -2,
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profile.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? 'Active profile' : 'Separate tracking data',
            style: TextStyle(
              color: isActive ? Colors.greenAccent : Colors.white38,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isActive
                  ? null
                  : () async {
                      await profiles.switchProfile(profile.id);
                      if (!mounted) return;
                      Navigator.pop(context, true);
                    },
              child: Text(isActive ? 'Current' : 'Switch'),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Edit profile',
                onPressed: () => _editProfile(profile),
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              if (profiles.profiles.length > 1)
                IconButton(
                  tooltip: 'Delete profile',
                  onPressed: () => _confirmDelete(profile),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addProfileCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _createProfile,
      child: Container(
        width: 220,
        height: 285,
        decoration: BoxDecoration(
          color: const Color(0xFF0E1016),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white10,
              child: Icon(Icons.add, size: 38, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              'Add Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 5),
            Text(
              'Start with empty personal data',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAccount() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccountScreen()),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _createProfile() async {
    final controller = TextEditingController();
    int avatarIndex = profiles.profiles.length % avatarColors.length;

    final result = await showDialog<_ProfileFormResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create profile'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLength: 24,
                      decoration: const InputDecoration(
                        labelText: 'Profile name',
                        hintText: 'e.g. Rayat, Family, Guest',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Avatar color',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(avatarColors.length, (index) {
                        final selected = index == avatarIndex;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              avatarIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: CircleAvatar(
                            radius: selected ? 22 : 20,
                            backgroundColor: avatarColors[index],
                            child: selected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(
                      dialogContext,
                      _ProfileFormResult(name, avatarIndex),
                    );
                  },
                  child: const Text('Create & switch'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (result == null) return;

    await profiles.createProfile(
      result.name,
      avatarIndex: result.avatarIndex,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _editProfile(UserProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    int avatarIndex = profile.avatarIndex;

    final result = await showDialog<_ProfileFormResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit profile'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      maxLength: 24,
                      decoration: const InputDecoration(labelText: 'Profile name'),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(avatarColors.length, (index) {
                        final selected = index == avatarIndex;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              avatarIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: CircleAvatar(
                            radius: selected ? 22 : 20,
                            backgroundColor: avatarColors[index],
                            child: selected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(
                      dialogContext,
                      _ProfileFormResult(name, avatarIndex),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (result == null) return;

    await profiles.renameProfile(profile.id, result.name);
    await profiles.setAvatar(profile.id, result.avatarIndex);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _confirmDelete(UserProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${profile.name}?'),
          content: const Text(
            'This removes this local profile and its saved tracking data from this browser/device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await profiles.deleteProfile(profile.id);
    if (!mounted) return;
    setState(() {});
  }
}

class _ProfileFormResult {
  final String name;
  final int avatarIndex;

  const _ProfileFormResult(this.name, this.avatarIndex);
}
