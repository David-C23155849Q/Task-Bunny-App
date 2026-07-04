import 'package:flutter/material.dart';

class ClientHowItWorksPage extends StatelessWidget {
  const ClientHowItWorksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("How It Works"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          Text(
            "How TaskBunny Works for Clients",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 30),

          _buildStepCard(
            context,
            icon: Icons.post_add,
            title: "1. Post a Task",
            description:
            "Describe what you need done, choose a category, set your budget, and pick a date and location.",
          ),
          _buildStepCard(
            context,
            icon: Icons.search,
            title: "2. Get Matched",
            description:
            "We'll automatically match you with nearby taskers who are skilled in the job you need done.",
          ),
          _buildStepCard(
            context,
            icon: Icons.person_pin_circle,
            title: "3. Select a Tasker",
            description:
            "Review tasker profiles, ratings, and availability. Choose the one that fits you best.",
          ),
          _buildStepCard(
            context,
            icon: Icons.verified,
            title: "4. Task Completed",
            description:
            "Once the task is done, you can confirm it, rate the tasker, and make payment securely.",
          ),

          const SizedBox(height: 40),

          Text(
            "Why Use TaskBunny?",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          _buildBenefitItem(Icons.shield, "Safe & Secure"),
          _buildBenefitItem(Icons.timer, "Fast & Convenient"),
          _buildBenefitItem(Icons.star, "Trusted Taskers"),
          _buildBenefitItem(Icons.credit_card, "Secure Payments"),

          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text("Back to Home"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(BuildContext context,
      {required IconData icon, required String title, required String description}) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 6),
                  Text(description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}
