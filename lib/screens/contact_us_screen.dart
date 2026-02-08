import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFE), // White with slight blue tint
      appBar: AppBar(
        title: const Text('Contact Us'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF00BCD4), // Turquoise
                Color(0xFF0D47A1), // Deep blue
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Need Help?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Feel free to reach out to us through any of the following channels:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildContactOption(
                context,
                Icons.email,
                'Email',
                'rejykaring2000@gmail.com',
                const Color(0xFF00BCD4),
                () {
                  _launchEmail(context, 'rejykaring2000@gmail.com');
                },
              ),
              const SizedBox(height: 12),
              _buildContactOption(
                context,
                Icons.phone,
                'Phone',
                '+91 7994870262',
                const Color(0xFF0D47A1),
                () {
                  _launchPhone(context, '+91 7994870262');
                },
              ),
              const SizedBox(height: 12),
              _buildContactOption(
                context,
                Icons.message,
                'WhatsApp',
                '+91 7994870262',
                const Color(0xFF00BCD4),
                () {
                  _launchWhatsApp(context, '+91 7994870262');
                },
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.access_time,
                            color: Color(0xFF00BCD4),
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Our Support Hours',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Monday - Friday: 9:00 AM - 6:00 PM'),
                      const SizedBox(height: 4),
                      const Text('Saturday: 10:00 AM - 4:00 PM'),
                      const SizedBox(height: 4),
                      const Text('Sunday: Closed'),
                      const SizedBox(height: 12),
                      const Text(
                        'We typically respond within 24 hours during business days.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: onTap,
      ),
    );
  }

  void _launchEmail(BuildContext context, String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening email client for $email'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF00BCD4),
      ),
    );
  }

  void _launchPhone(BuildContext context, String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phone'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0D47A1),
      ),
    );
  }

  void _launchWhatsApp(BuildContext context, String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening WhatsApp for $phone'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF00BCD4),
      ),
    );
  }
}