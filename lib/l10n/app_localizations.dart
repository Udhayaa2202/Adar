import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ADAR'**
  String get appName;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Drug Activity Reporter'**
  String get appSubtitle;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Drug Activity\nAnonymously'**
  String get reportTitle;

  /// No description provided for @establishingConnection.
  ///
  /// In en, this message translates to:
  /// **'Establishing Secure Grid...'**
  String get establishingConnection;

  /// No description provided for @startReporting.
  ///
  /// In en, this message translates to:
  /// **'Start Reporting'**
  String get startReporting;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'DASHBOARD'**
  String get dashboardTitle;

  /// No description provided for @trustScore.
  ///
  /// In en, this message translates to:
  /// **'TRUST SCORE'**
  String get trustScore;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Report-ID'**
  String get searchHint;

  /// No description provided for @yourReports.
  ///
  /// In en, this message translates to:
  /// **'YOUR REPORTS'**
  String get yourReports;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'VIEW REPORT'**
  String get viewReport;

  /// No description provided for @startNewReport.
  ///
  /// In en, this message translates to:
  /// **'START NEW REPORT'**
  String get startNewReport;

  /// No description provided for @searchButton.
  ///
  /// In en, this message translates to:
  /// **'SEARCH'**
  String get searchButton;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'REPORT DETAILS'**
  String get reportDetails;

  /// No description provided for @statusStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get statusStatus;

  /// No description provided for @dateDate.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get dateDate;

  /// No description provided for @locationLocation.
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get locationLocation;

  /// No description provided for @descriptionDescription.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get descriptionDescription;

  /// No description provided for @submitReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReportTitle;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What did you see? (e.g., Person hiding a package...)'**
  String get descriptionHint;

  /// No description provided for @descriptionHelper.
  ///
  /// In en, this message translates to:
  /// **'Tip: Include clothing, physical features, or specific actions.'**
  String get descriptionHelper;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @evidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Evidence *'**
  String get evidenceLabel;

  /// No description provided for @photoButton.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoButton;

  /// No description provided for @videoButton.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoButton;

  /// No description provided for @continueToAssistant.
  ///
  /// In en, this message translates to:
  /// **'Continue to Assistant'**
  String get continueToAssistant;

  /// No description provided for @intelligenceSubmitted.
  ///
  /// In en, this message translates to:
  /// **'INTELLIGENCE SUBMITTED'**
  String get intelligenceSubmitted;

  /// No description provided for @reportSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your report has been encrypted and routed to the secure intelligence grid.'**
  String get reportSubmittedMessage;

  /// No description provided for @trackingId.
  ///
  /// In en, this message translates to:
  /// **'TRACKING ID'**
  String get trackingId;

  /// No description provided for @safetyNextSteps.
  ///
  /// In en, this message translates to:
  /// **'SAFETY NEXT STEPS:'**
  String get safetyNextSteps;

  /// No description provided for @safetyStep1.
  ///
  /// In en, this message translates to:
  /// **'Delete the original photo/video from your gallery.'**
  String get safetyStep1;

  /// No description provided for @safetyStep2.
  ///
  /// In en, this message translates to:
  /// **'This report is now anonymous and cannot be traced to you.'**
  String get safetyStep2;

  /// No description provided for @returnToDashboard.
  ///
  /// In en, this message translates to:
  /// **'RETURN TO DASHBOARD'**
  String get returnToDashboard;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Intelligence Assistant'**
  String get assistantTitle;

  /// No description provided for @assistantIntro.
  ///
  /// In en, this message translates to:
  /// **'Hello. I\'ve analyzed your initial report. I need 5 quick details to help the authorities prioritize this.'**
  String get assistantIntro;

  /// No description provided for @assistantTyping.
  ///
  /// In en, this message translates to:
  /// **'Assistant is analyzing...'**
  String get assistantTyping;

  /// No description provided for @finalizeSubmit.
  ///
  /// In en, this message translates to:
  /// **'FINALIZE & SUBMIT REPORT'**
  String get finalizeSubmit;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;

  /// No description provided for @tapToGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap to get location'**
  String get tapToGetLocation;

  /// No description provided for @reportNotFound.
  ///
  /// In en, this message translates to:
  /// **'Report {id} not found'**
  String reportNotFound(String id);

  /// No description provided for @validIdError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit Report ID'**
  String get validIdError;

  /// No description provided for @fillAllFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Please provide Description, Evidence, and Location.'**
  String get fillAllFieldsError;

  /// No description provided for @q_frequency.
  ///
  /// In en, this message translates to:
  /// **'How often have you noticed this happening?'**
  String get q_frequency;

  /// No description provided for @q_frequency_opt1.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get q_frequency_opt1;

  /// No description provided for @q_frequency_opt2.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get q_frequency_opt2;

  /// No description provided for @q_frequency_opt3.
  ///
  /// In en, this message translates to:
  /// **'Just once'**
  String get q_frequency_opt3;

  /// No description provided for @q_sensitive_area.
  ///
  /// In en, this message translates to:
  /// **'Is this near a sensitive area like a school or park?'**
  String get q_sensitive_area;

  /// No description provided for @q_sensitive_area_opt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, very close'**
  String get q_sensitive_area_opt1;

  /// No description provided for @q_sensitive_area_opt2.
  ///
  /// In en, this message translates to:
  /// **'No, far away'**
  String get q_sensitive_area_opt2;

  /// No description provided for @q_activity_type.
  ///
  /// In en, this message translates to:
  /// **'What best describes the activity you saw?'**
  String get q_activity_type;

  /// No description provided for @q_activity_type_opt1.
  ///
  /// In en, this message translates to:
  /// **'Dealing/Exchange'**
  String get q_activity_type_opt1;

  /// No description provided for @q_activity_type_opt2.
  ///
  /// In en, this message translates to:
  /// **'Stash/Drop-off'**
  String get q_activity_type_opt2;

  /// No description provided for @q_activity_type_opt3.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get q_activity_type_opt3;

  /// No description provided for @q_vehicles.
  ///
  /// In en, this message translates to:
  /// **'Were there any vehicles involved in the scene?'**
  String get q_vehicles;

  /// No description provided for @q_vehicles_opt1.
  ///
  /// In en, this message translates to:
  /// **'Parked car/bike'**
  String get q_vehicles_opt1;

  /// No description provided for @q_vehicles_opt2.
  ///
  /// In en, this message translates to:
  /// **'Moving vehicle'**
  String get q_vehicles_opt2;

  /// No description provided for @q_vehicles_opt3.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get q_vehicles_opt3;

  /// No description provided for @q_people_count.
  ///
  /// In en, this message translates to:
  /// **'Approximate number of people involved?'**
  String get q_people_count;

  /// No description provided for @q_people_count_opt1.
  ///
  /// In en, this message translates to:
  /// **'1-2 people'**
  String get q_people_count_opt1;

  /// No description provided for @q_people_count_opt2.
  ///
  /// In en, this message translates to:
  /// **'Small group (3-5)'**
  String get q_people_count_opt2;

  /// No description provided for @q_people_count_opt3.
  ///
  /// In en, this message translates to:
  /// **'Large crowd'**
  String get q_people_count_opt3;

  /// No description provided for @assistantThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you. I have all the intelligence needed. Your report is ready for secure transmission.'**
  String get assistantThanks;

  /// No description provided for @futureDateError.
  ///
  /// In en, this message translates to:
  /// **'Incident time cannot be in the future'**
  String get futureDateError;

  /// No description provided for @aboutTrustScore.
  ///
  /// In en, this message translates to:
  /// **'About trust score'**
  String get aboutTrustScore;

  /// No description provided for @trustScoreInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Trust Score System'**
  String get trustScoreInfoTitle;

  /// No description provided for @trustScoreCriteria.
  ///
  /// In en, this message translates to:
  /// **'Our algorithm evaluates reports based on several signals:\n\n• Description Detail: Detailed reports gain more trust.\n• Evidence Quality: Providing both photos and videos increases the score.\n• Incident Recency: Reporting incidents quickly ensures higher accuracy.\n\nA score of 100 indicates a highly reliable report.'**
  String get trustScoreCriteria;

  /// No description provided for @reportTrustScore.
  ///
  /// In en, this message translates to:
  /// **'Report Trust Score'**
  String get reportTrustScore;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'RETRY SUBMISSION'**
  String get retry;

  /// No description provided for @submissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed. Please check your connection and try again.'**
  String get submissionFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
