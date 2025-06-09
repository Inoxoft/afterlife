import 'dart:math';
import 'app_localizations.dart';

class AppLocalizationsKo extends AppLocalizations {
  @override String get appTitle => 'Afterlife';
  @override String get explore => '탐색';
  @override String get yourTwins => '당신의 트윈';
  @override String get create => '생성';
  @override String get settings => '설정';
  @override String get exploreDigitalTwins => '디지털 트윈 탐색';
  @override String get yourDigitalTwins => '당신의 디지털 트윈';
  @override String get interactWithHistoricalFigures => '마스크를 통해 역사적 인물과 상호작용';
  @override String get noDigitalTwinsDetected => '디지털 트윈이 감지되지 않음';
  @override String get createNewTwinDescription => '새로운 디지털 트윈을 생성하여 보존된 의식과 상호작용을 시작하세요';
  @override String get createNewTwin => '새 트윈 생성';
  @override String get yourDigitalTwin => '당신의 디지털 트윈';
  @override String get darkMode => '다크 모드';
  @override String get darkModeDescription => '저조도 환경에서 시청 경험 향상 (곧 출시)';
  @override String get chatFontSize => '채팅 글꼴 크기';
  @override String get chatFontSizeDescription => '채팅 대화의 텍스트 크기 조정';
  @override String get enableAnimations => '애니메이션 활성화';
  @override String get enableAnimationsDescription => '인터페이스 애니메이션 및 시각 효과 전환';
  @override String get enableNotifications => '알림 활성화';
  @override String get enableNotificationsDescription => '디지털 트윈이 채팅을 원할 때 알림 받기';
  @override String get exportAllCharacters => '모든 캐릭터 내보내기';
  @override String get exportAllCharactersDescription => '디지털 트윈을 파일로 저장';
  @override String get clearAllData => '모든 데이터 삭제';
  @override String get clearAllDataDescription => '모든 캐릭터 삭제 및 앱 재설정 (주의: 실행 취소 불가)';
  @override String get appVersion => '앱 버전';
  @override String get privacyPolicy => '개인정보 보호정책';
  @override String get privacyPolicyDescription => '데이터 사용 및 보호 방법 읽기';
  @override String get customApiKey => '사용자 정의 OpenRouter API 키';
  @override String get customApiKeyDescription => '개인 API 키 설정 또는 업데이트';
  @override String get chatWithDeveloper => '개발자와 채팅';
  @override String get chatWithDeveloperDescription => '직접 지원을 받고 앱에 대한 피드백 공유';
  @override String get language => '언어';
  @override String get languageDescription => '앱과 AI 응답의 선호 언어 선택';
  @override String get appearance => '외관';
  @override String get notifications => '알림';
  @override String get dataManagement => '데이터 관리';
  @override String get about => '정보';
  @override String get apiConnectivity => 'API 및 연결';
  @override String get developerConnection => '개발자 연결';
  @override String get typeMessage => '메시지를 입력하세요...';
  @override String get send => '전송';
  @override String get clearChat => '채팅 지우기';
  @override String get clearChatConfirmation => '이 대화의 모든 메시지가 삭제됩니다. 이 작업은 실행 취소할 수 없습니다.';
  @override String get cancel => '취소';
  @override String get clear => '지우기';
  @override String get chatHistoryCleared => '채팅 기록이 지워졌습니다';
  @override String get welcomeInterview => "환영합니다! 당신의 디지털 트윈 제작을 도와드리겠습니다 — 당신의 성격, 기억, 가치관, 스타일의 깊고 생생한 초상화를 만들어보겠습니다.";
  @override String get fileUploadOption => "정보가 포함된 파일(PDF, TXT, DOC 또는 이메일) 업로드";
  @override String get questionAnswerOption => "성격과 경험에 대한 질문에 답하기";
  @override String get agree => '동의';
  @override String get errorConnecting => "죄송합니다. 현재 연결에 문제가 있습니다. 나중에 다시 시도해 주세요.";
  @override String get errorProcessingMessage => "죄송합니다. 현재 메시지를 처리할 수 없습니다. 나중에 다시 시도해 주세요.";
  @override String get noApiKey => '오류: AI 서비스에 연결할 수 없습니다. API 키 구성을 확인해 주세요.';
  @override String get checkApiKey => 'API 키 설정을 확인해 주세요.';
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
  @override String get accessingDataStorage => '데이터 저장소 접근 중';
  @override String get physicist => '물리학자';
  @override String get presidentActor => '대통령, 배우';
  @override String get computerScientist => '컴퓨터 과학자';
  @override String get actressModelSinger => '여배우, 모델, 가수';
  @override String get settingsDescription => 'Afterlife 경험을 맞춤 설정하세요';
  @override String get privacyPolicyNotAvailable => '이 버전에서는 개인정보 보호정책을 사용할 수 없습니다';
  @override String get apiKeyNote => '참고: 사용자 정의 키가 제공되지 않은 경우 .env 파일의 기본 API 키가 대체키로 사용됩니다.';
  @override String get clearAllDataConfirmation => '이렇게 하면 모든 캐릭터가 영구적으로 삭제되고 앱이 기본 상태로 재설정됩니다. 이 작업은 취소할 수 없습니다.';
  @override String get deleteEverything => '모두 삭제';
  @override String get dataCleared => '모든 데이터가 삭제되었습니다';
  @override String get errorClearingData => '채팅 기록 삭제 중 오류가 발생했습니다. 다시 시도해 주세요.';
  @override String get startChattingWith => '{name}와(과) 채팅 시작';
  @override String get sendMessageToBegin => '대화를 시작하려면 아래에 메시지를 보내세요';
  @override String get chat => '채팅';
  @override String get viewProfile => '프로필 보기';
  @override String get you => '당신';
  @override String get clearChatHistory => '채팅 기록 삭제';
  @override String get clearChatHistoryTitle => '채팅 기록 삭제';
  @override String get clearChatHistoryConfirm => '채팅 기록을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.';
  @override String get noBiographyAvailable => '사용 가능한 전기가 없습니다.';
  @override String get profileOf => '{name}의 프로필';
  @override String get name => '이름';
  @override String get years => '연도';
  @override String get profession => '직업';
  @override String get biography => '전기';
  @override String get aiModel => 'AI 모델';
  @override String get viewAllModels => '모든 모델 보기';
  @override String get featureAvailableSoon => '이 기능은 곧 사용할 수 있습니다';
  @override String get startConversation => '대화 시작';
  @override String get recommended => '추천';
  @override String get aiModelUpdatedFor => '{name}의 AI 모델이 업데이트되었습니다';
  @override String get selectAiModelFor => '{name}의 AI 모델 선택';
  @override String get chooseAiModelFor => '{name}을(를) 구동할 AI 모델을 선택하세요:';
  @override String get select => '선택';
  @override String systemPromptLanguageInstruction(String language) {
    return "\n\n중요: 사용자가 명시적으로 언어 변경을 요청하지 않는 한 항상 한국어($language)로 응답하십시오. 응답은 한국어로 자연스럽고 유창해야 합니다.";
  }

