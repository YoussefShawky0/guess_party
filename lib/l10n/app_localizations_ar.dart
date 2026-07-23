// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Guess Party';

  @override
  String get bootstrapErrorTitle => 'تعذر تشغيل Guess Party';

  @override
  String get settings => 'الإعدادات';

  @override
  String get howToPlay => 'طريقة اللعب';

  @override
  String get gameRules => 'قواعد اللعبة';

  @override
  String get learnHowToPlay => 'تعرّف على طريقة لعب جيس بارتي';

  @override
  String get appearance => 'المظهر';

  @override
  String get language => 'اللغة';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get systemDefaultLanguage => 'لغة النظام';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get theme => 'السمة';

  @override
  String get chooseTheme => 'اختر السمة';

  @override
  String get demo => 'تجريبي';

  @override
  String get dark => 'داكن';

  @override
  String get light => 'فاتح';

  @override
  String get systemDefault => 'إعداد النظام';

  @override
  String get about => 'حول التطبيق';

  @override
  String get account => 'الحساب';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountSubtitle => 'إزالة هذا الحساب وبياناته نهائيًا';

  @override
  String get deleteAccountTitle => 'حذف حسابك؟';

  @override
  String get deleteAccountMessage =>
      'سيؤدي ذلك إلى إزالة حسابك وبيانات اللعبة المرتبطة به نهائيًا. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get deleteAccountFailed => 'تعذر حذف الحساب';

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get developer => 'المطوّر';

  @override
  String get checkForUpdates => 'البحث عن تحديثات';

  @override
  String get managedByGooglePlay => 'تتم إدارته عبر Google Play';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get viewPrivacyPolicy => 'عرض سياسة الخصوصية';

  @override
  String get updateAvailable => 'يتوفر تحديث';

  @override
  String get updateAvailableMessage =>
      'يتوفر إصدار جديد من جيس بارتي. هل تريد تحديثه الآن؟';

  @override
  String get later => 'لاحقًا';

  @override
  String get update => 'تحديث';

  @override
  String get updateNow => 'حدّث الآن';

  @override
  String get ok => 'حسنًا';

  @override
  String get gotIt => 'فهمت';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get submit => 'إرسال';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get goBack => 'رجوع';

  @override
  String get goHome => 'الصفحة الرئيسية';

  @override
  String get leave => 'مغادرة';

  @override
  String get exit => 'خروج';

  @override
  String get skip => 'تخطي';

  @override
  String get game => 'اللعبة';

  @override
  String get sharedDeviceGame => 'لعبة الجهاز المشترك';

  @override
  String get preparing => 'جارٍ التحضير...';

  @override
  String get createRoom => 'إنشاء غرفة';

  @override
  String get joinRoom => 'الانضمام إلى غرفة';

  @override
  String get userNotAuthenticated => 'المستخدم غير مسجّل الدخول';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get hostClosedRoom =>
      'أغلق المضيف الغرفة. ستتم العودة إلى الصفحة الرئيسية.';

  @override
  String get roomCode => 'رمز الغرفة';

  @override
  String get copyRoomCode => 'نسخ رمز الغرفة';

  @override
  String get shareRoom => 'مشاركة الغرفة';

  @override
  String get players => 'اللاعبون';

  @override
  String get host => 'المضيف';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get startGame => 'بدء اللعبة';

  @override
  String get startGameHint => 'ابدأ اللعبة عند اتصال عدد كافٍ من اللاعبين';

  @override
  String get onlineMode => 'اللعب عبر الإنترنت';

  @override
  String get sharedDeviceMode => 'جهاز مشترك';

  @override
  String get sharedDeviceRequiresInternet =>
      'يستخدم جهازًا واحدًا مشتركًا ويتطلب اتصالًا بالإنترنت وجلسة نشطة.';

  @override
  String get chooseCategory => 'اختر الفئة';

  @override
  String get maxPlayers => 'الحد الأقصى للاعبين';

  @override
  String get customPlayerCount => 'عدد مخصص للاعبين';

  @override
  String get customPlayerCountHint => '4-10';

  @override
  String get playerCountRequired => 'أدخل عدد اللاعبين';

  @override
  String get playerCountWholeNumber => 'أدخل عددًا صحيحًا';

  @override
  String get playerCountRangeError => 'أدخل عددًا من 4 إلى 10';

  @override
  String get rounds => 'الجولات';

  @override
  String get roundDuration => 'مدة الجولة';

  @override
  String seconds(int count) {
    return '$count ثانية';
  }

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get continueAsGuest => 'المتابعة كضيف';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get displayName => 'الاسم الظاهر';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordPrompt =>
      'أدخل بريدك الإلكتروني الموثّق. إذا كان الحساب موجودًا فسنرسل تعليمات الاسترداد.';

  @override
  String get sendLink => 'إرسال الرابط';

  @override
  String get chooseNewPassword => 'اختر كلمة مرور جديدة';

  @override
  String get updatePassword => 'تحديث كلمة المرور';

  @override
  String get returnToLogin => 'العودة إلى تسجيل الدخول';

  @override
  String get secureYourAccount => 'تأمين حسابك';

  @override
  String get sendVerificationEmail => 'إرسال رسالة التحقق';

  @override
  String get completeVerifiedUpgrade => 'إكمال ترقية الحساب الموثّق';

  @override
  String get mutePlayer => 'كتم هذا اللاعب';

  @override
  String get reportMessage => 'الإبلاغ عن الرسالة';

  @override
  String get reportReason => 'سبب الإبلاغ';

  @override
  String get chat => 'الدردشة';

  @override
  String get chatMessageHint => 'اكتب رسالة';

  @override
  String get sendMessage => 'إرسال الرسالة';

  @override
  String get loadOlderMessages => 'تحميل رسائل أقدم';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String roundNumber(int current, int total) {
    return 'الجولة $current من $total';
  }

  @override
  String get hintsPhase => 'التلميحات';

  @override
  String get votingPhase => 'التصويت';

  @override
  String get resultsPhase => 'النتائج';

  @override
  String get submitHint => 'إرسال التلميح';

  @override
  String get hintInput => 'أدخل تلميحًا مفيدًا';

  @override
  String voteForPlayer(String name) {
    return 'التصويت للاعب $name';
  }

  @override
  String get confirmVote => 'تأكيد التصويت';

  @override
  String get skipHints => 'تخطي التلميحات؟';

  @override
  String get skipVoting => 'تخطي التصويت؟';

  @override
  String get skipToVoting => 'الانتقال إلى التصويت';

  @override
  String get skipToResults => 'الانتقال إلى النتائج';

  @override
  String skipPhaseConfirmation(String phase) {
    return 'هل تريد بالتأكيد التخطي إلى $phase؟';
  }

  @override
  String timeRemaining(int seconds) {
    return 'متبقٍ $seconds ثانية';
  }

  @override
  String get secondsShort => 'ث';

  @override
  String get timeRemainingLabel => 'الوقت المتبقي';

  @override
  String get secondsLabel => 'ثوانٍ';

  @override
  String get reconnecting => 'جارٍ إعادة الاتصال...';

  @override
  String get backOnline => 'تمت استعادة الاتصال';

  @override
  String get connectionLost => 'انقطع الاتصال. جارٍ محاولة الاتصال مجددًا.';

  @override
  String get passDevice => 'مرّر الجهاز';

  @override
  String get readyToReveal => 'جاهز للكشف';

  @override
  String get hideRole => 'إخفاء الدور';

  @override
  String get revealRole => 'كشف الدور';

  @override
  String get secretRoleHidden => 'الدور السري مخفي';

  @override
  String get innocent => 'بريء';

  @override
  String get imposter => 'المحتال';

  @override
  String get leaderboard => 'لوحة الصدارة';

  @override
  String get currentScores => 'النتائج الحالية';

  @override
  String get gameOver => 'انتهت اللعبة';

  @override
  String get playAgain => 'العب مجددًا';

  @override
  String get winner => 'الفائز';

  @override
  String scorePoints(int score) {
    return '$score نقطة';
  }

  @override
  String connectedPlayersRequired(int count) {
    return 'لا يوجد عدد كافٍ من اللاعبين المتصلين. يلزم $count على الأقل للتخطي أو التقدم.';
  }

  @override
  String get couldNotStartSafely => 'تعذر بدء اللعبة بأمان. حاول مرة أخرى.';

  @override
  String get routeNotFound => 'الصفحة غير موجودة';

  @override
  String routeLabel(String route) {
    return 'المسار: $route';
  }

  @override
  String get checkingForUpdates => 'جارٍ البحث عن تحديثات...';

  @override
  String get pleaseWait => 'يرجى الانتظار قليلًا.';

  @override
  String get upToDate => 'التطبيق محدّث';

  @override
  String latestVersionMessage(String version) {
    return 'أنت تستخدم أحدث إصدار من جيس بارتي ($version).';
  }

  @override
  String get playStoreUpdateMessage =>
      'يتوفر إصدار أحدث من جيس بارتي على متجر Google Play.';

  @override
  String get updateCheckFailed => 'تعذر البحث عن تحديث';

  @override
  String get updateCheckFailedMessage =>
      'تعذر البحث عن تحديثات الآن. حاول مرة أخرى لاحقًا.';

  @override
  String get chooseMode => 'اختر نمط اللعب';

  @override
  String get chooseModeDescription =>
      'يستخدم اللعب عبر الإنترنت جهازًا لكل لاعب. أما نمط الجهاز المشترك فيعتمد على تمرير جهاز واحد، ويتطلب اتصالًا بالإنترنت وجلسة مسجّلة.';

  @override
  String get createOrJoinRoom => 'أنشئ غرفة أو انضم إليها';

  @override
  String get createOrJoinRoomDescription =>
      'ابدأ لعبة جديدة أو انضم إلى غرفة عبر الإنترنت مع أصدقائك.';

  @override
  String get getYourRole => 'اعرف دورك';

  @override
  String get getYourRoleDescription =>
      'سيتم تعيينك كلاعب بريء أو محتال. في نمط الجهاز المشترك، مرّر الجهاز بشكل خاص لكشف دور كل لاعب.';

  @override
  String get hintsAndVoting => 'التلميحات والتصويت';

  @override
  String get hintsAndVotingDescription =>
      'قدّم تلميحات ثم صوّت لمن تعتقد أنه المحتال.';

  @override
  String get resultsAndScoring => 'النتائج والنقاط';

  @override
  String get resultsAndScoringDescription =>
      'إذا تم اكتشاف المحتال يحصل المصوّتون عليه على 10 نقاط. وإذا نجا يحصل المحتال على 20 نقطة.';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String errorWithMessage(String message) {
    return 'خطأ: $message';
  }

  @override
  String get secureGuestAccount => 'تأمين حساب الضيف';

  @override
  String get linkRecoveryEmail => 'ربط بريد استرداد حقيقي';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get legacyAccount => 'حساب قديم';

  @override
  String get welcomeBack => 'مرحبًا بعودتك';

  @override
  String get legacyAccountHelp =>
      'استخدم هذا الخيار فقط لحساب موجود يعتمد اسم المستخدم. بعد تسجيل الدخول، اربط بريدًا حقيقيًا من الصفحة الرئيسية.';

  @override
  String get legacyUsername => 'اسم المستخدم القديم';

  @override
  String get legacyLogin => 'دخول بالحساب القديم';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get createVerifiedAccount => 'إنشاء حساب ببريد إلكتروني موثّق';

  @override
  String get backToEmailLogin => 'العودة إلى الدخول بالبريد';

  @override
  String get useLegacyAccount => 'استخدام حساب قديم باسم المستخدم';

  @override
  String get sessionEnded => 'انتهت جلستك. سجّل الدخول مرة أخرى.';

  @override
  String get findTheImposter => 'اكتشف المحتال';

  @override
  String welcomeUser(String username) {
    return 'مرحبًا، $username!';
  }

  @override
  String get readyToFindImposter => 'هل أنت مستعد لاكتشاف المحتال؟';

  @override
  String get startPlaying => 'ابدأ اللعب';

  @override
  String get enterUsername => 'أدخل اسم المستخدم';

  @override
  String get enterNewPassword => 'أدخل كلمة مرور جديدة لحسابك الموثّق.';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get recoveryLinkExpired => 'رابط استرداد كلمة المرور لم يعد صالحًا.';

  @override
  String get accountAlreadySecured =>
      'هذا الحساب يستخدم بريدًا إلكترونيًا حقيقيًا بالفعل.';

  @override
  String get accountUpgradeExplanation =>
      'اربط بريدًا حقيقيًا للحفاظ على هذا الحساب ومعرّف المستخدم الخاص به. لا يتم دمج الحسابات تلقائيًا.';

  @override
  String get realEmail => 'البريد الإلكتروني الحقيقي';

  @override
  String get verificationEmailSentHelp =>
      'تحقق من بريدك وافتح رابط التحقق، ثم عد إلى هنا لتعيين كلمة مرور إذا لزم الأمر.';

  @override
  String get accountPassword => 'كلمة مرور الحساب';

  @override
  String get gameMode => 'نمط اللعب';

  @override
  String get onlineModeDescription => 'ينضم كل لاعب من جهازه';

  @override
  String get sharedDeviceDescription =>
      'مرّر جهازًا واحدًا متصلًا بين اللاعبين';

  @override
  String get sharedDeviceSetupNotice =>
      'يتطلب نمط الجهاز المشترك اتصالًا بالإنترنت وجلسة مسجّلة نشطة. يستمر اللاعبون في تمرير هذا الجهاز بين الأدوار.';

  @override
  String get createNewRoom => 'إنشاء غرفة جديدة';

  @override
  String get createRoomDescription => 'اختر الفئة وعدد الجولات لبدء اللعبة';

  @override
  String get noInternet =>
      'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مجددًا.';

  @override
  String get categoriesLoadFailed => 'تعذر تحميل الفئات. حاول مرة أخرى.';

  @override
  String get enterRoomCode => 'أدخل رمز الغرفة';

  @override
  String get roomNotFound => 'الغرفة غير موجودة';

  @override
  String get roomNotFoundHelp =>
      'الغرفة غير موجودة. تحقق من الرمز وحاول مرة أخرى.';

  @override
  String get waitingRoom => 'غرفة الانتظار';

  @override
  String get copyCode => 'نسخ الرمز';

  @override
  String get shareRoomCode => 'مشاركة رمز الغرفة';

  @override
  String shareRoomMessage(String code) {
    return 'انضم إلى غرفتي في جيس بارتي!\n\nرمز الغرفة: $code\n\nأدخل هذا الرمز في التطبيق للانضمام إلى اللعبة!';
  }

  @override
  String playersNeededToStart(int count) {
    return 'يلزم $count لاعب إضافي لبدء اللعبة';
  }

  @override
  String get selectCategory => 'اختر الفئة';

  @override
  String get numberOfRounds => 'عدد الجولات';

  @override
  String roundCount(int count) {
    return '$count جولات';
  }

  @override
  String playerCount(int count) {
    return '$count لاعبين';
  }

  @override
  String minuteCount(int count) {
    return '$count دقائق';
  }

  @override
  String get enterRoomCodeValidation => 'يرجى إدخال رمز الغرفة';

  @override
  String get roomCodeLengthValidation => 'يجب أن يتكون رمز الغرفة من 6 أرقام';

  @override
  String get enterPlayerNames => 'أدخل أسماء اللاعبين';

  @override
  String get enterPlayerNamesHelp =>
      'أدخل أسماء اللاعبين الذين سيلعبون على هذا الجهاز';

  @override
  String playerNumber(int number) {
    return 'اللاعب $number';
  }

  @override
  String get enterName => 'أدخل الاسم...';

  @override
  String get minimumPlayersHelp => 'يلزم لاعبان على الأقل لبدء اللعبة';

  @override
  String get categoryPlaces => 'أماكن';

  @override
  String get categoryAnimals => 'حيوانات';

  @override
  String get categoryFootballPlayers => 'لاعبو كرة القدم';

  @override
  String get categoryIslamicFigures => 'شخصيات إسلامية';

  @override
  String get categoryDailyProducts => 'منتجات يومية';

  @override
  String get categoryFoods => 'أطعمة';

  @override
  String get leaveGameTitle => 'مغادرة اللعبة؟';

  @override
  String get leaveGameMessage =>
      'هل تريد بالتأكيد المغادرة؟ سيؤثر ذلك في اللعبة الحالية.';

  @override
  String get stay => 'البقاء';

  @override
  String get syncingPlayer => 'جارٍ مزامنة اللاعب. حاول مرة أخرى.';

  @override
  String get backOnlineSynced => 'عاد الاتصال وتمت مزامنة اللعبة.';

  @override
  String get loadingGame => 'جارٍ تحميل اللعبة...';

  @override
  String get waitingForPlayers => 'في انتظار اللاعبين...';

  @override
  String get syncingRole => 'جارٍ مزامنة دورك...';

  @override
  String get skipHintsConfirmation => 'هل تريد بالتأكيد الانتقال إلى التصويت؟';

  @override
  String get skipVotingConfirmation => 'هل تريد بالتأكيد الانتقال إلى النتائج؟';

  @override
  String get sharedGameScreen => 'شاشة اللعبة المشتركة';

  @override
  String get sharedGameScreenHelp => 'تابع الجولة على الجهاز المشترك.';

  @override
  String get character => 'الشخصية';

  @override
  String get privateRoundLoading => 'لا تزال معلومات جولتك الخاصة قيد التحميل.';

  @override
  String get rolesArePrivate => 'الأدوار خاصة';

  @override
  String get useRevealMemory =>
      'اعتمد على ما رأيته أثناء كشف الدور عند تمرير الجهاز.';

  @override
  String get youAreImposter => 'أنت المحتال';

  @override
  String get imposterHelp =>
      'أنت لا تعرف الشخصية. اقرأ الدردشة واندمج مع الآخرين واستنتج الإجابة.';

  @override
  String get stayConvincing => 'حافظ على إقناعك';

  @override
  String roundTitle(int number) {
    return 'الجولة $number';
  }

  @override
  String ofTotalRounds(int total) {
    return 'من $total';
  }

  @override
  String get viewFinalLeaderboard => 'عرض لوحة المتصدرين النهائية';

  @override
  String get waitingForHostLeaderboard =>
      'في انتظار المضيف لعرض لوحة الصدارة...';

  @override
  String get startNextRound => 'ابدأ الجولة التالية';

  @override
  String get waitingForHostNextRound =>
      'في انتظار المضيف لبدء الجولة التالية...';

  @override
  String get finalLeaderboard => 'لوحة الصدارة النهائية';

  @override
  String get backToHome => 'العودة إلى الرئيسية';

  @override
  String get exitRoleReveal => 'الخروج من كشف الدور؟';

  @override
  String get exitRoleRevealMessage =>
      'هل تريد بالتأكيد الخروج؟ سيتم إلغاء اللعبة.';

  @override
  String get loadingSharedSession => 'جارٍ تحميل جلسة الجهاز المشترك...';

  @override
  String playerProgress(int current, int total) {
    return 'اللاعب $current من $total';
  }

  @override
  String get passPhoneTo => 'مرّر الهاتف إلى';

  @override
  String get protectRole => 'تأكد من ألا يرى الآخرون!';

  @override
  String get youAreThe => 'أنت';

  @override
  String get imposterUpper => 'المحتال!';

  @override
  String get innocentUpper => 'البريء!';

  @override
  String get blendIn => 'اندمج مع الآخرين! لا تدعهم يكتشفونك!';

  @override
  String get nextPlayer => 'اللاعب التالي';

  @override
  String get startGameExclamation => 'ابدأ اللعبة!';

  @override
  String get revealMyRole => 'اكشف دوري';

  @override
  String get revealRoleAction => 'كشف الدور';

  @override
  String get passDeviceTo => 'مرّر الجهاز إلى';

  @override
  String get tapToSeeRole => 'اضغط لرؤية دورك';

  @override
  String get doNotLetOthersSee => 'لا تدع الآخرين يرون!';

  @override
  String get continueAction => 'متابعة';

  @override
  String get imposterRevealHelp => 'تظاهر بأنك تعرف الشخصية واندمج مع الآخرين!';

  @override
  String get innocentRevealHelp => 'قدّم تلميحات عن شخصيتك دون كشف الكثير!';

  @override
  String get unableToLoadPlayerInfo => 'تعذر تحميل معلومات اللاعبين';

  @override
  String get discussHints => 'ناقشوا وقدّموا التلميحات شفهيًا!';

  @override
  String get discussHintsHelp =>
      'تحدثوا عن الشخصية دون كشف أنفسكم. سينتقل المؤقت إلى التصويت تلقائيًا.';

  @override
  String get onlineHintHelp => 'قدّم تلميحًا عن الشخصية دون كشف نفسك!';

  @override
  String get writeHint => 'اكتب تلميحك هنا';

  @override
  String get sendHint => 'إرسال التلميح';

  @override
  String get hintExample => 'مثال: يُستخدم في المطبخ';

  @override
  String get hintRequired => 'يرجى كتابة تلميح أولًا';

  @override
  String get hintTooShort => 'يجب ألا يقل التلميح عن 3 أحرف';

  @override
  String get hintTooLong => 'التلميح طويل جدًا (الحد الأقصى 100 حرف)';

  @override
  String get localVotingHelp =>
      'اكتشف المحتال! يضغط كل لاعب على اسمه ثم يختار من يشتبه به.';

  @override
  String get onlineVotingHelp => 'صوّت لمن تعتقد أنه المحتال!';

  @override
  String get tapOwnNameToVote => 'اضغط على اسمك للتصويت ↓';

  @override
  String get chooseSuspect => 'اختر المشتبه به:';

  @override
  String whoDoYouSuspect(String name) {
    return '$name، من تشتبه به؟';
  }

  @override
  String get tapPlayerToSuspect => 'اضغط على اللاعب الذي تظنه المحتال';

  @override
  String get cannotVoteForSelf => 'لا يمكنك التصويت لنفسك';

  @override
  String get cannotVoteSelf => 'لا يمكنك التصويت لنفسك';

  @override
  String get changeVote => 'تغيير التصويت؟';

  @override
  String changeVoteTo(String name) {
    return 'هل تريد تغيير تصويتك إلى $name؟';
  }

  @override
  String get showResultsNow => 'عرض النتائج الآن ←';

  @override
  String get finalizingResults => 'جارٍ إنهاء النتائج...';

  @override
  String votesProgress(int submitted, int required) {
    return 'الأصوات ($submitted/$required)';
  }

  @override
  String get hintsPhaseTitle => 'مرحلة التلميحات';

  @override
  String get votingPhaseTitle => 'مرحلة التصويت';

  @override
  String get resultsTitle => 'النتائج';

  @override
  String get reportReasonHint => 'أخبرنا بما حدث';

  @override
  String get noMessages => 'لا توجد رسائل بعد';

  @override
  String get loadingMessages => 'جارٍ التحميل...';

  @override
  String get typeMessage => 'اكتب رسالة...';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get gameDataUnavailable => 'بيانات اللعبة غير متاحة.';

  @override
  String get enterUsernameShort => 'أدخل اسم المستخدم';

  @override
  String get yourUsername => 'اسم المستخدم';

  @override
  String get usernameRequired => 'يرجى إدخال اسم المستخدم';

  @override
  String get usernameTooShort => 'يجب ألا يقل اسم المستخدم عن حرفين';

  @override
  String get noPlayersYet => 'لا يوجد لاعبون بعد';

  @override
  String get reconnectingToGame => 'جارٍ إعادة الاتصال باللعبة...';

  @override
  String get noHintsYet => 'لا توجد تلميحات بعد...';

  @override
  String hintsSubmitted(int submitted, int required) {
    return 'التلميحات المرسلة ($submitted/$required)';
  }

  @override
  String get hiddenHint => 'تلميح مخفي';

  @override
  String get voteSubmittedWaiting => 'تم إرسال التصويت! في انتظار النتائج...';

  @override
  String get syncingPlayerInfoHelp =>
      'جارٍ مزامنة معلومات اللاعب... يرجى الانتظار.';

  @override
  String get allVotesWaitingHost => 'اكتملت الأصوات! في انتظار المضيف...';

  @override
  String get voteForPlayerPrompt => 'اضغط على اللاعب الذي تظنه المحتال';

  @override
  String get voteCountSingular => 'صوت واحد';

  @override
  String voteCountPlural(int count) {
    return '$count أصوات';
  }

  @override
  String get vote => 'تصويت';

  @override
  String get creatingRound => 'جارٍ إنشاء الجولة...';

  @override
  String get imposterCaughtTitle => 'تم اكتشاف المحتال';

  @override
  String get imposterEscapedTitle => 'نجا المحتال';

  @override
  String get groupFoundHiddenPlayer => 'تمكن الفريق من اكتشاف اللاعب المختبئ.';

  @override
  String get imposterAvoidedVote => 'تمكن المحتال من تجنب التصويت.';

  @override
  String get imposterWas => 'المحتال هو:';

  @override
  String get votingResults => 'نتائج التصويت';

  @override
  String mostVoted(String name, int count) {
    return 'الأكثر تصويتًا: $name ($count صوتًا)';
  }
}
