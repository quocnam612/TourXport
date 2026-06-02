import 'package:flutter/material.dart';

class LegalScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final String activeRoute;
  final List<Widget> children;

  const LegalScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activeRoute,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08110F),
      body: SelectionArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF10231F),
                      Color(0xFF0A1513),
                      Color(0xFF050807),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopNav(activeRoute: activeRoute),
                            const SizedBox(height: 42),
                            Text(
                              'TourXport',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.68),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 16,
                                  height: 1.65,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Last updated: May 30, 2026',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.54),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 64),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalSection extends StatelessWidget {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const LegalSection({
    super.key,
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              for (final paragraph in paragraphs) ...[
                Text(
                  paragraph,
                  style: _bodyStyle(context),
                ),
                const SizedBox(height: 12),
              ],
              for (final bullet in bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 9, right: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4AF7A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          bullet,
                          style: _bodyStyle(context),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _bodyStyle(BuildContext context) {
    return TextStyle(
      color: Colors.white.withOpacity(0.76),
      fontSize: 15,
      height: 1.65,
      fontWeight: FontWeight.w400,
    );
  }
}

class LegalNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const LegalNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF7A).withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD4AF7A), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  final String activeRoute;

  const _TopNav({required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _NavButton(
          label: 'Home',
          icon: Icons.explore_rounded,
          selected: false,
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          ),
        ),
        _NavButton(
          label: 'Privacy',
          icon: Icons.privacy_tip_outlined,
          selected: activeRoute == '/privacy',
          onPressed: activeRoute == '/privacy'
              ? null
              : () => Navigator.pushReplacementNamed(context, '/privacy'),
        ),
        _NavButton(
          label: 'Data deletion',
          icon: Icons.delete_outline_rounded,
          selected: activeRoute == '/data-deletion',
          onPressed: activeRoute == '/data-deletion'
              ? null
              : () => Navigator.pushReplacementNamed(context, '/data-deletion'),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: selected
            ? const Color(0xFFD4AF7A).withOpacity(0.20)
            : Colors.white.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected
                ? const Color(0xFFD4AF7A).withOpacity(0.48)
                : Colors.white.withOpacity(0.12),
          ),
        ),
      ),
    );
  }
}