  // Onboarding strings
  @override
  String get backButton => '뒤로';

  @override
  String get nextButton => '다음';

  @override
  String get getStarted => '시작하기';

  @override
  String get understandMasks => '마스크 이해하기';

  @override
  String get digitalPersonas => '역사적 본질을 가진 디지털 페르소나';

  @override
  String get theMindBehindTwins => '당신의 트윈 뒤에 있는 마음';

  @override
  String get poweredByAdvancedLanguageModels => '고급 언어 모델로 구동';

  @override
  String get howItWorks => '작동 원리';

  @override
  String get twinsPoweredByAI => '당신의 디지털 트윈은 자연스럽게 생각하고, 추론하고, 상호 작용할 수 있게 해주는 정교한 AI 언어 모델로 구동됩니다. 모델이 더 고급일수록 상호 작용이 더 진정성 있고 지식이 풍부해집니다.';

  @override
  String get basicLLM => '기본 LLM';

  @override
  String get advancedLLM => '고급 LLM';

  @override
  String get localProcessing => '로컬 처리';

  @override
  String get cloudBased => '클라우드 기반';

  @override
  String get goodForPrivacy => '개인정보 보호에 좋음';

  @override
  String get stateOfTheArt => '최첨단';

  @override
  String get limitedKnowledge => '제한된 지식';

  @override
  String get vastKnowledge => '방대한 지식';

  @override
  String get basicConversations => '기본 대화';

  @override
  String get nuancedInteractions => '미묘한 상호 작용';

  @override
  String get questionsAboutAfterlife => 'Afterlife에 대한 질문?';

  @override
  String get chatWithDeveloperTwin => '개발자 트윈과 채팅';

  @override
  String get welcomeToAfterlife => 'Afterlife에 오신 것을 환영합니다';

  @override
  String get chooseLanguage => '시작할 언어를 선택하세요';

  @override
  String get continueButton => '계속';

  @override
  String get diversePerspectives => '다양한 관점';

  @override
  String get fromPoliticsToArt => '정치부터 예술까지, 역사가 생생하게 살아납니다';

  @override
  String get engageWithDiverseFigures => '우리 세상을 형성한 정치, 과학, 예술 등의 다양한 인물들과 교류하세요.';

  @override
  String get rememberSimulations => '이들은 사용 가능한 데이터를 기반으로 한 시뮬레이션임을 기억하세요 - 답변은 역사적 정확성을 위한 우리의 최선의 시도를 나타냅니다.';

  @override
  String get createYourOwnTwins => '하단 네비게이션의 생성 버튼을 사용하여 자신만의 디지털 트윈을 만드세요.';

  @override
  String get exampleInteraction => '상호작용 예시';

  @override
  String get whenDiscussingRelativityWithEinstein => '아인슈타인과 상대성 이론에 대해 논의할 때:';

  @override
  String get withAdvancedLLMExample => '"시공간 곡률이 중력 렌즈에 어떤 영향을 미치는지, 그리고 이것이 일반 상대성 이론의 실험적 검증에 왜 중요했는지 설명해 드리겠습니다..."';

  @override
  String get withBasicLLMExample => '"음, E=mc²는 상대성 이론에 중요하지만, 더 깊은 의미나 수학적 프레임워크는 설명할 수 없습니다..."';

  @override
  String get withAdvancedLLMLabel => '고급 LLM과 함께:';

  @override
  String get withBasicLLMLabel => '기본 LLM과 함께:';

  @override
  String get deepKnowledge => '깊은 전문 지식';

  // Mask page strings
  @override
  String get digitalPersonasWithHistoricalEssence => '역사적 본질을 가진 디지털 페르소나';

  @override
  String get einsteinWithMaskAndLLMArmor => '마스크와 LLM 갑옷을 입은 아인슈타인';

  @override
  String get masksAreAIPersonas => '마스크는 역사적 데이터, 개인 기록, 상세한 캐릭터 사양으로부터 생성된 AI 페르소나입니다.';

  @override
  String get eachMaskTriesToEmbody => '각 마스크는 해당 역사적 인물의 진정한 성격, 개성, 지식을 구현하려고 노력합니다.';

  @override
  String get theseDigitalTwinsAllow => '이러한 디지털 트윈은 시간과 현실을 넘나드는 관점과 상호작용할 수 있게 해줍니다.';
} 