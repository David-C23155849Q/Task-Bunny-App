import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Legal"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Privacy Policy"),
              Tab(text: "Terms of Service"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PrivacyPolicyView(),
            TermsOfServiceView(),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(
        '''Privacy Policy for TaskBunny Tasker

Effective Date: June 26, 2025

TaskBunny ("we", "us", or "our") values your privacy. This Privacy Policy explains how we collect, use, and protect your personal information when you use the TaskBunny Tasker mobile application (the "App").

1. Information We Collect
- Account Info: Name, email, phone, city, profile picture, categories.
- Automatically: Device info, basic location (city), usage analytics.
- Firebase services are used for authentication, storage, and messaging.

2. How We Use Your Data
- To match you with clients
- To send task alerts
- To improve our service

3. Who We Share With
- Clients (limited public profile info)
- Firebase (Google Cloud)
- Legal authorities (if required)

4. Your Rights
- Update your data
- Request deletion
- Opt-out of notifications

5. Security
- All data is securely stored in Firebase.

6. Contact
- Email: support@taskbunny.com
        ''',
        style: TextStyle(fontSize: 14),
      ),
    );
  }
}

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(
        '''Terms of Service for TaskBunny Tasker

1. Introduction
By signing up as a tasker, you agree to these Terms of Service.

2. Eligibility
You must be 18 years or older with legal permission to work.

3. Responsibilities
- Provide honest and timely services
- Respect client privacy and property
- Maintain accurate profile information

4. Payments
You will be paid as agreed with clients. TaskBunny does not process payments directly.

5.Subscriptions
You are required to pay a monthly subscription via ecocash, failure to do so will result in account suspension

6. Account Termination
We reserve the right to suspend accounts that violate rules.

7. Changes
We may update terms. Continued use means acceptance of updates.

8. Contact
Email us at support@taskbunny.com
        ''',
        style: TextStyle(fontSize: 14),
      ),
    );
  }
}
