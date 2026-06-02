import 'package:flutter/material.dart';

import 'legal_scaffold.dart';

class DataDeletionScreen extends StatelessWidget {
  const DataDeletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Data Deletion Instructions',
      subtitle:
          'Use these instructions to request deletion of TourXport account data, including data connected through Facebook login.',
      activeRoute: '/data-deletion',
      children: [
        LegalNotice(
          icon: Icons.delete_forever_outlined,
          title: 'Public data deletion instructions',
          body:
              'This page is accessible without login and can be used as the User Data Deletion Instructions URL for Facebook Developer Console.',
        ),
        LegalSection(
          title: '1. What can be deleted',
          paragraphs: [
            'You can request deletion of personal data associated with your TourXport account. This includes account profile data and app content linked to your user account.',
          ],
          bullets: [
            'Name, email address, phone number if provided, avatar, and social login identifiers.',
            'Saved places, saved tours, saved hotels, saved restaurants, and travel preferences.',
            'Survey answers, generated itinerary records, reviews, and other account-linked content where deletion is technically and legally possible.',
            'Facebook login information stored by TourXport, such as Facebook user ID, public profile fields, email, and profile picture URL if available.',
          ],
        ),
        LegalSection(
          title: '2. Request deletion from inside the app',
          bullets: [
            'Sign in to the TourXport account you want to delete data from.',
            'Open Profile or Help & Support in the app.',
            'Send a support request with the subject "Data deletion request".',
            'Include the account email, login provider, and a short confirmation that you want TourXport to delete your account data.',
          ],
        ),
        LegalSection(
          title: '3. Request deletion if you cannot sign in',
          paragraphs: [
            'If you cannot access your account, send a deletion request through the support contact listed for TourXport in the app, app store listing, or Facebook app listing.',
          ],
          bullets: [
            'Use the subject "TourXport data deletion request".',
            'Provide the email address used for TourXport or Facebook login.',
            'Provide your Facebook profile name if the account was created with Facebook login.',
            'Do not send passwords or one-time verification codes.',
          ],
        ),
        LegalSection(
          title: '4. Verification',
          paragraphs: [
            'TourXport may ask for limited information to verify that the requester controls the account before deleting data. This protects accounts from unauthorized deletion.',
          ],
        ),
        LegalSection(
          title: '5. Processing time',
          paragraphs: [
            'After verification, TourXport will process deletion requests within a reasonable period. Some information may remain temporarily in backups, logs, or records required for fraud prevention, security, dispute resolution, or legal compliance.',
          ],
        ),
        LegalSection(
          title: '6. Revoke Facebook access',
          paragraphs: [
            'You can also disconnect TourXport from your Facebook account through Facebook settings. This stops future Facebook data sharing with TourXport but does not automatically delete data already stored in TourXport systems.',
          ],
          bullets: [
            'Open Facebook Settings.',
            'Go to Apps and Websites.',
            'Find TourXport.',
            'Remove access for TourXport.',
            'Submit a deletion request using the instructions above if you also want stored TourXport account data deleted.',
          ],
        ),
        LegalSection(
          title: '7. Result of deletion',
          paragraphs: [
            'When account data is deleted, saved travel items, generated tours, profile details, and linked social login records may no longer be available. You may need to create a new account to use personalized TourXport features again.',
          ],
        ),
      ],
    );
  }
}
