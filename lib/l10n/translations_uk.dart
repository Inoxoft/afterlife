import 'dart:math';
import 'app_localizations.dart';

class AppLocalizationsUk extends AppLocalizations {
  @override String get appTitle => 'Afterlife';
  @override String get explore => 'Дослідити';
  @override String get yourTwins => 'Ваші Двійники';
  @override String get create => 'Створити';
  @override String get settings => 'Налаштування';
  @override String get exploreDigitalTwins => 'ДОСЛІДИТИ ЦИФРОВИХ ДВІЙНИКІВ';
  @override String get yourDigitalTwins => 'ВАШІ ЦИФРОВІ ДВІЙНИКИ';
  @override String get interactWithHistoricalFigures => 'Взаємодійте з історичними постатями через їхні маски';
  @override String get noDigitalTwinsDetected => 'ЦИФРОВИХ ДВІЙНИКІВ НЕ ВИЯВЛЕНО';
  @override String get createNewTwinDescription => 'Створіть нового цифрового двійника, щоб почати взаємодію з вашою збереженою свідомістю';
  @override String get createNewTwin => 'СТВОРИТИ НОВОГО ДВІЙНИКА';
  @override String get yourDigitalTwin => 'Ваш Цифровий Двійник';
  @override String get darkMode => 'Темний режим';
  @override String get darkModeDescription => 'Покращіть перегляд в умовах низького освітлення (Скоро)';
  @override String get chatFontSize => 'Розмір шрифту чату';
  @override String get chatFontSizeDescription => 'Налаштуйте розмір тексту в розмовах';
  @override String get enableAnimations => 'Увімкнути анімації';
  @override String get enableAnimationsDescription => 'Перемикання анімацій інтерфейсу та візуальних ефектів';
  @override String get enableNotifications => 'Увімкнути сповіщення';
  @override String get enableNotificationsDescription => 'Отримуйте сповіщення, коли цифрові двійники хочуть поспілкуватися';
  @override String get exportAllCharacters => 'Експортувати всіх персонажів';
  @override String get exportAllCharactersDescription => 'Зберегти ваших цифрових двійників у файл';
  @override String get clearAllData => 'Очистити всі дані';
  @override String get clearAllDataDescription => 'Видалити всіх персонажів і скинути додаток (Увага: незворотно)';
  @override String get appVersion => 'Версія додатку';
  @override String get privacyPolicy => 'Політика конфіденційності';
  @override String get privacyPolicyDescription => 'Дізнайтеся, як ми використовуємо та захищаємо ваші дані';
  @override String get customApiKey => 'Користувацький ключ API OpenRouter';
  @override String get customApiKeyDescription => 'Встановіть або оновіть ваш персональний ключ API';
  @override String get chatWithDeveloper => 'Чат з розробником';
  @override String get chatWithDeveloperDescription => 'Отримайте пряму підтримку та поділіться відгуками про додаток';
  @override String get language => 'Мова';
  @override String get languageDescription => 'Виберіть бажану мову для додатку та відповідей ШІ';
  @override String get appearance => 'Зовнішній вигляд';
  @override String get notifications => 'Сповіщення';
  @override String get dataManagement => 'Керування даними';
  @override String get about => 'Про додаток';
  @override String get apiConnectivity => 'API та підключення';
  @override String get developerConnection => "Зв'язок з розробником";
  @override String get typeMessage => 'Введіть повідомлення...';
  @override String get send => 'Надіслати';
  @override String get clearChat => 'Очистити чат';
  @override String get clearChatConfirmation => 'Усі повідомлення в цій розмові будуть видалені. Цю дію не можна скасувати.';
  @override String get cancel => 'Скасувати';
  @override String get clear => 'Очистити';
  @override String get chatHistoryCleared => 'Історію чату очищено';
  @override String get welcomeInterview => "Вітаємо! Я допоможу вам створити вашого цифрового двійника — глибокий, яскравий портрет вашої особистості, спогадів, цінностей та стилю.";
  @override String get fileUploadOption => "Завантажте файл з інформацією (PDF, TXT, DOC або електронні листи)";
  @override String get questionAnswerOption => "Дайте відповіді на запитання про вашу особистість та досвід";
  @override String get agree => 'Погоджуюсь';
  @override String get errorConnecting => "Вибачте, зараз виникла проблема з підключенням. Будь ласка, спробуйте пізніше.";
  @override String get errorProcessingMessage => "Вибачте, я не можу обробити ваше повідомлення зараз. Будь ласка, спробуйте пізніше.";
  @override String get noApiKey => 'Помилка: Неможливо підключитися до сервісу ШІ. Перевірте налаштування ключа API.';
  @override String get checkApiKey => 'Будь ласка, перевірте налаштування вашого ключа API.';
  @override String get languageEnglish => 'English';
  @override String get languageSpanish => 'Español';
  @override String get languageFrench => 'Français';
  @override String get languageGerman => 'Deutsch';
  @override String get languageJapanese => '日本語';
  @override String get languageKorean => '한국어';
  @override String get languageChinese => '中文';
  @override String get languagePortuguese => 'Português';
  @override String get languageRussian => 'Русский';
  @override String get languageHindi => 'हिन्दी';
  @override String get languageItalian => 'Italiano';
  @override String get languageUkrainian => 'Українська';
  @override String get accessingDataStorage => 'ДОСТУП ДО СХОВИЩА ДАНИХ';
  @override String get physicist => 'ФІЗИК';
  @override String get presidentActor => 'ПРЕЗИДЕНТ, АКТОР';
  @override String get computerScientist => 'СПЕЦІАЛІСТ З ІНФОРМАТИКИ';
  @override String get actressModelSinger => 'АКТОРКА, МОДЕЛЬ І СПІВАЧКА';
  @override String get settingsDescription => 'Налаштуйте свій досвід Afterlife';
  @override String get privacyPolicyNotAvailable => 'Політика конфіденційності недоступна в цій версії';
  @override String get apiKeyNote => 'Примітка: Ключ API за замовчуванням з файлу .env буде використаний як резервний варіант, якщо не надано користувацький ключ.';
  @override String get clearAllDataConfirmation => 'Це назавжди видалить всіх ваших персонажів і скине додаток до стану за замовчуванням. Цю дію неможливо скасувати.';
  @override String get deleteEverything => 'Видалити Все';
  @override String get dataCleared => 'Всі дані очищено';
  @override String get errorClearingData => 'Помилка очищення історії чату. Спробуйте ще раз.';
  @override String get startChattingWith => 'Почати чат з {name}';
  @override String get sendMessageToBegin => 'Надішліть повідомлення нижче, щоб почати розмову';
  @override String get chat => 'Чат';
  @override String get viewProfile => 'Переглянути Профіль';
  @override String get you => 'Ви';
  @override String get clearChatHistory => 'Очистити Історію Чату';
  @override String get clearChatHistoryTitle => 'Очистити Історію Чату';
  @override String get clearChatHistoryConfirm => 'Ви впевнені, що хочете очистити історію чату? Цю дію неможливо скасувати.';
  @override String get noBiographyAvailable => 'Біографія недоступна.';
  @override String get profileOf => 'Профіль {name}';
  @override String get name => 'Ім\'я';
  @override String get years => 'Роки';
  @override String get profession => 'Професія';
  @override String get biography => 'Біографія';
  @override String get aiModel => 'МОДЕЛЬ ШІ';
  @override String get viewAllModels => 'Переглянути Всі Моделі';
  @override String get featureAvailableSoon => 'Ця функція скоро буде доступна';
  @override String get startConversation => 'Почати Розмову';
  @override String get recommended => 'РЕКОМЕНДУЄТЬСЯ';
  @override String get aiModelUpdatedFor => 'Модель ШІ оновлена для {name}';
  @override String get selectAiModelFor => 'Вибрати Модель ШІ для {name}';
  @override String get chooseAiModelFor => 'Виберіть модель ШІ, яка керуватиме {name}:';
  @override String get select => 'ВИБРАТИ';
  @override String systemPromptLanguageInstruction(String language) {
    return "\n\nВАЖЛИВО: Будь ласка, завжди відповідайте українською мовою, якщо користувач не попросить явно змінити мову. Ваші відповіді мають бути природними та вільними українською мовою.";
  }

