import 'dart:math';
import 'app_localizations.dart';

class AppLocalizationsJa extends AppLocalizations {
  @override String get appTitle => 'Afterlife';
  @override String get explore => '探索';
  @override String get yourTwins => 'あなたのツイン';
  @override String get create => '作成';
  @override String get settings => '設定';
  @override String get exploreDigitalTwins => 'デジタルツインを探索';
  @override String get yourDigitalTwins => 'あなたのデジタルツイン';
  @override String get interactWithHistoricalFigures => 'マスクを通して歴史上の人物と交流する';
  @override String get noDigitalTwinsDetected => 'デジタルツインが検出されませんでした';
  @override String get createNewTwinDescription => '新しいデジタルツインを作成して、保存された意識と交流を始めましょう';
  @override String get createNewTwin => '新しいツインを作成';
  @override String get yourDigitalTwin => 'あなたのデジタルツイン';
  @override String get darkMode => 'ダークモード';
  @override String get darkModeDescription => '低照度環境での視聴体験を向上させます（近日公開）';
  @override String get chatFontSize => 'チャットフォントサイズ';
  @override String get chatFontSizeDescription => 'チャット会話のテキストサイズを調整';
  @override String get enableAnimations => 'アニメーションを有効にする';
  @override String get enableAnimationsDescription => 'インターフェースアニメーションと視覚効果を切り替え';
  @override String get enableNotifications => '通知を有効にする';
  @override String get enableNotificationsDescription => 'デジタルツインがチャットしたいときに通知を受け取る';
  @override String get exportAllCharacters => 'すべてのキャラクターをエクスポート';
  @override String get exportAllCharactersDescription => 'デジタルツインをファイルに保存';
  @override String get clearAllData => 'すべてのデータをクリア';
  @override String get clearAllDataDescription => 'すべてのキャラクターを削除してアプリをリセット（注意：元に戻せません）';
  @override String get appVersion => 'アプリバージョン';
  @override String get privacyPolicy => 'プライバシーポリシー';
  @override String get privacyPolicyDescription => 'データの使用と保護方法を読む';
  @override String get customApiKey => 'カスタムOpenRouter APIキー';
  @override String get customApiKeyDescription => '個人のAPIキーを設定または更新';
  @override String get chatWithDeveloper => '開発者とチャット';
  @override String get chatWithDeveloperDescription => '直接サポートを受け、アプリについてのフィードバックを共有';
  @override String get language => '言語';
  @override String get languageDescription => 'アプリとAI応答の優先言語を選択';
  @override String get appearance => '外観';
  @override String get notifications => '通知';
  @override String get dataManagement => 'データ管理';
  @override String get about => 'について';
  @override String get apiConnectivity => 'API＆接続';
  @override String get developerConnection => '開発者接続';
  @override String get typeMessage => 'メッセージを入力...';
  @override String get send => '送信';
  @override String get clearChat => 'チャットをクリア';
  @override String get clearChatConfirmation => 'この会話のすべてのメッセージが削除されます。この操作は元に戻せません。';
  @override String get cancel => 'キャンセル';
  @override String get clear => 'クリア';
  @override String get chatHistoryCleared => 'チャット履歴がクリアされました';
  @override String get welcomeInterview => "ようこそ！あなたのデジタルツイン作成をお手伝いします。あなたの個性、記憶、価値観、スタイルの深く鮮明な肖像を作りましょう。";
  @override String get fileUploadOption => "あなたの情報を含むファイル（PDF、TXT、DOC、またはメール）をアップロード";
  @override String get questionAnswerOption => "あなたの個性と経験についての質問に答える";
  @override String get agree => '同意する';
  @override String get errorConnecting => "申し訳ありませんが、現在接続に問題があります。後でもう一度お試しください。";
  @override String get errorProcessingMessage => "申し訳ありませんが、現在メッセージを処理できませんでした。後でもう一度お試しください。";
  @override String get noApiKey => 'エラー：AIサービスに接続できません。APIキーの設定を確認してください。';
  @override String get checkApiKey => 'APIキーの設定を確認してください。';
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
  @override String get accessingDataStorage => 'データストレージにアクセス中';
  @override String get physicist => '物理学者';
  @override String get presidentActor => '大統領、俳優';
  @override String get computerScientist => 'コンピューター科学者';
  @override String get actressModelSinger => '女優、モデル＆歌手';
  @override String get settingsDescription => 'Afterlife体験をカスタマイズ';
  @override String get privacyPolicyNotAvailable => 'このバージョンではプライバシーポリシーは利用できません';
  @override String get apiKeyNote => '注意：カスタムキーが提供されていない場合、.envファイルのデフォルトAPIキーがフォールバックとして使用されます。';
  @override String get clearAllDataConfirmation => 'これにより、すべてのキャラクターが永続的に削除され、アプリがデフォルト状態にリセットされます。この操作は元に戻せません。';
  @override String get deleteEverything => 'すべて削除';
  @override String get dataCleared => 'すべてのデータがクリアされました';
  @override String get errorClearingData => 'チャット履歴のクリア中にエラーが発生しました。もう一度お試しください。';
  @override String get startChattingWith => '{name}とチャットを始める';
  @override String get sendMessageToBegin => '下にメッセージを送信して会話を開始してください';
  @override String get chat => 'チャット';
  @override String get viewProfile => 'プロフィールを表示';
  @override String get you => 'あなた';
  @override String get clearChatHistory => 'チャット履歴をクリア';
  @override String get clearChatHistoryTitle => 'チャット履歴をクリア';
  @override String get clearChatHistoryConfirm => 'チャット履歴をクリアしてもよろしいですか？この操作は元に戻せません。';
  @override String get noBiographyAvailable => '利用可能な伝記はありません。';
  @override String get profileOf => '{name}のプロフィール';
  @override String get name => '名前';
  @override String get years => '年';
  @override String get profession => '職業';
  @override String get biography => '伝記';
  @override String get aiModel => 'AIモデル';
  @override String get viewAllModels => 'すべてのモデルを表示';
  @override String get featureAvailableSoon => 'この機能は近日利用可能になります';
  @override String get startConversation => '会話を開始';
  @override String get recommended => '推奨';
  @override String get aiModelUpdatedFor => '{name}のAIモデルが更新されました';
  @override String get selectAiModelFor => '{name}のAIモデルを選択';
  @override String get chooseAiModelFor => '{name}を動かすAIモデルを選択してください：';
  @override String get select => '選択';
  @override String systemPromptLanguageInstruction(String language) {
    return "\n\n重要：ユーザーが明示的に言語を変更するよう求めない限り、常に日本語（$language）で回答してください。回答は日本語で自然で流暢でなければなりません。";
  }

