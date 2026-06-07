import 'package:flutter/material.dart';

class WorkerGuideScreen extends StatelessWidget {
  const WorkerGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final List<Map<String, dynamic>> steps = [
      {
        'title': 'Complete Your Profile',
        'description': 'Add your skills, tools, and profile picture so customers can trust you.',
        'icon': Icons.person_pin_circle_outlined,
        'image': 'assets/images/guide_profile.png',
      },
      {
        'title': 'Browse Available Tasks',
        'description': 'Check the dashboard for tasks posted by customers in your area.',
        'icon': Icons.task_outlined,
        'image': 'assets/images/guide_tasks.png',
      },
      {
        'title': 'Apply and Get Hired',
        'description': 'Submit offers for tasks and chat with customers before starting work.',
        'icon': Icons.handshake_outlined,
        'image': 'assets/images/guide_apply.png',
      },
      {
        'title': 'Earn & Get Paid',
        'description': 'Complete the task and receive secure payments through the app.',
        'icon': Icons.attach_money,
        'image': 'assets/images/guide_payment.png',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Getting Started Guide'),
      ),
      body: ListView.builder(
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(step['icon'], color: colorScheme.primary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step['title'],
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (step['image'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      step['image'],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  step['description'],
                  style: textTheme.bodyMedium,
                ),
                const Divider(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
