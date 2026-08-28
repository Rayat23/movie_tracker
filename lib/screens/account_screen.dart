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
      // Status lookup should never block the account screen.
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
            constraints: const BoxConstraints(maxWidth: 920),
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
    return _panel(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded, size: 46, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            'Firebase configuration required',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            'Run Movie Tracker with the Firebase --dart-define values to enable accounts and cloud sync. Local profiles continue to work without Firebase.',
            style: TextStyle(color: Colors.white60, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _signedOutView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(
          createMode ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
          createMode
              ? 'Create your Movie Tracker account'
              : 'Sign in to Movie Tracker',
          createMode
              ? 'Create the account first. After you are signed in, use the cloud backup button to upload your local profiles.'
              : 'Sign in to access profile backups connected to your account.',
        ),
        const SizedBox(height: 18),
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
                  label: Text(
                    busy
                        ? (createMode ? 'Creating account...' : 'Signing in...')
                        : (createMode ? 'Create Account' : 'Sign In'),
                  ),
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
        _hero(
          Icons.cloud_done_rounded,
          user.displayName?.trim().isNotEmpty == true
              ? 'Welcome, ${user.displayName}'
              : 'Your Movie Tracker account',
          user.email ?? 'Signed in',
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final accountCard = _accountCard(user.email, profileCount);
            final cloudCard = _cloudCard();

            if (compact) {
              return Column(
                children: [
                  accountCard,
                  const SizedBox(height: 16),
                  cloudCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: accountCard),
                const SizedBox(width: 16),
                Expanded(child: cloudCard),
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

  Widget _accountCard(String? email, int profileCount) {
    return _panel(
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
          const SizedBox(height: 18),
          _detailRow('Email', email ?? '—'),
          _detailRow('Local profiles', '$profileCount'),
          _detailRow(
            'Last cloud backup',
            lastCloudUpdate == null
                ? 'No confirmed cloud backup yet'
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
  }

  Widget _cloudCard() {
    return _panel(
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
            'Back up every local profile to this account, or restore the latest profile set stored in Firestore.',
            style: TextStyle(color: Colors.white60, height: 1.45),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : _backupNow,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(busy ? 'Working...' : 'Back Up This Device'),
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
          const SizedBox(height: 12),
          const Text(
            'Cloud operations now stop with a readable error instead of loading forever if Firestore cannot respond.',
            style: TextStyle(fontSize: 12, color: Colors.white38, height: 1.4),
          ),
        ],
      ),
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
        passwordController.clear();

        if (!mounted) return;
        setState(() {
          busy = false;
          successMessage =
              'Account created and signed in. Use “Back Up This Device” to upload your profiles.';
        });
        _loadCloudStatus();
        return;
      }

      await accounts.signIn(email: email, password: password);
      passwordController.clear();

      if (!mounted) return;
      setState(() {
        busy = false;
        successMessage = 'Signed in successfully.';
      });
      _loadCloudStatus();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        busy = false;
        errorMessage = accounts.friendlyError(error);
      });
    }
  }

  Future<void> _backupNow() async {
    setState(() {
      busy = true;
      errorMessage = null;
      successMessage = 'Starting cloud backup...';
    });

    try {
      await cloudSync.uploadAllProfiles();
      final updated = await cloudSync.lastCloudUpdate();

      if (!mounted) return;
      setState(() {
        busy = false;
        lastCloudUpdate = updated ?? DateTime.now();
        errorMessage = null;
        successMessage =
            'Backup complete. ${ProfileService.instance.profiles.length} local profile(s) are now stored in this account.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        busy = false;
        successMessage = null;
        errorMessage = cloudSync.friendlyError(error);
      });
    }
  }

  Future<void> _restoreFromCloud() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restore cloud profiles?'),
          content: const Text(
            'This replaces the local profiles and tracking data on this device with the latest profiles stored in this cloud account.',
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
      successMessage = 'Checking cloud profiles...';
    });

    try {
      final restored = await cloudSync.downloadCloudProfiles();

      if (!mounted) return;
      setState(() {
        busy = false;
        errorMessage = null;
        successMessage = restored
            ? 'Cloud profiles restored successfully on this device.'
            : 'No cloud backup was found for this account.';
      });

      if (restored) {
        _loadCloudStatus();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        busy = false;
        successMessage = null;
        errorMessage = cloudSync.friendlyError(error);
      });
    }
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
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
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
      busy = false;
      errorMessage = null;
      successMessage = 'Signed out. Local profiles remain on this device.';
      lastCloudUpdate = null;
    });
  }

  Widget _hero(IconData icon, String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF241719), Color(0xFF151722), Color(0xFF0F1118)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.16),
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
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white60, height: 1.45),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(height: 1.4)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}
