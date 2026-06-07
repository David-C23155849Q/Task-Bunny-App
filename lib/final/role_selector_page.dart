import 'package:flutter/material.dart';
import 'cutomer_signup_screen.dart';
import 'workers_signup_screen.dart';

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  void _continueToSignup() {
    if (_selectedRole == null) return;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_selectedRole == 'worker') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Step1BasicInfoScreen(role: _selectedRole!),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerSignupScreen(role: _selectedRole!),
          ),
        );
      }
    });
  }

  Widget _buildRoleCard({
    required String title,
    required String role,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final cardColor = theme.cardColor;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : cardColor,
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: primary),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? primary : theme.textTheme.bodyLarge!.color,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: primary, size: 28),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        title: const Text('Choose Your Role'),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/bunny.png',
                height: 120,
              ),
              const SizedBox(height: 10),
              Text(
                "Welcome to TaskLink!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your role to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium!.color!.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 30),
              _buildRoleCard(
                title: "I'm a Worker",
                role: 'worker',
                icon: Icons.build_circle_outlined,
              ),
              _buildRoleCard(
                title: "I'm a Customer",
                role: 'customer',
                icon: Icons.shopping_bag_outlined,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _selectedRole != null ? _continueToSignup : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
