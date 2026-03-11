// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ADAR';

  @override
  String get appSubtitle => 'Anonymous Drug Activity Reporter';

  @override
  String get reportTitle => 'Report Drug Activity\nAnonymously';

  @override
  String get establishingConnection => 'Establishing Secure Grid...';

  @override
  String get startReporting => 'Start Reporting';

  @override
  String get dashboardTitle => 'DASHBOARD';

  @override
  String get trustScore => 'TRUST SCORE';

  @override
  String get searchHint => 'Enter Your Report-ID';

  @override
  String get yourReports => 'YOUR REPORTS';

  @override
  String get viewReport => 'VIEW REPORT';

  @override
  String get startNewReport => 'START NEW REPORT';

  @override
  String get searchButton => 'SEARCH';

  @override
  String get reportDetails => 'REPORT DETAILS';

  @override
  String get statusStatus => 'STATUS';

  @override
  String get dateDate => 'DATE';

  @override
  String get locationLocation => 'LOCATION';

  @override
  String get descriptionDescription => 'DESCRIPTION';

  @override
  String get submitReportTitle => 'Submit Report';

  @override
  String get descriptionLabel => 'Description *';

  @override
  String get descriptionHint =>
      'What did you see? (e.g., Person hiding a package...)';

  @override
  String get descriptionHelper =>
      'Tip: Include clothing, physical features, or specific actions.';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get evidenceLabel => 'Evidence *';

  @override
  String get photoButton => 'Photo';

  @override
  String get videoButton => 'Video';

  @override
  String get continueToAssistant => 'Continue to Assistant';

  @override
  String get intelligenceSubmitted => 'INTELLIGENCE SUBMITTED';

  @override
  String get reportSubmittedMessage =>
      'Your report has been encrypted and routed to the secure intelligence grid.';

  @override
  String get trackingId => 'TRACKING ID';

  @override
  String get safetyNextSteps => 'SAFETY NEXT STEPS:';

  @override
  String get safetyStep1 =>
      'Delete the original photo/video from your gallery.';

  @override
  String get safetyStep2 =>
      'This report is now anonymous and cannot be traced to you.';

  @override
  String get returnToDashboard => 'RETURN TO DASHBOARD';

  @override
  String get assistantTitle => 'Intelligence Assistant';

  @override
  String get assistantIntro =>
      'Hello. I\'ve analyzed your initial report. I need 5 quick details to help the authorities prioritize this.';

  @override
  String get assistantTyping => 'Assistant is analyzing...';

  @override
  String get finalizeSubmit => 'FINALIZE & SUBMIT REPORT';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get tamil => 'Tamil';

  @override
  String get tapToGetLocation => 'Tap to get location';

  @override
  String reportNotFound(String id) {
    return 'Report $id not found';
  }

  @override
  String get validIdError => 'Please enter a valid 6-digit Report ID';

  @override
  String get fillAllFieldsError =>
      'Please provide Description, Evidence, and Location.';

  @override
  String get q_frequency => 'How often have you noticed this happening?';

  @override
  String get q_frequency_opt1 => 'Daily';

  @override
  String get q_frequency_opt2 => 'Weekly';

  @override
  String get q_frequency_opt3 => 'Just once';

  @override
  String get q_sensitive_area =>
      'Is this near a sensitive area like a school or park?';

  @override
  String get q_sensitive_area_opt1 => 'Yes, very close';

  @override
  String get q_sensitive_area_opt2 => 'No, far away';

  @override
  String get q_activity_type => 'What best describes the activity you saw?';

  @override
  String get q_activity_type_opt1 => 'Dealing/Exchange';

  @override
  String get q_activity_type_opt2 => 'Stash/Drop-off';

  @override
  String get q_activity_type_opt3 => 'Usage';

  @override
  String get q_vehicles => 'Were there any vehicles involved in the scene?';

  @override
  String get q_vehicles_opt1 => 'Parked car/bike';

  @override
  String get q_vehicles_opt2 => 'Moving vehicle';

  @override
  String get q_vehicles_opt3 => 'None';

  @override
  String get q_people_count => 'Approximate number of people involved?';

  @override
  String get q_people_count_opt1 => '1-2 people';

  @override
  String get q_people_count_opt2 => 'Small group (3-5)';

  @override
  String get q_people_count_opt3 => 'Large crowd';

  @override
  String get assistantThanks =>
      'Thank you. I have all the intelligence needed. Your report is ready for secure transmission.';

  @override
  String get futureDateError => 'Incident time cannot be in the future';

  @override
  String get aboutTrustScore => 'About trust score';

  @override
  String get trustScoreInfoTitle => 'Trust Score System';

  @override
  String get trustScoreCriteria =>
      'Our algorithm evaluates reports based on several signals:\n\n• Description Detail: Detailed reports gain more trust.\n• Evidence Quality: Providing both photos and videos increases the score.\n• Incident Recency: Reporting incidents quickly ensures higher accuracy.\n\nA score of 100 indicates a highly reliable report.';

  @override
  String get reportTrustScore => 'Report Trust Score';

  @override
  String get retry => 'RETRY SUBMISSION';

  @override
  String get submissionFailed =>
      'Submission failed. Please check your connection and try again.';
}
