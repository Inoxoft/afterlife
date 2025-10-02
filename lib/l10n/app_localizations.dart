import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'translations_en.dart';
import 'translations_es.dart';
import 'translations_fr.dart';
import 'translations_de.dart';
import 'translations_ja.dart';
import 'translations_ko.dart';
import 'translations_it.dart';
import 'translation_uk.dart';
import 'translations_ru.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('es', ''), // Spanish
    Locale('fr', ''), // French
    Locale('de', ''), // German
    Locale('it', ''), // Italian
    Locale('ja', ''), // Japanese
    Locale('ko', ''), // Korean
    Locale('uk', ''), // Ukrainian
    Locale('ru', ''), // Russian
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
  String get languageItalian;
  String get languageJapanese;
  String get languageKorean;
  String get languageUkrainian;
  String get languageRussian;

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

  // Character professions
  String get basketballPlayer;
  String get musicianSinger;
  String get politicalLeaderActivist;
  String get martialArtistActor;
  String get civilRightsLeader;
  String get physicistChemist;
  String get usPresident;
  String get egyptianPharaoh;
  String get djMusicProducer;
  String get rapperActor;
  String get musicianArtist;
  String get theoreticalPhysicist;
  String get singerActor;
  String get britishPrimeMinister;
  String get inventorEngineer;
  String get playwrightPoet;
  String get romanGeneralDictator;
  String get techEntrepreneur;
  String get britishRoyalHumanitarian;
  String get singerPerformer;
  String get boxerActivist;
  String get astronomerScienceCommunicator;
  String get independenceLeader;
  String get painter;
  String get polymathArtist;
  String get philosopher;

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

  // Setup Guide Page strings
  String get gettingStarted;
  String get chooseYourAiExperience;
  String get cloudAiModels;
  String get bestQualityRequiresInternet;
  String get accessToGptClaudeAndMore;
  String get advancedReasoningAndKnowledge;
  String get alwaysUpToDateInformation;
  String get fastResponses;
  String get setUpApiKey;
  String get getFreeApiKeyAt;
  String get addCreditToUseAdvancedModels;
  String get openRouterRequiresCredits;
  String get localAiModel;
  String get privateWorksOffline;
  String get completePrivacyDataStaysLocal;
  String get worksWithoutInternet;
  String get hammerModelSize;
  String get optimizedForMobileDevices;
  String get downloadModel;
  String get freeDownloadNoAccountRequired;
  String get youCanUseBoth;
  String get setBothOptionsAutoChoose;
  String get canSetupLaterInSettings;
  String get apiKeySavedCanChat;
  String get pleaseOpenBrowserVisit;

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

  // Apple Intelligence (iOS) onboarding strings
  String get appleIntelligenceTitle;
  String get appleIntelligenceSubtitle;
  String get appleOnDevicePrivacy;
  String get appleNoCloudCalls;
  String get applePoweredByFoundationModels;
  String get appleInstantSetup;
  String get applePrivacyNote;

  // Mask page strings
  String get digitalPersonasWithHistoricalEssence;
  String get einsteinWithMaskAndLLMArmor;
  String get masksAreAIPersonas;
  String get eachMaskTriesToEmbody;
  String get theseDigitalTwinsAllow;

  // Character Profile screen strings
  String get characterProfile;
  String get editCharacter;
  String get characterPrompts;
  String get fullDetailedPrompt;
  String get usedForCloudAiModels;
  String get optimizedLocalPrompt;
  String get usedForLocalModels;
  String get apiModels;
  String get localModel;
  String get copyPrompt;
  String get promptCopiedToClipboard;
  String get startChat;
  String get selectCharacterIcon;
  String get removeIcon;
  String get useFirstLetter;
  String get characterImage;
  String get chooseFromGallery;
  String get removeCurrentImage;
  String get imageGuidelines;
  String get imageGuidelinesText;
  String get characterIconImage;
  String get chooseIconFromGallery;
  String get removeIconImage;
  String get changesSavedSuccessfully;
  String get errorSavingChanges;
  String get characterUpdatedSuccessfully;
  String get errorUpdatingCharacter;
  String get viewAllAvailableModels;
  String get exploreMoreAiOptions;
  String get privacyFirstLocalAi;
  String get speedMultimodalSupport;
  String get lightweightInstructionTuned;
  String get requiresModelDownload;
  String get noInternetNeeded;
  String get selectAiModel;
  String get chooseAiModelThatWillPower;
  String get aiModelUpdatedSuccessfully;
  String get reinterview;
  String get reinterviewDescription;

  // Splash screen status messages
  String get initializingPreservationSystems;
  String get calibratingNeuralNetworks;
  String get synchronizingQuantumStates;
  String get aligningConsciousnessMatrices;
  String get establishingNeuralLinks;
  String get preservationSystemsReady;
  String get errorInitializingSystems;

  // Error messages and user feedback
  String get restartApp;
  String get initializationError;
  String get apiKeyCannotBeEmpty;
  String get characterCardCopiedToClipboard;
  String get charactersExportedSuccessfully;
  String get errorExportingCharacters;
  String get errorSavingApiKey;
  String get errorLoadingCharacter;
  String get failedToSaveSettings;
  String get apiKeyUpdatedSuccessfully;

  // Dialog boxes and confirmations
  String get restartInterview;
  String get clearResponsesConfirmation;
  String get deleteCharacter;
  String get deleteCharacterConfirmation;
  String get delete;
  String get save;
  String get edit;

  // API Key Dialog
  String get openRouterApiKey;
  String get apiKeyRequired;
  String get updateApiKeyDescription;
  String get apiKeyRequiredDescription;
  String get enterApiKey;
  String get clearCurrentKey;
  String get getApiKeyFromOpenRouter;
  String get usingCustomApiKey;
  String get replaceKeyInstructions;
  String get apiKeyShouldStartWithSk;
  String get howToGetApiKey;
  String get visitOpenRouterAndSignUp;
  String get goToKeysSection;
  String get createNewApiKey;
  String get getApiKeyHere;
  String get updateKey;

  // Interview and character creation
  String get invalidCharacterCardFormat;
  String get characterDataIncomplete;
  String get failedToSaveCharacter;
  String get characterProfileNotFound;
  String get errorSavingCharacter;

  // Generic error messages with parameters
  String errorLoadingCharacterWithDetails(String error);
  String errorSavingApiKeyWithDetails(String error);
  String errorRemovingApiKeyWithDetails(String error);
  String failedToSaveSettingsWithDetails(String error);
  String aiModelUpdatedForCharacter(String characterName);
  String characterCardCopiedForCharacter(String characterName);
  String errorUpdatingModel(String error);
  String errorSavingCharacterWithDetails(String error);
  String errorClearingDataWithDetails(String error);
  String errorExportingCharactersWithDetails(String error);

  // Additional UI strings
  String get skipForNow;
  String get removeKey;
  String get saveKey;
  String get usingDefaultApiKey;
  String get exportChat;

  // Interview initial message
  String get interviewInitialMessage;

  // Additional methods from Spanish translation that need to be in base class
  String get selectIcon;
  String get selectImage;
  String get selectImageFromGallery;
  String get selectCharacterImage;
  String get openRouterGpt4o;
  String get openRouterClaude35Sonnet;
  String get openRouterGpt4Turbo;
  String get openRouterGeminiPro;
  String get mistralLarge;
  String get localGemma2b;
  String get private;

  // Famous character bios
  String get einsteinBio;
  String get reaganBio;
  String get turingBio;
  String get monroeBio;
  String get kobeBryantBio;
  String get kurtCobainBio;
  String get nelsonMandelaBio;
  String get bobMarleyBio;
  String get bruceLeeBio;
  String get martinLutherKingJrBio;
  String get marieCurieBio;
  String get abrahamLincolnBio;
  String get cleopatraBio;
  String get aviciiBio;
  String get tupacShakurBio;
  String get davidBowieBio;
  String get stephenHawkingBio;
  String get elvisPresleyBio;
  String get winstonChurchillBio;
  String get nikolaTeslaBio;
  String get williamShakespeareBio;
  String get juliusCaesarBio;
  String get steveJobsBio;
  String get princessDianaBio;
  String get freddieMercuryBio;
  String get muhammadAliBio;
  String get carlSaganBio;
  String get mahatmaGandhiBio;
  String get vincentVanGoghBio;
  String get leonardoDaVinciBio;
  String get socratesBio;

  // Date and time strings
  String get created;
  String get today;
  String get yesterday;
  String get daysAgo;

  // Interview screen specific
  String get creatingYourDigitalTwin;
  String get editingCharacter;
  String get uploadCharacterFile;
  String get typeYourMessage;
  String get processingFiles;
  String get noFilesSelected;
  String get processingFileProgress;
  String get characterCardReady;
  String get reviewCharacterCard;
  String get finalizeCharacter;
  String get interviewComplete;
  String get interviewCompleteDescription;
  String get updateCharacter;
  String get continueToGallery;
  String get restartInterviewConfirmation;
  String get restart;
  String get whichWouldYouPrefer;
  String get interviewWelcomeMessage;

  // Group Chat
  String get createGroupChat;
  String get editGroupChat;
  String get groupName;
  String get enterGroupName;
  String get selectedCharacters;
  String get famousCharacters;
  String get yourCharacters;
  String get noFamousCharacters;
  String get noUserCharacters;
  String get createGroup;
  String get updateGroup;
  String get groupCreationError;
  String get groupCreationFailed;
  String get groupChats;
  String get noGroupChats;
  String get createFirstGroup;
  String get startGroupChat;
  String get addMembers;
  String get removeMembers;
  String get leaveGroup;
  String get deleteGroup;
  String get groupSettings;
  String get conversationStarters;
  String get charactersTyping;
  String get characterTyping;
  String get sendMessage;
  String get groupChatWith;
  String get lastActive;
  String get membersCount;
  String get messageCount;
  String get goBack;
  String get retry;
  String get groupsCreated;
  String get members;
  String get messages;
  String get createFirstGroupChat;
  String get openChat;
  String get editGroup;

  // Local LLM Settings
  String get localAiSettings;
  String get huggingFaceAccessToken;
  String get tokenIsSet;
  String get pasteHuggingFaceToken;
  String get hfTokenPlaceholder;
  String get hfTokenHint;
  String get saveToken;
  String get clearToken;
  String get getToken;
  String get status;
  String get size;
  String get supportsImages;
  String get maxTokens;
  String get yes;
  String get no;
  String get notDownloaded;
  String get downloading;
  String get ready;
  String get error;
  String get downloadingProgress;
  String get modelManagement;
  // Model localization
  String get localLlama32;
  String get localLlama32Description;
  String get gemmaModelReady;
  String get deleteModel;
  String get downloadModelSection;
  String get downloadGemmaModel;
  String get modelRequiresLicense;
  String get requiresHfLogin;
  String get storageSpaceNeeded;
  String get runsLocallyPrivacy;
  String get optimizedMobileInference;
  String get openLicensePage;
  String get openHfTokens;
  String get cancelDownload;
  String get downloadGemmaModelButton;
  String get deleteModelConfirmation;
  String get huggingFaceTokenSaved;
  String get tokenCleared;
  String get localLlmSettingsSaved;
  String get modelDownloadedSuccessfully;
  String get modelDownloadFailed;
  String get modelDeletedSuccessfully;
  String get downloadCancelledByUser;
  String get localAiSettingsDescription;
  String failedToLoadSettings(String error);
  String failedToSaveToken(String error);
  String failedToDownloadModel(String error);
  String failedToDeleteModel(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
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
      case 'it':
        return AppLocalizationsIt();
      case 'uk':
        return AppLocalizationsUk();
      case 'ru':
        return AppLocalizationsRu();
      default:
        return AppLocalizationsEn();
    }
  }
}
