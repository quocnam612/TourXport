import 'package:flutter/material.dart';

import 'legal_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Privacy Policy',
      subtitle:
          'This page explains how TourXport collects, uses, stores, and protects information when people use the app, including sign-in with Facebook or Google.',
      activeRoute: '/privacy',
      children: [
        LegalNotice(
          icon: Icons.public_rounded,
          title: 'Public page for platform review',
          body:
              'This policy is accessible without login and can be used as the Privacy Policy URL for Facebook Developer Console.',
        ),
        LegalSection(
          title: '1. Information we collect',
          paragraphs: [
            'TourXport only collects information needed to provide account, travel planning, and saved content features.',
          ],
          bullets: [
            'Account information such as name, email address, phone number if provided, avatar, and authentication provider identifiers.',
            'Facebook or Google profile information that you authorize during social sign-in, such as public profile, email, and profile picture.',
            'Travel preferences, survey answers, generated itineraries, saved destinations, saved hotels, saved restaurants, and reviews you create.',
            'Approximate or precise location only when you grant permission for map, routing, or nearby travel features.',
            'Technical information such as device type, app errors, request metadata, and security logs used to operate and protect the service.',
          ],
        ),
        LegalSection(
          title: '2. How we use information',
          bullets: [
            'Create and manage your TourXport account.',
            'Authenticate you through email, Google, or Facebook login.',
            'Generate travel suggestions, itineraries, route information, and personalized recommendations.',
            'Store your saved places, tours, restaurants, hotels, reviews, and profile preferences.',
            'Improve app reliability, prevent abuse, and secure user accounts.',
            'Respond to user support, privacy, or data deletion requests.',
          ],
        ),
        LegalSection(
          title: '3. Sharing and third-party services',
          paragraphs: [
            'TourXport does not sell personal data. We may share limited information with service providers only when required to run app features.',
          ],
          bullets: [
            'Authentication providers such as Facebook and Google for login flows authorized by the user.',
            'Cloud and media hosting services used to store profile images or app assets.',
            'Map, route, weather, and travel data providers used to power destination discovery and itinerary features.',
            'Infrastructure and database providers used to host the backend and protect the service.',
          ],
        ),
        LegalSection(
          title: '4. Data retention',
          paragraphs: [
            'We keep account and travel data while your account is active or as long as needed to provide TourXport features. Some data may be retained for a limited period when required for security, fraud prevention, legal obligations, or backup recovery.',
          ],
        ),
        LegalSection(
          title: '5. Your choices and rights',
          bullets: [
            'You can update profile information inside the app.',
            'You can remove saved tours and saved travel items from your account.',
            'You can revoke Facebook or Google access from the relevant provider account settings.',
            'You can request deletion of personal data by following the instructions on the Data Deletion page.',
          ],
        ),
        LegalSection(
          title: '6. Security',
          paragraphs: [
            'TourXport uses authenticated API requests, password hashing, access tokens, provider verification, and reasonable operational safeguards to protect user data. No online service can guarantee absolute security, but we work to reduce unauthorized access and misuse.',
          ],
        ),
        LegalSection(
          title: '7. Children',
          paragraphs: [
            'TourXport is not intended for children under 13. We do not knowingly collect personal information from children under 13. If such data is discovered, we will remove it from our systems where required.',
          ],
        ),
        LegalSection(
          title: '8. Contact and updates',
          paragraphs: [
            'We may update this policy when app features, providers, or legal requirements change. The updated date at the top of this page shows the latest revision. For privacy questions, contact TourXport through the support channel listed in the app or in the related platform app listing.',
          ],
        ),
      ],
    );
  }
}
