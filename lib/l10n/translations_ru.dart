import 'dart:math';
import 'app_localizations.dart';

class AppLocalizationsRu extends AppLocalizations {
  @override String get appTitle => 'Afterlife';
  @override String get explore => 'Исследовать';
  @override String get yourTwins => 'Ваши Двойники';
  @override String get create => 'Создать';
  @override String get settings => 'Настройки';
  @override String get exploreDigitalTwins => 'Исследовать Цифровых Двойников';
  @override String get yourDigitalTwins => 'Ваши Цифровые Двойники';
  @override String get interactWithHistoricalFigures => 'Взаимодействуйте с историческими личностями через маски';
  @override String get noDigitalTwinsDetected => 'Цифровые двойники не обнаружены';
  @override String get createNewTwinDescription => 'Создайте нового цифрового двойника, чтобы начать взаимодействие с вашим сохраненным сознанием';
  @override String get createNewTwin => 'Создать Нового Двойника';
  @override String get yourDigitalTwin => 'Ваш Цифровой Двойник';
  @override String get darkMode => 'Темный режим';
  @override String get darkModeDescription => 'Улучшить восприятие в условиях слабого освещения (Скоро)';
  @override String get chatFontSize => 'Размер шрифта чата';
  @override String get chatFontSizeDescription => 'Настроить размер текста в разговорах чата';
  @override String get enableAnimations => 'Включить анимации';
  @override String get enableAnimationsDescription => 'Переключить анимации интерфейса и визуальные эффекты';
  @override String get enableNotifications => 'Включить уведомления';
  @override String get enableNotificationsDescription => 'Получать уведомления, когда цифровые двойники хотят поговорить';
  @override String get exportAllCharacters => 'Экспортировать всех персонажей';
  @override String get exportAllCharactersDescription => 'Сохранить ваших цифровых двойников в файл';
  @override String get clearAllData => 'Очистить все данные';
  @override String get clearAllDataDescription => 'Удалить всех персонажей и сбросить приложение (Предупреждение: необратимо)';
  @override String get appVersion => 'Версия приложения';
  @override String get privacyPolicy => 'Политика Конфиденциальности';
  @override String get privacyPolicyDescription => 'Прочитайте, как мы используем и защищаем ваши данные';
  @override String get customApiKey => 'Пользовательский ключ API OpenRouter';
  @override String get customApiKeyDescription => 'Установить или обновить ваш личный ключ API';
  @override String get chatWithDeveloper => 'Чат с Разработчиком';
  @override String get chatWithDeveloperDescription => 'Получите прямую поддержку и поделитесь отзывами о приложении';
  @override String get language => 'Язык';
  @override String get languageDescription => 'Выберите предпочитаемый язык для приложения и ответов ИИ';
  @override String get appearance => 'Внешний вид';
  @override String get notifications => 'Уведомления';
  @override String get dataManagement => 'Управление данными';
  @override String get about => 'О приложении';
  @override String get apiConnectivity => 'API и подключение';
  @override String get developerConnection => 'Связь с разработчиком';
  @override String get typeMessage => 'Введите сообщение...';
  @override String get send => 'Отправить';
  @override String get clearChat => 'Очистить чат';
  @override String get clearChatConfirmation => 'Все сообщения в этом разговоре будут удалены. Это действие нельзя отменить.';
  @override String get cancel => 'Отмена';
  @override String get clear => 'Очистить';
  @override String get chatHistoryCleared => 'История чата очищена';
  @override String get welcomeInterview => "Добро пожаловать! Я помогу вам создать вашего цифрового двойника — глубокий, яркий портрет вашей личности, воспоминаний, ценностей и стиля.";
  @override String get fileUploadOption => "Загрузите файл с информацией (PDF, TXT, DOC или электронные письма)";
  @override String get questionAnswerOption => "Ответьте на вопросы о вашей личности и опыте";
  @override String get agree => 'Согласен';
  @override String get errorConnecting => "Извините, сейчас проблемы с подключением. Пожалуйста, попробуйте позже.";
  @override String get errorProcessingMessage => "Извините, я не могу обработать ваше сообщение сейчас. Пожалуйста, попробуйте позже.";
  @override String get noApiKey => 'Ошибка: Не удается подключиться к сервису ИИ. Проверьте конфигурацию ключа API.';
  @override String get checkApiKey => 'Пожалуйста, проверьте настройки вашего ключа API.';
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
  @override String get accessingDataStorage => 'ДОСТУП К ХРАНИЛИЩУ ДАННЫХ';
  @override String get physicist => 'ФИЗИК';
  @override String get presidentActor => 'ПРЕЗИДЕНТ, АКТЁР';
  @override String get computerScientist => 'ИНФОРМАТИК';
  @override String get actressModelSinger => 'АКТРИСА, МОДЕЛЬ И ПЕВИЦА';
  @override String get settingsDescription => 'Настройте свой опыт в Afterlife';
  @override String get privacyPolicyNotAvailable => 'Политика конфиденциальности недоступна в этой версии';
  @override String get apiKeyNote => 'Примечание: Ключ API по умолчанию из файла .env будет использован как резервный, если не предоставлен пользовательский ключ.';
  @override String get clearAllDataConfirmation => 'Это навсегда удалит всех персонажей и сбросит приложение к состоянию по умолчанию. Это действие нельзя отменить.';
  @override String get deleteEverything => 'Удалить всё';
  @override String get dataCleared => 'Все данные очищены';
  @override String get errorClearingData => 'Ошибка при очистке истории чата. Попробуйте снова.';
  @override String get startChattingWith => 'Начать чат с {name}';
  @override String get sendMessageToBegin => 'Отправьте сообщение ниже, чтобы начать разговор';
  @override String get chat => 'Чат';
  @override String get viewProfile => 'Посмотреть профиль';
  @override String get you => 'Вы';
  @override String get clearChatHistory => 'Очистить историю чата';
  @override String get clearChatHistoryTitle => 'Очистить историю чата';
  @override String get clearChatHistoryConfirm => 'Вы хотите очистить историю чата? Это действие нельзя отменить.';
  @override String get noBiographyAvailable => 'Биография недоступна.';
  @override String get profileOf => 'Профиль {name}';
  @override String get name => 'Имя';
  @override String get years => 'Годы';
  @override String get profession => 'Профессия';
  @override String get biography => 'Биография';
  @override String get aiModel => 'ИИ модель';
  @override String get viewAllModels => 'Посмотреть все модели';
  @override String get featureAvailableSoon => 'Эта функция скоро будет доступна';
  @override String get startConversation => 'Начать разговор';
  @override String get recommended => 'Рекомендуется';
  @override String get aiModelUpdatedFor => 'ИИ модель для {name} обновлена';
  @override String get selectAiModelFor => 'Выбрать ИИ модель для {name}';
  @override String get chooseAiModelFor => 'Выберите ИИ модель для {name}:';
  @override String get select => 'Выбрать';
  @override String systemPromptLanguageInstruction(String language) {
    return "\n\nВажно: Всегда отвечайте на русском языке ($language), если пользователь явно не запросит смену языка. Ответы должны быть естественными и беглыми на русском языке.";
  }

