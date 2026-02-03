// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'ADAR';

  @override
  String get appSubtitle => 'அநாமதேய போதைப்பொருள் நடவடிக்கை புகாரளிப்பவர்';

  @override
  String get reportTitle =>
      'போதைப்பொருள் நடவடிக்கையை\nஅநாமதேயமாக புகாரளிக்கவும்';

  @override
  String get establishingConnection => 'பாதுகாப்பான இணைப்பை உருவாக்குகிறது...';

  @override
  String get startReporting => 'புகாரளிக்கத் தொடங்குங்கள்';

  @override
  String get dashboardTitle => 'முகப்பு பலகை';

  @override
  String get trustScore => 'நம்பகத்தன்மை மதிப்பீடு';

  @override
  String get searchHint => 'உங்கள் புகார்-ஐடியை உள்ளிடவும்';

  @override
  String get yourReports => 'உங்கள் புகார்கள்';

  @override
  String get viewReport => 'புகாரைப் பார்க்கவும்';

  @override
  String get startNewReport => 'புதிய புகாரைத் தொடங்கவும்';

  @override
  String get searchButton => 'தேடு';

  @override
  String get reportDetails => 'புகார் விவரங்கள்';

  @override
  String get statusStatus => 'நிலை';

  @override
  String get dateDate => 'தேதி';

  @override
  String get locationLocation => 'இடம்';

  @override
  String get descriptionDescription => 'விளக்கம்';

  @override
  String get submitReportTitle => 'புகாரைச் சமர்ப்பிக்கவும்';

  @override
  String get descriptionLabel => 'விளக்கம் *';

  @override
  String get descriptionHint =>
      'நீங்கள் என்ன பார்த்தீர்கள்? (எ.கா: ஒருவர் பார்சலை மறைத்து வைப்பது...)';

  @override
  String get descriptionHelper =>
      'குறிப்பு: ஆடை, உடல் அம்சங்கள் அல்லது குறிப்பிட்ட செயல்களைச் சேர்க்கவும்.';

  @override
  String get dateLabel => 'தேதி';

  @override
  String get timeLabel => 'நேரம்';

  @override
  String get evidenceLabel => 'ஆதாரம் *';

  @override
  String get photoButton => 'புகைப்படம்';

  @override
  String get videoButton => 'வீடியோ';

  @override
  String get continueToAssistant => 'உதவியாளரிடம் செல்லவும்';

  @override
  String get intelligenceSubmitted => 'தகவல் சமர்ப்பிக்கப்பட்டது';

  @override
  String get reportSubmittedMessage =>
      'உங்கள் புகார் குறியாக்கம் செய்யப்பட்டு பாதுகாப்பான உளவுத்துறை கட்டத்திற்கு அனுப்பப்பட்டுள்ளது.';

  @override
  String get trackingId => 'கண்காணிப்பு ஐடி';

  @override
  String get safetyNextSteps => 'பாதுகாப்பு அடுத்த படிகள்:';

  @override
  String get safetyStep1 =>
      'உங்கள் கேலரியில் இருந்து அசல் புகைப்படம்/வீடியோவை நீக்கவும்.';

  @override
  String get safetyStep2 =>
      'இந்த புகார் இப்போது அநாமதேயமானது, உங்களை கண்டறிய முடியாது.';

  @override
  String get returnToDashboard => 'முகப்பு பலகைக்கு திரும்பவும்';

  @override
  String get assistantTitle => 'உளவுத்துறை உதவியாளர்';

  @override
  String get assistantIntro =>
      'வணக்கம். நான் உங்கள் முதற்கட்ட புகாரை ஆய்வு செய்துள்ளேன். அதிகாரிகளுக்கு முன்னுரிமை அளிக்க எனக்கு 5 விரைவான விவரங்கள் தேவை.';

  @override
  String get assistantTyping => 'உதவியாளர் ஆய்வு செய்கிறார்...';

  @override
  String get finalizeSubmit => 'முடிவு செய்து புகாரைச் சமர்ப்பிக்கவும்';

  @override
  String get selectLanguage => 'மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get english => 'ஆங்கிலம்';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get tapToGetLocation => 'இடத்தைப் பெற தட்டவும்';

  @override
  String reportNotFound(String id) {
    return 'புகார் $id காணப்படவில்லை';
  }

  @override
  String get validIdError => 'சரியான 6-இலக்க புகார் ஐடியை உள்ளிடவும்';

  @override
  String get fillAllFieldsError => 'விளக்கம், ஆதாரம் மற்றும் இடத்தை வழங்கவும்.';

  @override
  String get q_frequency => 'இதை எவ்வளவு அடிக்கடி கவனித்திருக்கிறீர்கள்?';

  @override
  String get q_frequency_opt1 => 'தினசரி';

  @override
  String get q_frequency_opt2 => 'வாராந்திரம்';

  @override
  String get q_frequency_opt3 => 'ஒரு முறை மட்டும்';

  @override
  String get q_sensitive_area =>
      'இது பள்ளி அல்லது பூங்கா போன்ற முக்கியமான பகுதிக்கு அருகில் உள்ளதா?';

  @override
  String get q_sensitive_area_opt1 => 'ஆம், மிக அருகில்';

  @override
  String get q_sensitive_area_opt2 => 'இல்லை, வெகு தொலைவில்';

  @override
  String get q_activity_type =>
      'நீங்கள் பார்த்த நடவடிக்கையை எது சிறப்பாக விவரிக்கிறது?';

  @override
  String get q_activity_type_opt1 => 'விற்பனை/பரிமாற்றம்';

  @override
  String get q_activity_type_opt2 => 'மறைத்து வைத்தல்';

  @override
  String get q_activity_type_opt3 => 'பயன்படுத்துதல்';

  @override
  String get q_vehicles => 'சம்பவ இடத்தில் ஏதேனும் வாகனங்கள் இருந்தனவா?';

  @override
  String get q_vehicles_opt1 => 'நிறுத்தப்பட்ட கார்/பைக்';

  @override
  String get q_vehicles_opt2 => 'நகரும் வாகனம்';

  @override
  String get q_vehicles_opt3 => 'எதுவுமில்லை';

  @override
  String get q_people_count => 'தோராயமாக எத்தனை பேர் இருந்தனர்?';

  @override
  String get q_people_count_opt1 => '1-2 பேர்';

  @override
  String get q_people_count_opt2 => 'சிறிய குழு (3-5)';

  @override
  String get q_people_count_opt3 => 'பெரிய கூட்டம்';

  @override
  String get assistantThanks =>
      'நன்றி. எனக்கு தேவையான அனைத்து உளவுத்துறை தகவல்களும் கிடைத்துள்ளன. உங்கள் புகார் பாதுகாப்பான பரிமாற்றத்திற்கு தயாராக உள்ளது.';
}