  // Onboarding strings
  @override
  String get backButton => 'НАЗАД';

  @override
  String get nextButton => 'ДАЛІ';

  @override
  String get getStarted => 'ПОЧАТИ';

  @override
  String get understandMasks => 'ЗРОЗУМІТИ МАСКИ';

  @override
  String get digitalPersonas => 'Цифрові персони з історичною сутністю';

  @override
  String get theMindBehindTwins => 'РОЗУМ ВАШИХ БЛИЗНЮКІВ';

  @override
  String get poweredByAdvancedLanguageModels => 'На основі продвинутих мовних моделей';

  @override
  String get howItWorks => 'Як це працює';

  @override
  String get twinsPoweredByAI => 'Ваші цифрові близнюки працюють на основі складних мовних моделей ШІ, які дозволяють їм думати, міркувати та взаємодіяти природно. Чим більш продвинута модель, тим більш автентичними та обізнаними будуть ваші взаємодії.';

  @override
  String get basicLLM => 'БАЗОВА LLM';

  @override
  String get advancedLLM => 'ПРОДВИНУТА LLM';

  @override
  String get localProcessing => 'Локальна обробка';

  @override
  String get cloudBased => 'Хмарна';

  @override
  String get goodForPrivacy => 'Добре для приватності';

  @override
  String get stateOfTheArt => 'Сучасна';

