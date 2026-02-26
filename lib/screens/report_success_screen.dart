import 'package:flutter/material.dart';
import 'package:adar/screens/dashboard_screen.dart';
import 'package:intl/intl.dart';
import 'package:adar/l10n/app_localizations.dart';

class ReportSuccessScreen extends StatelessWidget {
  final String reportId;

  const ReportSuccessScreen({
    super.key,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure the ID is clean for display
    final displayId = reportId.startsWith("ADAR-") ? reportId : "ADAR-$reportId";

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              const Icon(Icons.verified_user_rounded, size: 100, color: Colors.blue),
              const SizedBox(height: 30),
              Text(
                AppLocalizations.of(context)!.intelligenceSubmitted,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                AppLocalizations.of(context)!.reportSubmittedMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),

              const SizedBox(height: 40),

              _buildTrackingCard(context, displayId),

              const SizedBox(height: 50),

              _buildSafetyProtocolSection(context),

              const Spacer(),

              _buildReturnButton(context, displayId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context, String id) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.trackingId,
            style: const TextStyle(
                color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SelectableText(
            id,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "(Tap to select and copy)",
            style: TextStyle(color: Colors.white24, fontSize: 10),
          )
        ],
      ),
    );
  }

  Widget _buildSafetyProtocolSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.safetyNextSteps.toUpperCase(),
          style: const TextStyle(
              color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        const SizedBox(height: 15),
        _buildSafetyStep(Icons.delete_sweep_rounded,
            AppLocalizations.of(context)!.safetyStep1),
        _buildSafetyStep(Icons.phonelink_lock_rounded,
            AppLocalizations.of(context)!.safetyStep2),
      ],
    );
  }

  Widget _buildSafetyStep(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnButton(BuildContext context, String id) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0056D2),
        minimumSize: const Size(double.infinity, 65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ),
      onPressed: () {
        // StreamBuilder to show the real data from Firestore.
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
              (route) => false,
        );
      },
      child: Text(
        AppLocalizations.of(context)!.returnToDashboard,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}