import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static final Uri _inquiryUri = Uri.parse(
    'https://github.com/Rayat23/movie_tracker/issues/new?template=project_inquiry.yml',
  );

  Future<void> _openInquiry(BuildContext context) async {
    final opened = await launchUrl(
      _inquiryUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the inquiry form. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Work With Me')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hero(context),
                const SizedBox(height: 28),
                const Text(
                  'What I can build',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final cardWidth = width >= 920
                        ? (width - 28) / 3
                        : width >= 620
                            ? (width - 14) / 2
                            : width;

                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _serviceCard(
                          width: cardWidth,
                          icon: Icons.language_rounded,
                          title: 'Websites & MVPs',
                          text:
                              'Responsive websites, dashboards, trackers and practical MVPs for small businesses and new ideas.',
                        ),
                        _serviceCard(
                          width: cardWidth,
                          icon: Icons.smart_toy_outlined,
                          title: 'AI Automation',
                          text:
                              'AI-assisted workflows for repetitive tasks, intake, reporting, support and internal operations.',
                        ),
                        _serviceCard(
                          width: cardWidth,
                          icon: Icons.dashboard_customize_outlined,
                          title: 'Custom Tools',
                          text:
                              'Simple custom apps and business tools built around the process you actually need to run.',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                _proofCard(),
                const SizedBox(height: 28),
                _inquiryCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF32191B), Color(0xFF171923), Color(0xFF0F1118)],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'AVAILABLE FOR PROJECT INQUIRIES',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Need a website, app or AI automation?',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Movie Tracker is one example of the kind of product work I build. Tell me the problem you want solved and I can review the scope before any commitment is made.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          );

          final button = FilledButton.icon(
            onPressed: () => _openInquiry(context),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Start a Project Inquiry'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 22), button],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 28),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _serviceCard({
    required double width,
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 188),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Icon(icon, size: 29, color: Colors.redAccent),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white54, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _proofCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, color: Colors.greenAccent),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Movie Tracker is the live proof of work',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 7),
                Text(
                  'It includes responsive Flutter web UI, movie and TV tracking, profiles, Firebase authentication and cloud data, automated CI/CD, production monitoring and a server-side API proxy.',
                  style: TextStyle(color: Colors.white54, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inquiryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF15131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start with the problem, not a contract',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'The first form only collects project details. It is not a quote, contract, payment request or promise of a deadline. Private contact information should not be posted in the public inquiry.',
            style: TextStyle(color: Colors.white54, height: 1.45),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _openInquiry(context),
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('Open Project Inquiry'),
          ),
        ],
      ),
    );
  }
}