  @override
  String get limitedKnowledge => 'Обмежені знання';

  @override
  String get vastKnowledge => 'Широкі знання';

  @override
  String get basicConversations => 'Базові розмови';

  @override
  String get nuancedInteractions => 'Тонкі взаємодії';

  @override
  String get questionsAboutAfterlife => 'Питання про Afterlife?';

  @override
  String get chatWithDeveloperTwin => 'ЧАТ З БЛИЗНЮКОМ РОЗРОБНИКА';

  @override
  String get welcomeToAfterlife => 'Ласкаво просимо до Afterlife';

  @override
  String get chooseLanguage => 'Оберіть вашу мову для початку';

  @override
  String get continueButton => 'ПРОДОВЖИТИ';

  @override
  String get diversePerspectives => 'РІЗНОМАНІТНІ ПЕРСПЕКТИВИ';

  @override
  String get fromPoliticsToArt => 'Від політики до мистецтва, історія оживає';

  @override
  String get engageWithDiverseFigures => 'Взаємодійте з різноманітними постатями з політики, науки, мистецтва та інших сфер, які формували наш світ.';

  @override
  String get rememberSimulations => 'Пам\'ятайте, що це симуляції, засновані на доступних даних - відповіді представляють нашу найкращу спробу історичної точності.';

  @override
  String get createYourOwnTwins => 'Створюйте власних цифрових близнюків за допомогою кнопки "Створити" в нижній навігації.';

  @override
  String get exampleInteraction => 'Приклад Взаємодії';

  @override
  String get whenDiscussingRelativityWithEinstein => 'При обговоренні теорії відносності з Ейнштейном:';

  @override
  String get withAdvancedLLMExample => '"Дозвольте мені пояснити, як кривизна простору-часу впливає на гравітаційні лінзи, і чому це було важливо для експериментального підтвердження загальної теорії відносності..."';

  @override
  String get withBasicLLMExample => '"Ну, E=mc² важливо для теорії відносності, але я не можу пояснити глибші наслідки або математичну основу..."';

  @override
  String get deepKnowledge => 'Глибока Експертиза';

  @override
  String get withAdvancedLLMLabel => 'З продвинутою LLM:';

  @override
  String get withBasicLLMLabel => 'З базовою LLM:';

  // Mask page strings
  @override
  String get digitalPersonasWithHistoricalEssence => 'Цифрові персони з історичною сутністю';

  @override
  String get einsteinWithMaskAndLLMArmor => 'Ейнштейн з маскою та обладунками LLM';

  @override
  String get masksAreAIPersonas => 'Маски - це персони ШІ, створені з історичних даних, особистих записів та детальних характеристик персонажів.';

  @override
  String get eachMaskTriesToEmbody => 'Кожна маска намагається втілити справжній характер, особистість та знання своєї історичної постаті.';

  @override
  String get theseDigitalTwinsAllow => 'Ці цифрові близнюки дозволяють вам взаємодіяти з перспективами через час та реальність.';
  // Splash screen status messages
  @override
  String get initializingPreservationSystems => 'INITIALIZING PRESERVATION SYSTEMS';

  @override
  String get calibratingNeuralNetworks => 'CALIBRATING NEURAL NETWORKS';

  @override
  String get synchronizingQuantumStates => 'SYNCHRONIZING QUANTUM STATES';

