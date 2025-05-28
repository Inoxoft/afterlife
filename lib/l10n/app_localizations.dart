import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'translations_en.dart';
import 'translations_es.dart';
import 'translations_fr.dart';
import 'translations_de.dart';
import 'translations_ja.dart';
import 'translations_ko.dart';
import 'translations_zh.dart';
import 'translations_pt.dart';
import 'translations_ru.dart';
import 'translations_hi.dart';
import 'translations_it.dart';
import 'translations_uk.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('es', ''), // Spanish
    Locale('fr', ''), // French
    Locale('de', ''), // German
    Locale('ja', ''), // Japanese
    Locale('ko', ''), // Korean
    Locale('zh', ''), // Chinese
    Locale('pt', ''), // Portuguese
    Locale('ru', ''), // Russian
    Locale('hi', ''), // Hindi
    Locale('it', ''), // Italian
    Locale('uk', ''), // Ukrainian
  ];

  // Common UI strings
  String get appTitle;
  String get explore;
  String get yourTwins;
  String get create;
  String get settings;
  String get exploreDigitalTwins;
  String get yourDigitalTwins;
  String get interactWithHistoricalFigures;
  String get noDigitalTwinsDetected;
  String get createNewTwinDescription;
  String get createNewTwin;
  String get yourDigitalTwin;
  String get darkMode;
  String get darkModeDescription;
  String get chatFontSize;
  String get chatFontSizeDescription;
  String get enableAnimations;
  String get enableAnimationsDescription;
  String get enableNotifications;
  String get enableNotificationsDescription;
  String get exportAllCharacters;
  String get exportAllCharactersDescription;
  String get clearAllData;
  String get clearAllDataDescription;
  String get appVersion;
  String get privacyPolicy;
  String get privacyPolicyDescription;
  String get customApiKey;
  String get customApiKeyDescription;
  String get chatWithDeveloper;
  String get chatWithDeveloperDescription;
  String get language;
  String get languageDescription;
  String get appearance;
  String get notifications;
  String get dataManagement;
  String get about;
  String get apiConnectivity;
  String get developerConnection;

  // Chat and interaction strings
  String get typeMessage;
  String get send;
  String get clearChat;
  String get clearChatConfirmation;
  String get cancel;
  String get clear;
  String get chatHistoryCleared;

  // Interview strings
  String get welcomeInterview;
  String get fileUploadOption;
  String get questionAnswerOption;
  String get agree;

  // Error messages
  String get errorConnecting;
  String get errorProcessingMessage;
  String get noApiKey;
  String get checkApiKey;

  // Language names for display
  String get languageEnglish;
  String get languageSpanish;
  String get languageFrench;
  String get languageGerman;
  String get languageJapanese;
  String get languageKorean;
  String get languageChinese;
  String get languagePortuguese;
  String get languageRussian;
  String get languageHindi;
  String get languageItalian;
  String get languageUkrainian;

  // System prompt language instruction
  String systemPromptLanguageInstruction(String language);

  // New strings from the code block
  String get accessingDataStorage;
  String get physicist;
  String get presidentActor;
  String get computerScientist;
  String get actressModelSinger;
  String get settingsDescription;
  String get privacyPolicyNotAvailable;
  String get apiKeyNote;
  String get clearAllDataConfirmation;
  String get deleteEverything;
  String get dataCleared;
  String get errorClearingData;

  // Chat screen strings
  String get startChattingWith;
  String get sendMessageToBegin;
  String get chat;
  String get viewProfile;
  String get you;
  String get clearChatHistory;
  String get clearChatHistoryTitle;
  String get clearChatHistoryConfirm;

  // Famous character profile screen
  String get noBiographyAvailable;
  String get profileOf;
  String get name;
  String get years;
  String get profession;
  String get biography;
  String get aiModel;
  String get viewAllModels;
  String get featureAvailableSoon;
  String get startConversation;
  String get recommended;
  String get aiModelUpdatedFor;

  // Famous character model dialog
  String get selectAiModelFor;
  String get chooseAiModelFor;
  String get select;

  // Onboarding strings
  String get backButton;
  String get nextButton;
  String get getStarted;
  String get understandMasks;
  String get digitalPersonas;
  String get theMindBehindTwins;
  String get poweredByAdvancedLanguageModels;
  String get howItWorks;
  String get twinsPoweredByAI;
  String get basicLLM;
  String get advancedLLM;
  String get localProcessing;
  String get cloudBased;
  String get goodForPrivacy;
  String get stateOfTheArt;
  String get limitedKnowledge;
  String get vastKnowledge;
  String get basicConversations;
  String get nuancedInteractions;
  String get questionsAboutAfterlife;
  String get chatWithDeveloperTwin;
  String get welcomeToAfterlife;
  String get chooseLanguage;
  String get continueButton;

  String get diversePerspectives;

  String get fromPoliticsToArt;

  String get engageWithDiverseFigures;

  String get rememberSimulations;

  String get createYourOwnTwins;

  // Additional LLM page strings
  String get exampleInteraction;
  String get whenDiscussingRelativityWithEinstein;
  String get withAdvancedLLMExample;
  String get withBasicLLMExample;
  String get withAdvancedLLMLabel;
  String get withBasicLLMLabel;
  String get deepKnowledge;

  // Mask page strings
  String get digitalPersonasWithHistoricalEssence;
  String get einsteinWithMaskAndLLMArmor;
  String get masksAreAIPersonas;
  String get eachMaskTriesToEmbody;
  String get theseDigitalTwinsAllow;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any((supportedLocale) => 
        supportedLocale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(_getLocalization(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;

  AppLocalizations _getLocalization(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
        return AppLocalizationsEs();
      case 'fr':
        return AppLocalizationsFr();
      case 'de':
        return AppLocalizationsDe();
      case 'ja':
        return AppLocalizationsJa();
      case 'ko':
        return AppLocalizationsKo();
      case 'zh':
        return AppLocalizationsZh();
      case 'pt':
        return AppLocalizationsPt();
      case 'ru':
        return AppLocalizationsRu();
      case 'hi':
        return AppLocalizationsHi();
      case 'it':
        return AppLocalizationsIt();
      case 'uk':
        return AppLocalizationsUk();
      default:
        return AppLocalizationsEn();
    }
  }
} 