import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Guess Party'**
  String get appName;

  /// No description provided for @bootstrapErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Guess Party could not start'**
  String get bootstrapErrorTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get howToPlay;

  /// No description provided for @gameRules.
  ///
  /// In en, this message translates to:
  /// **'Game Rules'**
  String get gameRules;

  /// No description provided for @learnHowToPlay.
  ///
  /// In en, this message translates to:
  /// **'Learn how to play Guess Party'**
  String get learnHowToPlay;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @systemDefaultLanguage.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefaultLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @demo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demo;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove this account and its data'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your account and associated game data. This action cannot be undone.'**
  String get deleteAccountMessage;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Account deletion failed'**
  String get deleteAccountFailed;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @managedByGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'Managed by Google Play'**
  String get managedByGooglePlay;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @viewPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'View our privacy policy'**
  String get viewPrivacyPolicy;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @updateAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of Guess Party is available. Would you like to update now?'**
  String get updateAvailableMessage;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotIt;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @game.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get game;

  /// No description provided for @sharedDeviceGame.
  ///
  /// In en, this message translates to:
  /// **'Shared-Device Game'**
  String get sharedDeviceGame;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparing;

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Room'**
  String get createRoom;

  /// No description provided for @joinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join Room'**
  String get joinRoom;

  /// No description provided for @userNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get userNotAuthenticated;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @hostClosedRoom.
  ///
  /// In en, this message translates to:
  /// **'Host has closed the room. Returning to home.'**
  String get hostClosedRoom;

  /// No description provided for @roomCode.
  ///
  /// In en, this message translates to:
  /// **'Room Code'**
  String get roomCode;

  /// No description provided for @copyRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Copy room code'**
  String get copyRoomCode;

  /// No description provided for @shareRoom.
  ///
  /// In en, this message translates to:
  /// **'Share Room'**
  String get shareRoom;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get players;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// No description provided for @startGameHint.
  ///
  /// In en, this message translates to:
  /// **'Start the game when enough players are connected'**
  String get startGameHint;

  /// No description provided for @onlineMode.
  ///
  /// In en, this message translates to:
  /// **'Online Mode'**
  String get onlineMode;

  /// No description provided for @sharedDeviceMode.
  ///
  /// In en, this message translates to:
  /// **'Shared Device'**
  String get sharedDeviceMode;

  /// No description provided for @sharedDeviceRequiresInternet.
  ///
  /// In en, this message translates to:
  /// **'Uses one shared device and requires internet access and an active session.'**
  String get sharedDeviceRequiresInternet;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose Category'**
  String get chooseCategory;

  /// No description provided for @maxPlayers.
  ///
  /// In en, this message translates to:
  /// **'Maximum Players'**
  String get maxPlayers;

  /// No description provided for @rounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get rounds;

  /// No description provided for @roundDuration.
  ///
  /// In en, this message translates to:
  /// **'Round Duration'**
  String get roundDuration;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'{count} seconds'**
  String seconds(int count);

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your verified email address. If an account exists, we will send recovery instructions.'**
  String get resetPasswordPrompt;

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendLink;

  /// No description provided for @chooseNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get chooseNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @returnToLogin.
  ///
  /// In en, this message translates to:
  /// **'Return to login'**
  String get returnToLogin;

  /// No description provided for @secureYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get secureYourAccount;

  /// No description provided for @sendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Send verification email'**
  String get sendVerificationEmail;

  /// No description provided for @completeVerifiedUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Complete verified upgrade'**
  String get completeVerifiedUpgrade;

  /// No description provided for @mutePlayer.
  ///
  /// In en, this message translates to:
  /// **'Mute this player'**
  String get mutePlayer;

  /// No description provided for @reportMessage.
  ///
  /// In en, this message translates to:
  /// **'Report message'**
  String get reportMessage;

  /// No description provided for @reportReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for report'**
  String get reportReason;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get chatMessageHint;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @loadOlderMessages.
  ///
  /// In en, this message translates to:
  /// **'Load older messages'**
  String get loadOlderMessages;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @roundNumber.
  ///
  /// In en, this message translates to:
  /// **'Round {current} of {total}'**
  String roundNumber(int current, int total);

  /// No description provided for @hintsPhase.
  ///
  /// In en, this message translates to:
  /// **'Hints'**
  String get hintsPhase;

  /// No description provided for @votingPhase.
  ///
  /// In en, this message translates to:
  /// **'Voting'**
  String get votingPhase;

  /// No description provided for @resultsPhase.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsPhase;

  /// No description provided for @submitHint.
  ///
  /// In en, this message translates to:
  /// **'Submit Hint'**
  String get submitHint;

  /// No description provided for @hintInput.
  ///
  /// In en, this message translates to:
  /// **'Enter a helpful hint'**
  String get hintInput;

  /// No description provided for @voteForPlayer.
  ///
  /// In en, this message translates to:
  /// **'Vote for {name}'**
  String voteForPlayer(String name);

  /// No description provided for @confirmVote.
  ///
  /// In en, this message translates to:
  /// **'Confirm Vote'**
  String get confirmVote;

  /// No description provided for @skipHints.
  ///
  /// In en, this message translates to:
  /// **'Skip hints?'**
  String get skipHints;

  /// No description provided for @skipVoting.
  ///
  /// In en, this message translates to:
  /// **'Skip voting?'**
  String get skipVoting;

  /// No description provided for @skipToVoting.
  ///
  /// In en, this message translates to:
  /// **'Skip to Voting'**
  String get skipToVoting;

  /// No description provided for @skipToResults.
  ///
  /// In en, this message translates to:
  /// **'Skip to Results'**
  String get skipToResults;

  /// No description provided for @skipPhaseConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to skip to {phase}?'**
  String skipPhaseConfirmation(String phase);

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds remaining'**
  String timeRemaining(int seconds);

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondsShort;

  /// No description provided for @timeRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get timeRemainingLabel;

  /// No description provided for @secondsLabel.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get secondsLabel;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @backOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get backOnline;

  /// No description provided for @connectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost. Trying to reconnect.'**
  String get connectionLost;

  /// No description provided for @passDevice.
  ///
  /// In en, this message translates to:
  /// **'Pass the device'**
  String get passDevice;

  /// No description provided for @readyToReveal.
  ///
  /// In en, this message translates to:
  /// **'Ready to reveal'**
  String get readyToReveal;

  /// No description provided for @hideRole.
  ///
  /// In en, this message translates to:
  /// **'Hide role'**
  String get hideRole;

  /// No description provided for @revealRole.
  ///
  /// In en, this message translates to:
  /// **'Reveal role'**
  String get revealRole;

  /// No description provided for @secretRoleHidden.
  ///
  /// In en, this message translates to:
  /// **'Secret role hidden'**
  String get secretRoleHidden;

  /// No description provided for @innocent.
  ///
  /// In en, this message translates to:
  /// **'Innocent'**
  String get innocent;

  /// No description provided for @imposter.
  ///
  /// In en, this message translates to:
  /// **'Imposter'**
  String get imposter;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @currentScores.
  ///
  /// In en, this message translates to:
  /// **'Current Scores'**
  String get currentScores;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// No description provided for @scorePoints.
  ///
  /// In en, this message translates to:
  /// **'{score} points'**
  String scorePoints(int score);

  /// No description provided for @connectedPlayersRequired.
  ///
  /// In en, this message translates to:
  /// **'Not enough connected players. Minimum {count} required to skip or advance.'**
  String connectedPlayersRequired(int count);

  /// No description provided for @couldNotStartSafely.
  ///
  /// In en, this message translates to:
  /// **'Could not start safely. Please try again.'**
  String get couldNotStartSafely;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get routeNotFound;

  /// No description provided for @routeLabel.
  ///
  /// In en, this message translates to:
  /// **'Route: {route}'**
  String routeLabel(String route);

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get checkingForUpdates;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment.'**
  String get pleaseWait;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to Date!'**
  String get upToDate;

  /// No description provided for @latestVersionMessage.
  ///
  /// In en, this message translates to:
  /// **'You are running the latest version of Guess Party ({version}).'**
  String latestVersionMessage(String version);

  /// No description provided for @playStoreUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'A newer version of Guess Party is available on the Play Store.'**
  String get playStoreUpdateMessage;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Update Check Failed'**
  String get updateCheckFailed;

  /// No description provided for @updateCheckFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not check for updates right now. Please try again later.'**
  String get updateCheckFailedMessage;

  /// No description provided for @chooseMode.
  ///
  /// In en, this message translates to:
  /// **'Choose a Mode'**
  String get chooseMode;

  /// No description provided for @chooseModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Online uses one device per player. Shared-Device Mode is pass-and-play on one device and still requires internet access and a signed-in session.'**
  String get chooseModeDescription;

  /// No description provided for @createOrJoinRoom.
  ///
  /// In en, this message translates to:
  /// **'Create or Join Room'**
  String get createOrJoinRoom;

  /// No description provided for @createOrJoinRoomDescription.
  ///
  /// In en, this message translates to:
  /// **'Start a new game or join an existing Online room with friends.'**
  String get createOrJoinRoomDescription;

  /// No description provided for @getYourRole.
  ///
  /// In en, this message translates to:
  /// **'Get Your Role'**
  String get getYourRole;

  /// No description provided for @getYourRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'You will be assigned as either an Innocent player or the Imposter. In Shared-Device Mode, pass the device privately for each reveal.'**
  String get getYourRoleDescription;

  /// No description provided for @hintsAndVoting.
  ///
  /// In en, this message translates to:
  /// **'Hints & Voting'**
  String get hintsAndVoting;

  /// No description provided for @hintsAndVotingDescription.
  ///
  /// In en, this message translates to:
  /// **'Give hints, then vote for who you think is the Imposter.'**
  String get hintsAndVotingDescription;

  /// No description provided for @resultsAndScoring.
  ///
  /// In en, this message translates to:
  /// **'Results & Scoring'**
  String get resultsAndScoring;

  /// No description provided for @resultsAndScoringDescription.
  ///
  /// In en, this message translates to:
  /// **'If the Imposter is caught, voters get 10 points. If the Imposter escapes, the Imposter gets 20 points.'**
  String get resultsAndScoringDescription;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @secureGuestAccount.
  ///
  /// In en, this message translates to:
  /// **'Secure this guest account'**
  String get secureGuestAccount;

  /// No description provided for @linkRecoveryEmail.
  ///
  /// In en, this message translates to:
  /// **'Link a real recovery email'**
  String get linkRecoveryEmail;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @legacyAccount.
  ///
  /// In en, this message translates to:
  /// **'Legacy Account'**
  String get legacyAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @legacyAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'Use this only for an existing username account. After signing in, link a real email from Home.'**
  String get legacyAccountHelp;

  /// No description provided for @legacyUsername.
  ///
  /// In en, this message translates to:
  /// **'Legacy username'**
  String get legacyUsername;

  /// No description provided for @legacyLogin.
  ///
  /// In en, this message translates to:
  /// **'Legacy login'**
  String get legacyLogin;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccount;

  /// No description provided for @createVerifiedAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a verified-email account'**
  String get createVerifiedAccount;

  /// No description provided for @backToEmailLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to email login'**
  String get backToEmailLogin;

  /// No description provided for @useLegacyAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a legacy username account'**
  String get useLegacyAccount;

  /// No description provided for @sessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Please sign in again.'**
  String get sessionEnded;

  /// No description provided for @findTheImposter.
  ///
  /// In en, this message translates to:
  /// **'Find the Imposter'**
  String get findTheImposter;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {username}!'**
  String welcomeUser(String username);

  /// No description provided for @readyToFindImposter.
  ///
  /// In en, this message translates to:
  /// **'Ready to find the Imposter?'**
  String get readyToFindImposter;

  /// No description provided for @startPlaying.
  ///
  /// In en, this message translates to:
  /// **'Start Playing'**
  String get startPlaying;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterUsername;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password for your verified account.'**
  String get enterNewPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @recoveryLinkExpired.
  ///
  /// In en, this message translates to:
  /// **'This password recovery link is no longer valid.'**
  String get recoveryLinkExpired;

  /// No description provided for @accountAlreadySecured.
  ///
  /// In en, this message translates to:
  /// **'This account already uses a real email.'**
  String get accountAlreadySecured;

  /// No description provided for @accountUpgradeExplanation.
  ///
  /// In en, this message translates to:
  /// **'Link a real email to preserve this account and its user ID. Accounts are never merged automatically.'**
  String get accountUpgradeExplanation;

  /// No description provided for @realEmail.
  ///
  /// In en, this message translates to:
  /// **'Real email'**
  String get realEmail;

  /// No description provided for @verificationEmailSentHelp.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox and open the verification link. Return here afterward to set a password if needed.'**
  String get verificationEmailSentHelp;

  /// No description provided for @accountPassword.
  ///
  /// In en, this message translates to:
  /// **'Account password'**
  String get accountPassword;

  /// No description provided for @gameMode.
  ///
  /// In en, this message translates to:
  /// **'Game Mode'**
  String get gameMode;

  /// No description provided for @onlineModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Each player joins from their own device'**
  String get onlineModeDescription;

  /// No description provided for @sharedDeviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Pass & play on one connected device'**
  String get sharedDeviceDescription;

  /// No description provided for @sharedDeviceSetupNotice.
  ///
  /// In en, this message translates to:
  /// **'Shared-Device Mode requires an internet connection and an active signed-in session. Players still pass this device between turns.'**
  String get sharedDeviceSetupNotice;

  /// No description provided for @createNewRoom.
  ///
  /// In en, this message translates to:
  /// **'Create New Room'**
  String get createNewRoom;

  /// No description provided for @createRoomDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a category and rounds to start the game'**
  String get createRoomDescription;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get noInternet;

  /// No description provided for @categoriesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories. Please try again.'**
  String get categoriesLoadFailed;

  /// No description provided for @enterRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Room Code'**
  String get enterRoomCode;

  /// No description provided for @roomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Room not found'**
  String get roomNotFound;

  /// No description provided for @roomNotFoundHelp.
  ///
  /// In en, this message translates to:
  /// **'Room not found. Check the code and try again.'**
  String get roomNotFoundHelp;

  /// No description provided for @waitingRoom.
  ///
  /// In en, this message translates to:
  /// **'Waiting Room'**
  String get waitingRoom;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @shareRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Share Room Code'**
  String get shareRoomCode;

  /// No description provided for @shareRoomMessage.
  ///
  /// In en, this message translates to:
  /// **'Join my Guess Party room!\n\nRoom Code: {code}\n\nEnter this code in the app to join the game!'**
  String shareRoomMessage(String code);

  /// No description provided for @playersNeededToStart.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Need 1 more player to start} other{Need {count} more players to start}}'**
  String playersNeededToStart(int count);

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @numberOfRounds.
  ///
  /// In en, this message translates to:
  /// **'Number of Rounds'**
  String get numberOfRounds;

  /// No description provided for @roundCount.
  ///
  /// In en, this message translates to:
  /// **'{count} rounds'**
  String roundCount(int count);

  /// No description provided for @playerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String playerCount(int count);

  /// No description provided for @minuteCount.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minuteCount(int count);

  /// No description provided for @enterRoomCodeValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a room code'**
  String get enterRoomCodeValidation;

  /// No description provided for @roomCodeLengthValidation.
  ///
  /// In en, this message translates to:
  /// **'Room code must be 6 digits'**
  String get roomCodeLengthValidation;

  /// No description provided for @enterPlayerNames.
  ///
  /// In en, this message translates to:
  /// **'Enter Player Names'**
  String get enterPlayerNames;

  /// No description provided for @enterPlayerNamesHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter names for players who will play on this device'**
  String get enterPlayerNamesHelp;

  /// No description provided for @playerNumber.
  ///
  /// In en, this message translates to:
  /// **'Player {number}'**
  String playerNumber(int number);

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name...'**
  String get enterName;

  /// No description provided for @minimumPlayersHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 2 players are required to start the game'**
  String get minimumPlayersHelp;

  /// No description provided for @categoryPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get categoryPlaces;

  /// No description provided for @categoryAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get categoryAnimals;

  /// No description provided for @categoryFootballPlayers.
  ///
  /// In en, this message translates to:
  /// **'Football Players'**
  String get categoryFootballPlayers;

  /// No description provided for @categoryIslamicFigures.
  ///
  /// In en, this message translates to:
  /// **'Islamic Figures'**
  String get categoryIslamicFigures;

  /// No description provided for @categoryDailyProducts.
  ///
  /// In en, this message translates to:
  /// **'Daily Products'**
  String get categoryDailyProducts;

  /// No description provided for @categoryFoods.
  ///
  /// In en, this message translates to:
  /// **'Foods'**
  String get categoryFoods;

  /// No description provided for @leaveGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Game?'**
  String get leaveGameTitle;

  /// No description provided for @leaveGameMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave? This will affect the current game.'**
  String get leaveGameMessage;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @syncingPlayer.
  ///
  /// In en, this message translates to:
  /// **'Syncing your player. Try again.'**
  String get syncingPlayer;

  /// No description provided for @backOnlineSynced.
  ///
  /// In en, this message translates to:
  /// **'Back online. Game synced.'**
  String get backOnlineSynced;

  /// No description provided for @loadingGame.
  ///
  /// In en, this message translates to:
  /// **'Loading game...'**
  String get loadingGame;

  /// No description provided for @waitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players...'**
  String get waitingForPlayers;

  /// No description provided for @syncingRole.
  ///
  /// In en, this message translates to:
  /// **'Syncing your role...'**
  String get syncingRole;

  /// No description provided for @skipHintsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to skip to voting?'**
  String get skipHintsConfirmation;

  /// No description provided for @skipVotingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to skip to results?'**
  String get skipVotingConfirmation;

  /// No description provided for @sharedGameScreen.
  ///
  /// In en, this message translates to:
  /// **'Shared game screen'**
  String get sharedGameScreen;

  /// No description provided for @sharedGameScreenHelp.
  ///
  /// In en, this message translates to:
  /// **'Continue the round on the shared device.'**
  String get sharedGameScreenHelp;

  /// No description provided for @character.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get character;

  /// No description provided for @privateRoundLoading.
  ///
  /// In en, this message translates to:
  /// **'Your private round information is still loading.'**
  String get privateRoundLoading;

  /// No description provided for @rolesArePrivate.
  ///
  /// In en, this message translates to:
  /// **'Roles are private'**
  String get rolesArePrivate;

  /// No description provided for @useRevealMemory.
  ///
  /// In en, this message translates to:
  /// **'Use what you saw during the pass-device reveal.'**
  String get useRevealMemory;

  /// No description provided for @youAreImposter.
  ///
  /// In en, this message translates to:
  /// **'You are the Imposter'**
  String get youAreImposter;

  /// No description provided for @imposterHelp.
  ///
  /// In en, this message translates to:
  /// **'You do not know the character. Read the chat, blend in, and infer the answer.'**
  String get imposterHelp;

  /// No description provided for @stayConvincing.
  ///
  /// In en, this message translates to:
  /// **'Stay convincing'**
  String get stayConvincing;

  /// No description provided for @roundTitle.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String roundTitle(int number);

  /// No description provided for @ofTotalRounds.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String ofTotalRounds(int total);

  /// No description provided for @viewFinalLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'View Final Leaderboard'**
  String get viewFinalLeaderboard;

  /// No description provided for @waitingForHostLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host to show the leaderboard...'**
  String get waitingForHostLeaderboard;

  /// No description provided for @startNextRound.
  ///
  /// In en, this message translates to:
  /// **'Start Next Round'**
  String get startNextRound;

  /// No description provided for @waitingForHostNextRound.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host to start the next round...'**
  String get waitingForHostNextRound;

  /// No description provided for @finalLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Final Leaderboard'**
  String get finalLeaderboard;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @exitRoleReveal.
  ///
  /// In en, this message translates to:
  /// **'Exit Role Reveal?'**
  String get exitRoleReveal;

  /// No description provided for @exitRoleRevealMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit? The game will be cancelled.'**
  String get exitRoleRevealMessage;

  /// No description provided for @loadingSharedSession.
  ///
  /// In en, this message translates to:
  /// **'Loading shared-device session...'**
  String get loadingSharedSession;

  /// No description provided for @playerProgress.
  ///
  /// In en, this message translates to:
  /// **'Player {current} of {total}'**
  String playerProgress(int current, int total);

  /// No description provided for @passPhoneTo.
  ///
  /// In en, this message translates to:
  /// **'Pass the phone to'**
  String get passPhoneTo;

  /// No description provided for @protectRole.
  ///
  /// In en, this message translates to:
  /// **'Make sure others cannot see!'**
  String get protectRole;

  /// No description provided for @youAreThe.
  ///
  /// In en, this message translates to:
  /// **'You are the'**
  String get youAreThe;

  /// No description provided for @imposterUpper.
  ///
  /// In en, this message translates to:
  /// **'IMPOSTER!'**
  String get imposterUpper;

  /// No description provided for @innocentUpper.
  ///
  /// In en, this message translates to:
  /// **'INNOCENT!'**
  String get innocentUpper;

  /// No description provided for @blendIn.
  ///
  /// In en, this message translates to:
  /// **'Blend in! Do not get caught!'**
  String get blendIn;

  /// No description provided for @nextPlayer.
  ///
  /// In en, this message translates to:
  /// **'Next Player'**
  String get nextPlayer;

  /// No description provided for @startGameExclamation.
  ///
  /// In en, this message translates to:
  /// **'Start Game!'**
  String get startGameExclamation;

  /// No description provided for @revealMyRole.
  ///
  /// In en, this message translates to:
  /// **'Reveal My Role'**
  String get revealMyRole;

  /// No description provided for @revealRoleAction.
  ///
  /// In en, this message translates to:
  /// **'Reveal Role'**
  String get revealRoleAction;

  /// No description provided for @passDeviceTo.
  ///
  /// In en, this message translates to:
  /// **'Pass device to'**
  String get passDeviceTo;

  /// No description provided for @tapToSeeRole.
  ///
  /// In en, this message translates to:
  /// **'Tap to see your role'**
  String get tapToSeeRole;

  /// No description provided for @doNotLetOthersSee.
  ///
  /// In en, this message translates to:
  /// **'Do not let others see!'**
  String get doNotLetOthersSee;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @imposterRevealHelp.
  ///
  /// In en, this message translates to:
  /// **'Pretend to know the character and blend in with the others!'**
  String get imposterRevealHelp;

  /// No description provided for @innocentRevealHelp.
  ///
  /// In en, this message translates to:
  /// **'Give hints about your character without revealing too much!'**
  String get innocentRevealHelp;

  /// No description provided for @unableToLoadPlayerInfo.
  ///
  /// In en, this message translates to:
  /// **'Unable to load player information'**
  String get unableToLoadPlayerInfo;

  /// No description provided for @discussHints.
  ///
  /// In en, this message translates to:
  /// **'Discuss and give hints verbally!'**
  String get discussHints;

  /// No description provided for @discussHintsHelp.
  ///
  /// In en, this message translates to:
  /// **'Talk about the character without revealing yourself. The timer will move to voting automatically.'**
  String get discussHintsHelp;

  /// No description provided for @onlineHintHelp.
  ///
  /// In en, this message translates to:
  /// **'Give a hint about the character without revealing yourself!'**
  String get onlineHintHelp;

  /// No description provided for @writeHint.
  ///
  /// In en, this message translates to:
  /// **'Write your hint here'**
  String get writeHint;

  /// No description provided for @sendHint.
  ///
  /// In en, this message translates to:
  /// **'Send Hint'**
  String get sendHint;

  /// No description provided for @hintExample.
  ///
  /// In en, this message translates to:
  /// **'Example: It is used in a kitchen'**
  String get hintExample;

  /// No description provided for @hintRequired.
  ///
  /// In en, this message translates to:
  /// **'Please write a hint first'**
  String get hintRequired;

  /// No description provided for @hintTooShort.
  ///
  /// In en, this message translates to:
  /// **'Hint must be at least 3 characters'**
  String get hintTooShort;

  /// No description provided for @hintTooLong.
  ///
  /// In en, this message translates to:
  /// **'Hint is too long (maximum 100 characters)'**
  String get hintTooLong;

  /// No description provided for @localVotingHelp.
  ///
  /// In en, this message translates to:
  /// **'Find the Imposter! Each player taps their own name, then picks who they suspect.'**
  String get localVotingHelp;

  /// No description provided for @onlineVotingHelp.
  ///
  /// In en, this message translates to:
  /// **'Vote for who you think is the Imposter!'**
  String get onlineVotingHelp;

  /// No description provided for @tapOwnNameToVote.
  ///
  /// In en, this message translates to:
  /// **'Tap your name to vote ↓'**
  String get tapOwnNameToVote;

  /// No description provided for @chooseSuspect.
  ///
  /// In en, this message translates to:
  /// **'Choose a suspect:'**
  String get chooseSuspect;

  /// No description provided for @whoDoYouSuspect.
  ///
  /// In en, this message translates to:
  /// **'{name}, who do you suspect?'**
  String whoDoYouSuspect(String name);

  /// No description provided for @tapPlayerToSuspect.
  ///
  /// In en, this message translates to:
  /// **'Tap the player you think is the Imposter'**
  String get tapPlayerToSuspect;

  /// No description provided for @cannotVoteForSelf.
  ///
  /// In en, this message translates to:
  /// **'Cannot vote for self'**
  String get cannotVoteForSelf;

  /// No description provided for @cannotVoteSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot vote for yourself'**
  String get cannotVoteSelf;

  /// No description provided for @changeVote.
  ///
  /// In en, this message translates to:
  /// **'Change Vote?'**
  String get changeVote;

  /// No description provided for @changeVoteTo.
  ///
  /// In en, this message translates to:
  /// **'Change your vote to {name}?'**
  String changeVoteTo(String name);

  /// No description provided for @showResultsNow.
  ///
  /// In en, this message translates to:
  /// **'Show Results Now →'**
  String get showResultsNow;

  /// No description provided for @finalizingResults.
  ///
  /// In en, this message translates to:
  /// **'Finalizing Results...'**
  String get finalizingResults;

  /// No description provided for @votesProgress.
  ///
  /// In en, this message translates to:
  /// **'Votes ({submitted}/{required})'**
  String votesProgress(int submitted, int required);

  /// No description provided for @hintsPhaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Hints Phase'**
  String get hintsPhaseTitle;

  /// No description provided for @votingPhaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Voting Phase'**
  String get votingPhaseTitle;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsTitle;

  /// No description provided for @reportReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened'**
  String get reportReasonHint;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// No description provided for @loadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingMessages;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get pageNotFound;

  /// No description provided for @gameDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Game data unavailable.'**
  String get gameDataUnavailable;

  /// No description provided for @enterUsernameShort.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get enterUsernameShort;

  /// No description provided for @yourUsername.
  ///
  /// In en, this message translates to:
  /// **'Your Username'**
  String get yourUsername;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get usernameRequired;

  /// No description provided for @usernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 2 characters'**
  String get usernameTooShort;

  /// No description provided for @noPlayersYet.
  ///
  /// In en, this message translates to:
  /// **'No players yet'**
  String get noPlayersYet;

  /// No description provided for @reconnectingToGame.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to game...'**
  String get reconnectingToGame;

  /// No description provided for @noHintsYet.
  ///
  /// In en, this message translates to:
  /// **'No hints yet...'**
  String get noHintsYet;

  /// No description provided for @hintsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Hints Submitted ({submitted}/{required})'**
  String hintsSubmitted(int submitted, int required);

  /// No description provided for @hiddenHint.
  ///
  /// In en, this message translates to:
  /// **'Hidden hint'**
  String get hiddenHint;

  /// No description provided for @voteSubmittedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Vote submitted! Waiting for results...'**
  String get voteSubmittedWaiting;

  /// No description provided for @syncingPlayerInfoHelp.
  ///
  /// In en, this message translates to:
  /// **'Syncing player info... Please wait.'**
  String get syncingPlayerInfoHelp;

  /// No description provided for @allVotesWaitingHost.
  ///
  /// In en, this message translates to:
  /// **'All votes in! Waiting for host...'**
  String get allVotesWaitingHost;

  /// No description provided for @voteForPlayerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap the player you think is the Imposter'**
  String get voteForPlayerPrompt;

  /// No description provided for @voteCountSingular.
  ///
  /// In en, this message translates to:
  /// **'1 vote'**
  String get voteCountSingular;

  /// No description provided for @voteCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} votes'**
  String voteCountPlural(int count);

  /// No description provided for @vote.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get vote;

  /// No description provided for @creatingRound.
  ///
  /// In en, this message translates to:
  /// **'Creating Round...'**
  String get creatingRound;

  /// No description provided for @imposterCaughtTitle.
  ///
  /// In en, this message translates to:
  /// **'Imposter Caught'**
  String get imposterCaughtTitle;

  /// No description provided for @imposterEscapedTitle.
  ///
  /// In en, this message translates to:
  /// **'Imposter Escaped'**
  String get imposterEscapedTitle;

  /// No description provided for @groupFoundHiddenPlayer.
  ///
  /// In en, this message translates to:
  /// **'The group found the hidden player.'**
  String get groupFoundHiddenPlayer;

  /// No description provided for @imposterAvoidedVote.
  ///
  /// In en, this message translates to:
  /// **'The imposter avoided the vote.'**
  String get imposterAvoidedVote;

  /// No description provided for @imposterWas.
  ///
  /// In en, this message translates to:
  /// **'The Imposter was:'**
  String get imposterWas;

  /// No description provided for @votingResults.
  ///
  /// In en, this message translates to:
  /// **'Voting Results'**
  String get votingResults;

  /// No description provided for @mostVoted.
  ///
  /// In en, this message translates to:
  /// **'Most voted: {name} ({count} votes)'**
  String mostVoted(String name, int count);
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
