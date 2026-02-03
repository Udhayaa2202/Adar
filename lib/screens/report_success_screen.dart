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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              const Icon(Icons.shield_rounded, size: 100, color: Colors.blue),
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

             _buildTrackingCard(context),

              const SizedBox(height: 50),

              _buildSafetyProtocolSection(context),

              const Spacer(),

              _buildReturnButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context) {
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
            reportId,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyProtocolSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          AppLocalizations.of(context)!.safetyNextSteps,
          style: const TextStyle(
              color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildSafetyStep(Icons.delete_sweep,
            AppLocalizations.of(context)!.safetyStep1),
        _buildSafetyStep(Icons.lock_outline,
            AppLocalizations.of(context)!.safetyStep2),
      ],
    );
  }

  Widget _buildSafetyStep(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[800],
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () {
        final newReport = {
          "id": reportId.startsWith("ADAR-") ? reportId : "ADAR-$reportId",
          "status": "PENDING",
          "date": DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
          "location": "Current Location",
          "description": "Report submitted via intelligence portal. Analyzing data..."
        };

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(newReport: newReport)),
              (route) => false,
        );
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          AppLocalizations.of(context)!.returnToDashboard,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}