  @override
  String get aligningConsciousnessMatrices => 'ALIGNING CONSCIOUSNESS MATRICES';

  @override
  String get establishingNeuralLinks => 'ESTABLISHING NEURAL LINKS';

  @override
  String get preservationSystemsReady => 'PRESERVATION SYSTEMS READY';

  @override
  String get errorInitializingSystems => 'ERROR INITIALIZING SYSTEMS';

  // Error messages and user feedback
  @override
  String get restartApp => 'Restart App';

  @override
  String get initializationError => 'Initialization Error';

  @override
  String get apiKeyCannotBeEmpty => 'API key cannot be empty';

  @override
  String get changesSavedSuccessfully => 'Changes saved successfully';

  @override
  String get characterUpdatedSuccessfully => 'Character updated successfully';

  @override
  String get characterCardCopiedToClipboard => 'Character card copied to clipboard';

  @override
  String get charactersExportedSuccessfully => 'Characters exported successfully!';

  @override
  String get errorExportingCharacters => 'Error exporting characters';

  @override
  String get errorSavingApiKey => 'Error saving API key';

  @override
  String get errorLoadingCharacter => 'Error loading character';

  @override
  String get failedToSaveSettings => 'Failed to save settings';

  @override
  String get apiKeyUpdatedSuccessfully => 'API key updated successfully';

  // Dialog boxes and confirmations
  @override
  String get restartInterview => 'Restart Interview';

  @override
  String get clearResponsesConfirmation => 'This will clear all your responses. Are you sure?';

  @override
  String get deleteCharacter => 'Delete Character';

  @override
  String get deleteCharacterConfirmation => 'This action cannot be undone.';

  @override
  String get characterProfile => 'Character Profile';

  @override
  String get editCharacter => 'Edit Character';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  // API Key Dialog
  @override
  String get openRouterApiKey => 'OpenRouter API Key';

  @override
  String get apiKeyRequired => 'API Key Required';

  @override
  String get updateApiKeyDescription => 'Update your OpenRouter API key for AI functionality:';

  @override
  String get apiKeyRequiredDescription => 'The application requires an OpenRouter API key to function. Please enter your API key below:';

  @override
  String get enterApiKey => 'Enter API Key (sk-...)';

  @override
  String get clearCurrentKey => 'Clear current key';

  @override
  String get getApiKeyFromOpenRouter => 'You can get an API key from openrouter.ai';

  @override
  String get usingCustomApiKey => 'Using your custom API key';

  @override
  String get replaceKeyInstructions => 'To replace with a different key, clear the field first and enter new key';

  @override
  String get apiKeyShouldStartWithSk => 'API key should start with "sk-"';

  // Interview and character creation
  @override
  String get invalidCharacterCardFormat => 'Invalid character card format';

  @override
  String get characterDataIncomplete => 'Character data is incomplete';

  @override
  String get failedToSaveCharacter => 'Failed to save character';

  @override
  String get characterProfileNotFound => 'Character profile not found';

  @override
  String get errorSavingCharacter => 'Error saving character';

  // Generic error messages with parameters
  @override
  String errorLoadingCharacterWithDetails(String error) => 'Error loading character: $error';

  @override
  String errorSavingApiKeyWithDetails(String error) => 'Error saving API key: $error';

  @override
  String errorRemovingApiKeyWithDetails(String error) => 'Error removing API key: $error';

  @override
  String failedToSaveSettingsWithDetails(String error) => 'Failed to save settings: $error';

  @override
  String aiModelUpdatedForCharacter(String characterName) => 'AI model updated for $characterName';

  @override
  String characterCardCopiedForCharacter(String characterName) => 'Character card for "$characterName" copied to clipboard';

  @override
  String errorUpdatingModel(String error) => 'Error updating model: $error';

  @override
  String errorSavingCharacterWithDetails(String error) => 'Error saving character: $error';

  @override
  String errorClearingDataWithDetails(String error) => 'Error clearing data: $error';

  @override
  String errorExportingCharactersWithDetails(String error) => 'Error exporting characters: $error';
  // Additional UI strings
  @override
  String get skipForNow => 'Skip for now';

  @override
  String get updateKey => 'Update Key';

  @override
  String get removeKey => 'Remove Key';

  @override
  String get saveKey => 'Save Key';

  @override
  String get usingDefaultApiKey => 'Using default API key from .env file';
} 