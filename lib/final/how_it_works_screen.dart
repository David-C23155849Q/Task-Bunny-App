import 'package:errand_app/final/workers_home_tab.dart';
import 'package:flutter/material.dart';

class HowItWorksScreen extends StatefulWidget {
  final String uid;

  const HowItWorksScreen({required this.uid});

  @override
  State<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends State<HowItWorksScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;
  bool skipPressed = false;

  final List<Map<String, String>> steps = [
    {
      'image': 'assets/images/bunny.png',
      'title': '✨ Welcome Tasker',
      'description': 'Let us walk you through a few steps on how TaskBunny works. It is highly recommended that you do not skip this tutorial.',
    },
    {
      'image': 'assets/images/post_task_picture.png',
      'title': '✨ Clients Post Tasks',
      'description': 'They describe their task, set a budget, and pick a category. You don’t need to chase jobs!',
    },
    {
      'image': 'assets/images/notification.png',
      'title': '🎯 You Get Matched',
      'description': 'If the task matches your skills & city, we notify you instantly. You decide what to accept!',
    },
    {
      'image': 'assets/images/get_paid.png',
      'title': '💰 Complete & Get Paid',
      'description': 'Do the job, make someone happy, and get paid—directly. Simple! '
          'NB:Do not mark task as complete without confirming payment.',
    },
    {
      'image': 'assets/images/payment.png',
      'title': '⚠️ Pay Monthly Subscription',
      'description': 'TaskBunny Taskers are required to pay 10% of their total earnings each month via eco cash. Failure to make payment will result in your account being suspended.',
    },
    {
      'image': 'assets/images/done.png',
      'title': '✅ Tutorial Complete',
      'description': 'This marks the end of our tutorial. Time to get started. ',
    },
  ];

  void onSkip() {
    setState(() {
      skipPressed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Skipped! You can revisit this later from Settings."),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: steps.length,
                onPageChanged: (index) => setState(() => currentIndex = index),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(step['image']!, height: 260),
                        const SizedBox(height: 24),
                        Text(
                          step['title']!,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          step['description']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (index != steps.length - 1)
                          Text(
                            "➡️ Swipe to continue...",
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                steps.length,
                    (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  width: currentIndex == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? (isDark ? Colors.white : Colors.black)
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Skip Button
            TextButton(
              onPressed: onSkip,
              child: Text("Skip Tutorial"),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton(
                onPressed: (currentIndex == steps.length - 1 || skipPressed)
                    ? () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeTab(),
                    ),
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: (currentIndex == steps.length - 1 || skipPressed)
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                child: Text(
                  "🚀 Get Started",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