  // Onboarding strings
  @override
  String get backButton => '戻る';

  @override
  String get nextButton => '次へ';

  @override
  String get getStarted => '開始';

  @override
  String get understandMasks => 'マスクを理解する';

  @override
  String get digitalPersonas => '歴史的本質を持つデジタルペルソナ';

  @override
  String get theMindBehindTwins => 'あなたのツインの背後にある心';

  @override
  String get poweredByAdvancedLanguageModels => '高度な言語モデルによって駆動';

  @override
  String get howItWorks => '仕組み';

  @override
  String get twinsPoweredByAI => 'あなたのデジタルツインは、自然に思考し、推論し、対話することを可能にする洗練されたAI言語モデルによって駆動されています。モデルがより高度であるほど、あなたの対話はより本格的で知識豊富になります。';

  @override
  String get basicLLM => '基本LLM';

  @override
  String get advancedLLM => '高度なLLM';

  @override
  String get localProcessing => 'ローカル処理';

  @override
  String get cloudBased => 'クラウドベース';

  @override
  String get goodForPrivacy => 'プライバシーに良い';

  @override
  String get stateOfTheArt => '最先端';

  @override
  String get limitedKnowledge => '限定的な知識';

  @override
  String get vastKnowledge => '豊富な知識';

  @override
  String get basicConversations => '基本的な会話';

  @override
  String get nuancedInteractions => 'ニュアンスのある対話';

  @override
  String get questionsAboutAfterlife => 'Afterlifeについての質問？';

  @override
  String get chatWithDeveloperTwin => '開発者ツインとチャット';

  @override
  String get welcomeToAfterlife => 'Afterlifeへようこそ';

  @override
  String get chooseLanguage => '開始するための言語を選択してください';

  @override
  String get continueButton => '続行';

  @override
  String get diversePerspectives => '多様な視点';

  @override
  String get fromPoliticsToArt => '政治から芸術まで、歴史が生き生きと蘇る';

  @override
  String get engageWithDiverseFigures => '私たちの世界を形作った政治、科学、芸術などの多様な人物と対話してください。';

  @override
  String get rememberSimulations => 'これらは利用可能なデータに基づくシミュレーションであることを覚えておいてください - 回答は歴史的正確性への最善の努力を表しています。';

  @override
  String get createYourOwnTwins => '下部ナビゲーションの作成ボタンを使用して、あなた自身のデジタルツインを作成してください。';

  @override
  String get exampleInteraction => '例の相互作用';

  @override
  String get whenDiscussingRelativityWithEinstein => 'アインシュタインと相対性理論について話し合う時：';

  @override
  String get withAdvancedLLMExample => '"時空の曲率が重力レンズにどのように影響するか、そしてなぜこれが一般相対性理論の実験的検証にとって重要だったかを説明させてください..."';

  @override
  String get withBasicLLMExample => '"まあ、E=mc²は相対性理論にとって重要ですが、より深い意味や数学的枠組みは説明できません..."';

  @override
  String get withAdvancedLLMLabel => '高度なLLMと:';

  @override
  String get withBasicLLMLabel => '基本LLMと:';

  @override
  String get deepKnowledge => '深い専門知識';

  // Mask page strings
  @override
  String get digitalPersonasWithHistoricalEssence => '歴史的本質を持つデジタルペルソナ';

  @override
  String get einsteinWithMaskAndLLMArmor => 'マスクとLLMアーマーを身に着けたアインシュタイン';

  @override
  String get masksAreAIPersonas => 'マスクは、歴史的データ、個人的な記録、詳細なキャラクター仕様から作成されたAIペルソナです。';

  @override
  String get eachMaskTriesToEmbody => '各マスクは、その歴史上の人物の本物のキャラクター、個性、知識を体現しようとします。';

  @override
  String get theseDigitalTwinsAllow => 'これらのデジタルツインは、時代と現実を超えた視点と交流することを可能にします。';
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
  String get interviewInitialMessage => 'こんにちは！あなたの詳細なキャラクターカードを作成する準備ができています。次のいずれかを選択できます：\n\n1. あなたの性格と経験に関する私の質問に答える\n2. あなたの情報を含むファイル（PDF、TXT、DOC、またはメール）をアップロードする\n\nどちらがお好みですか？';
} 