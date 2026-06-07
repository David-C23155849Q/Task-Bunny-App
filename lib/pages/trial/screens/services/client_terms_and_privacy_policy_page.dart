import 'package:flutter/material.dart';

class TermsPrivacyPolicyPage extends StatelessWidget {
  const TermsPrivacyPolicyPage({Key? key}) : super(key: key);

  final String termsText = '''
**Terms and Conditions**

Welcome to TaskBunny. By accessing or using our platform, you agree to comply with and be bound by the following terms and conditions. Please read them carefully.

1. **Acceptance of Terms**  
By using TaskBunny, you acknowledge that you have read, understood, and agree to be legally bound by these Terms and Conditions.

2. **Use of Service**  
You agree to use TaskBunny solely for lawful purposes and in accordance with all applicable laws and regulations. Unauthorized use is strictly prohibited.

3. **User Account**  
You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. Notify us immediately of any unauthorized use.

4. **Modifications to the Service**  
TaskBunny reserves the right to modify, suspend, or discontinue any aspect of the service at any time without prior notice.

5. **Limitation of Liability**  
TaskBunny shall not be liable for any direct, indirect, incidental, or consequential damages arising from your use or inability to use the service.

6. **Governing Law**  
These terms shall be governed by and construed in accordance with the laws of the jurisdiction in which TaskBunny operates.

Please review these terms periodically as continued use of the service constitutes your acceptance of any updates.

''';

  final String privacyText = '''
**Privacy Policy**

Your privacy is of utmost importance to us. This Privacy Policy outlines how TaskBunny collects, uses, and safeguards your personal information.

1. **Information Collection**  
We collect personal information you provide when registering, including your name, email address, and task details.

2. **Use of Information**  
Your information is used to provide, maintain, and improve our services, communicate with you, and comply with legal obligations.

3. **Data Sharing**  
We do not sell or rent your personal information to third parties. We may share data with trusted partners who assist in operating our services under strict confidentiality agreements.

4. **Data Security**  
We employ industry-standard security measures to protect your data from unauthorized access, alteration, or disclosure.

5. **User Rights**  
You may access, correct, or request deletion of your personal information in accordance with applicable laws.

6. **Policy Updates**  
We may update this Privacy Policy periodically. Continued use of the platform constitutes acceptance of the updated terms.

If you have questions about our policies, please contact us at privacy@taskbunny.com.

''';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Privacy Policy"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Terms and Conditions",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              termsText,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
            Text(
              "Privacy Policy",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              privacyText,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