  // Onboarding strings
  @override
  String get backButton => 'Назад';

  @override
  String get nextButton => 'Далее';

  @override
  String get getStarted => 'Начать';

  @override
  String get understandMasks => 'Понимание масок';

  @override
  String get digitalPersonas => 'Цифровые персоны с исторической сущностью';

  @override
  String get theMindBehindTwins => 'Разум за вашими близнецами';

  @override
  String get poweredByAdvancedLanguageModels => 'Работает на продвинутых языковых моделях';

  @override
  String get howItWorks => 'Как это работает';

  @override
  String get twinsPoweredByAI => 'Ваши цифровые близнецы работают на сложных языковых моделях ИИ, которые позволяют им естественно думать, рассуждать и взаимодействовать. Чем более продвинута модель, тем более аутентичными и знающими будут взаимодействия.';

  @override
  String get basicLLM => 'Базовая LLM';

  @override
  String get advancedLLM => 'Продвинутая LLM';

  @override
  String get localProcessing => 'Локальная обработка';

  @override
  String get cloudBased => 'Облачная';

  @override
  String get goodForPrivacy => 'Хорошо для приватности';

  @override
  String get stateOfTheArt => 'Передовая';

  @override
  String get limitedKnowledge => 'Ограниченные знания';

  @override
  String get vastKnowledge => 'Обширные знания';

