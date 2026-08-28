import 'package:flutter/material.dart';

import '../services/account_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/firebase_bootstrap.dart';
import '../services/profile_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AccountService accounts = AccountService.instance;
  final CloudSyncService cloudSync = CloudSyncService.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool createMode = false;
  bool busy = false;
  String? errorMessage;
  String? successMessage;
  DateTime? lastCloudUpdate;

  @override
  void initState() {
    super.initState();
    _loadCloudStatus();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadCloudStatus() async {
    if (!accounts.isSignedIn) return;
    try {
      final value = await cloudSync.lastCloudUpdate();
      if (!mounted) return;
      setState(() {
        lastCloudUpdate = value;
      });
    } catch (_) {
      // The account page remains usable even if status lookup fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account & Cloud Sync')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: !FirebaseBootstrap.isConfigured
                ? _configurationRequired()
                : accounts.isSignedIn
                    ? _signedInView()
                    : _signedOutView(),
          ),
        ),
      ),
    );
  }

  Widget _configurationRequired() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heroCard(
          icon: Icons.cloud_off_rounded,
          title: 'Cloud accounts are ready in the app code',
          message:
              'This build is running in local-only mode because Firebase project values have not been supplied yet. Your profiles still work normally on this browser/device.',
        ),
        const SizedBox(height: 20),
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'One-time Firebase setup required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'After a Firebase project is connected, this screen becomes the real email/password sign-up and sign-in page. Firebase values are passed at run/build time, so they do not need to be committed into the repository.',
                style: TextStyle(color: Colors.white60, height: 1.5),
              ),
              const SizedBox(height: 18),
              _setupRow('1', 'Create/connect a Firebase project.'),
              _setupRow('2', 'Enable Email/Password in Firebase Authentication.'),
              _setupRow('3', 'Create a Cloud Firestore database.'),
              _setupRow(
                '4',
                'Run Movie Tracker with the Firebase --dart-define values for that project.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _signedOutView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heroCard(
          icon: createMode ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
          title: createMode ? 'Create your Movie Tracker account' : 'Sign in to Movie Tracker',
          message: createMode
              ? 'Your local profiles can be backed up to your new account after registration.'
              : 'Sign in to access your cloud profile backups across devices.',
        ),
        const SizedBox(height: 20),
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.login_rounded),
                    label: Text('Sign In'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.person_add_alt_1_rounded),
                    label: Text('Create Account'),
                  ),
                ],
                selected: {createMode},
                onSelectionChanged: busy
                    ? null
                    : (selection) {
                        setState(() {
                          createMode = selection.first;
                          errorMessage = null;
                          successMessage = null;
                        });
                      },
              ),
              const SizedBox(height: 22),
              if (createMode) ...[
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: true,
                onSubmitted: (_) => _submitAuth(),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 14),
                _messageBox(errorMessage!, isError: true),
              ],
              if (successMessage != null) ...[
                const SizedBox(height: 14),
                _messageBox(successMessage!, isError: false),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : _submitAuth,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          createMode
                              ? Icons.person_add_alt_1_rounded
                              : Icons.login_rounded,
                        ),
                  label: Text(createMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              if (!createMode) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: busy ? null : _resetPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _signedInView() {
    final user = accounts.currentUser!;
    final profileCount = ProfileService.instance.profiles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heroCard(
          icon: Icons.cloud_done_rounded,
          title: user.displayName?.trim().isNotEmpty == true
              ? 'Welcome, ${user.displayName}'
              : 'Your cloud account',
          message: user.email ?? 'Signed in to Movie Tracker',
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final accountCard = _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Colors.greenAccent),
                      SizedBox(width: 10),
                      Text(
                        'Account',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailRow('Email', user.email ?? '—'),
                  _detailRow('Local profiles', '$profileCount'),
                  _detailRow(
                    'Last cloud backup',
                    lastCloudUpdate == null
                        ? 'No cloud backup yet'
                        : _formatDateTime(lastCloudUpdate!),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: busy ? null : _signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out'),
                  ),
                ],
              ),
            );

            final syncCard = _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sync_rounded, color: Colors.lightBlueAccent),
                      SizedBox(width: 10),
                      Text(
                        'Cloud Data',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Back up all local profiles or restore the profiles already stored in this account.',
                    style: TextStyle(color: Colors.white60, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _backupNow,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Back Up This Device'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _restoreFromCloud,
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: const Text('Restore From Cloud'),
                    ),
                  ),
                ],
              ),
            );

            if (compact) {
              return Column(
                children: [
                  accountCard,
                  const SizedBox(height: 16),
                  syncCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: accountCard),
                const SizedBox(width: 16),
                Expanded(child: syncCard),
              ],
            );
          },
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          _messageBox(errorMessage!, isError: true),
        ],
        if (successMessage != null) ...[
          const SizedBox(height: 16),
          _messageBox(successMessage!, isError: false),
        ],
      ],
    );
  }

  Future<void> _submitAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (createMode && name.isEmpty)) {
      setState(() {
        errorMessage = 'Complete all required fields.';
        successMessage = null;
      });
      return;
    }

    setState(() {
      busy = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      if (createMode) {
        await accounts.createAccount(
          name: name,
          email: email,
          password: password,
        );
        await cloudSync.uploadAllProfiles();
        successMessage = 'Account created and local profiles backed up.';
      } else {
        await accounts.signIn(email: email, password: password);
        successMessage = 'Signed in successfully.';
      }

      passwordController.clear();
      await _loadCloudStatus();
    } catch (error) {
      errorMessage = accounts.friendlyError(error);
    }

    if (!mounted) return;
    setState(() {
      busy = false;
    });
  }

  Future<void> _backupNow() async {
    setState(() {
      busy = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      await cloudSync.uploadAllProfiles();
      lastCloudUpdate = await cloudSync.lastCloudUpdate();
      successMessage = 'All local profiles were backed up to this account.';
    } catch (error) {
      errorMessage = error.toString();
    }

    if (!mounted) return;
    setState(() {
      busy = false;
    });
  }

  Future<void> _restoreFromCloud() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restore cloud profiles?'),
          content: const Text(
            'This replaces the local profiles and tracking data on this device with the profiles currently stored in your cloud account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      busy = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final restored = await cloudSync.downloadCloudProfiles();
      successMessage = restored
          ? 'Cloud profiles restored on this device.'
          : 'No cloud profiles were found for this account.';
    } catch (error) {
      errorMessage = error.toString();
    }

    if (!mounted) return;
    setState(() {
      busy = false;
    });
  }

  Future<void> _resetPassword() async {
    final controller = TextEditingController(text: emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Send Reset Email'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (email == null || email.isEmpty) return;

    try {
      await accounts.sendPasswordReset(email);
      if (!mounted) return;
      setState(() {
        successMessage = 'Password reset email sent.';
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = accounts.friendlyError(error);
        successMessage = null;
      });
    }
  }

  Future<void> _signOut() async {
    await accounts.signOut();
    if (!mounted) return;
    setState(() {
      errorMessage = null;
      successMessage = 'Signed out. Local profiles remain on this device.';
      lastCloudUpdate = null;
    });
  }

  Widget _heroCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF231719), Color(0xFF151722), Color(0xFF0F1118)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white60, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _setupRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white10,
            child: Text(number, style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 11),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.white38)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _messageBox(String message, {required bool isError}) {
    final color = isError ? Colors.redAccent : Colors.greenAccent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(message),
    );
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year} • $hour:$minute $period';
  }
}