  @override
  String get basicConversations => 'Базовые разговоры';

  @override
  String get nuancedInteractions => 'Тонкие взаимодействия';

  @override
  String get questionsAboutAfterlife => 'Вопросы об Afterlife?';

  @override
  String get chatWithDeveloperTwin => 'Чат с близнецом разработчика';

  @override
  String get welcomeToAfterlife => 'Добро пожаловать в Afterlife';

  @override
  String get chooseLanguage => 'Выберите язык для начала';

  @override
  String get continueButton => 'ПРОДОЛЖИТЬ';

  @override
  String get diversePerspectives => 'РАЗНООБРАЗНЫЕ ПЕРСПЕКТИВЫ';

  @override
  String get fromPoliticsToArt => 'От политики до искусства, история оживает';

  @override
  String get engageWithDiverseFigures => 'Взаимодействуйте с разнообразными фигурами из политики, науки, искусства и другого, которые формировали наш мир.';

  @override
  String get rememberSimulations => 'Помните, что это симуляции, основанные на доступных данных - ответы представляют нашу лучшую попытку исторической точности.';

  @override
  String get createYourOwnTwins => 'Создавайте собственных цифровых близнецов с помощью кнопки "Создать" в нижней навигации.';

  @override
  String get exampleInteraction => 'Пример Взаимодействия';

  @override
  String get whenDiscussingRelativityWithEinstein => 'При обсуждении теории относительности с Эйнштейном:';

  @override
  String get withAdvancedLLMExample => '"Позвольте мне объяснить, как кривизна пространства-времени влияет на гравитационные линзы, и почему это было важно для экспериментального подтверждения общей теории относительности..."';

  @override
  String get withBasicLLMExample => '"Ну, E=mc² важно для теории относительности, но я не могу объяснить более глубокие последствия или математическую основу..."';

  @override
  String get deepKnowledge => 'Глубокая экспертиза';

  @override
  String get withAdvancedLLMLabel => 'С продвинутой LLM:';

  @override
  String get withBasicLLMLabel => 'С базовой LLM:';

  // Mask page strings
  @override
  String get digitalPersonasWithHistoricalEssence => 'Цифровые персоны с исторической сущностью';

  @override
  String get einsteinWithMaskAndLLMArmor => 'Эйнштейн с маской и броней LLM';

  @override
  String get masksAreAIPersonas => 'Маски - это персоны ИИ, созданные на основе исторических данных, личных записей и детальных характеристик персонажей.';

  @override
  String get eachMaskTriesToEmbody => 'Каждая маска пытается воплотить подлинный характер, личность и знания своей исторической фигуры.';

  @override
  String get theseDigitalTwinsAllow => 'Эти цифровые близнецы позволяют вам взаимодействовать с перспективами через время и реальность.';
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
  // Interview initial message
  @override
  String get interviewInitialMessage => 'Привет! Я готов создать подробную карточку персонажа для вас. Вы можете выбрать:\n\n1. Ответить на мои вопросы о вашей личности и опыте\n2. Загрузить файл (PDF, TXT, DOC или электронную почту) с вашей информацией\n\nЧто бы вы предпочли?';
} 