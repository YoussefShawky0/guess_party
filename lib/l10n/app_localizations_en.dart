// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Guess Party';

  @override
  String get bootstrapErrorTitle => 'Guess Party could not start';

  @override
  String get settings => 'Settings';

  @override
  String get howToPlay => 'How to Play';

  @override
  String get gameRules => 'Game Rules';

  @override
  String get learnHowToPlay => 'Learn how to play Guess Party';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get systemDefaultLanguage => 'System Default';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get theme => 'Theme';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get demo => 'Demo';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get systemDefault => 'System Default';

  @override
  String get about => 'About';

  @override
  String get account => 'Account';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently remove this account and its data';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountMessage =>
      'This permanently removes your account and associated game data. This action cannot be undone.';

  @override
  String get deleteAccountFailed => 'Account deletion failed';

  @override
  String get appVersion => 'App Version';

  @override
  String get developer => 'Developer';

  @override
  String get checkForUpdates => 'Check for Updates';

  @override
  String get managedByGooglePlay => 'Managed by Google Play';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get viewPrivacyPolicy => 'View our privacy policy';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get updateAvailableMessage =>
      'A new version of Guess Party is available. Would you like to update now?';

  @override
  String get later => 'Later';

  @override
  String get update => 'Update';

  @override
  String get updateNow => 'Update Now';

  @override
  String get ok => 'OK';

  @override
  String get gotIt => 'Got it!';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get submit => 'Submit';

  @override
  String get retry => 'Retry';

  @override
  String get goBack => 'Go Back';

  @override
  String get goHome => 'Go Home';

  @override
  String get leave => 'Leave';

  @override
  String get exit => 'Exit';

  @override
  String get skip => 'Skip';

  @override
  String get game => 'Game';

  @override
  String get sharedDeviceGame => 'Shared-Device Game';

  @override
  String get preparing => 'Preparing...';

  @override
  String get createRoom => 'Create Room';

  @override
  String get joinRoom => 'Join Room';

  @override
  String get userNotAuthenticated => 'User not authenticated';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get hostClosedRoom => 'Host has closed the room. Returning to home.';

  @override
  String get roomCode => 'Room Code';

  @override
  String get copyRoomCode => 'Copy room code';

  @override
  String get shareRoom => 'Share Room';

  @override
  String get players => 'Players';

  @override
  String get host => 'Host';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get startGame => 'Start Game';

  @override
  String get startGameHint =>
      'Start the game when enough players are connected';

  @override
  String get onlineMode => 'Online Mode';

  @override
  String get sharedDeviceMode => 'Shared Device';

  @override
  String get sharedDeviceRequiresInternet =>
      'Uses one shared device and requires internet access and an active session.';

  @override
  String get chooseCategory => 'Choose Category';

  @override
  String get maxPlayers => 'Maximum Players';

  @override
  String get rounds => 'Rounds';

  @override
  String get roundDuration => 'Round Duration';

  @override
  String seconds(int count) {
    return '$count seconds';
  }

  @override
  String get login => 'Log In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get username => 'Username';

  @override
  String get displayName => 'Display name';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get resetPasswordPrompt =>
      'Enter your verified email address. If an account exists, we will send recovery instructions.';

  @override
  String get sendLink => 'Send link';

  @override
  String get chooseNewPassword => 'Choose a new password';

  @override
  String get updatePassword => 'Update password';

  @override
  String get returnToLogin => 'Return to login';

  @override
  String get secureYourAccount => 'Secure your account';

  @override
  String get sendVerificationEmail => 'Send verification email';

  @override
  String get completeVerifiedUpgrade => 'Complete verified upgrade';

  @override
  String get mutePlayer => 'Mute this player';

  @override
  String get reportMessage => 'Report message';

  @override
  String get reportReason => 'Reason for report';

  @override
  String get chat => 'Chat';

  @override
  String get chatMessageHint => 'Type a message';

  @override
  String get sendMessage => 'Send message';

  @override
  String get loadOlderMessages => 'Load older messages';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String roundNumber(int current, int total) {
    return 'Round $current of $total';
  }

  @override
  String get hintsPhase => 'Hints';

  @override
  String get votingPhase => 'Voting';

  @override
  String get resultsPhase => 'Results';

  @override
  String get submitHint => 'Submit Hint';

  @override
  String get hintInput => 'Enter a helpful hint';

  @override
  String voteForPlayer(String name) {
    return 'Vote for $name';
  }

  @override
  String get confirmVote => 'Confirm Vote';

  @override
  String get skipHints => 'Skip hints?';

  @override
  String get skipVoting => 'Skip voting?';

  @override
  String get skipToVoting => 'Skip to Voting';

  @override
  String get skipToResults => 'Skip to Results';

  @override
  String skipPhaseConfirmation(String phase) {
    return 'Are you sure you want to skip to $phase?';
  }

  @override
  String timeRemaining(int seconds) {
    return '$seconds seconds remaining';
  }

  @override
  String get secondsShort => 's';

  @override
  String get timeRemainingLabel => 'Time Remaining';

  @override
  String get secondsLabel => 'seconds';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get backOnline => 'Back online';

  @override
  String get connectionLost => 'Connection lost. Trying to reconnect.';

  @override
  String get passDevice => 'Pass the device';

  @override
  String get readyToReveal => 'Ready to reveal';

  @override
  String get hideRole => 'Hide role';

  @override
  String get revealRole => 'Reveal role';

  @override
  String get secretRoleHidden => 'Secret role hidden';

  @override
  String get innocent => 'Innocent';

  @override
  String get imposter => 'Imposter';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get currentScores => 'Current Scores';

  @override
  String get gameOver => 'Game Over';

  @override
  String get playAgain => 'Play Again';

  @override
  String get winner => 'Winner';

  @override
  String scorePoints(int score) {
    return '$score points';
  }

  @override
  String connectedPlayersRequired(int count) {
    return 'Not enough connected players. Minimum $count required to skip or advance.';
  }

  @override
  String get couldNotStartSafely => 'Could not start safely. Please try again.';

  @override
  String get routeNotFound => 'Page not found';

  @override
  String routeLabel(String route) {
    return 'Route: $route';
  }

  @override
  String get checkingForUpdates => 'Checking for updates...';

  @override
  String get pleaseWait => 'Please wait a moment.';

  @override
  String get upToDate => 'Up to Date!';

  @override
  String latestVersionMessage(String version) {
    return 'You are running the latest version of Guess Party ($version).';
  }

  @override
  String get playStoreUpdateMessage =>
      'A newer version of Guess Party is available on the Play Store.';

  @override
  String get updateCheckFailed => 'Update Check Failed';

  @override
  String get updateCheckFailedMessage =>
      'We could not check for updates right now. Please try again later.';

  @override
  String get chooseMode => 'Choose a Mode';

  @override
  String get chooseModeDescription =>
      'Online uses one device per player. Shared-Device Mode is pass-and-play on one device and still requires internet access and a signed-in session.';

  @override
  String get createOrJoinRoom => 'Create or Join Room';

  @override
  String get createOrJoinRoomDescription =>
      'Start a new game or join an existing Online room with friends.';

  @override
  String get getYourRole => 'Get Your Role';

  @override
  String get getYourRoleDescription =>
      'You will be assigned as either an Innocent player or the Imposter. In Shared-Device Mode, pass the device privately for each reveal.';

  @override
  String get hintsAndVoting => 'Hints & Voting';

  @override
  String get hintsAndVotingDescription =>
      'Give hints, then vote for who you think is the Imposter.';

  @override
  String get resultsAndScoring => 'Results & Scoring';

  @override
  String get resultsAndScoringDescription =>
      'If the Imposter is caught, voters get 10 points. If the Imposter escapes, the Imposter gets 20 points.';

  @override
  String get logout => 'Log out';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get secureGuestAccount => 'Secure this guest account';

  @override
  String get linkRecoveryEmail => 'Link a real recovery email';

  @override
  String get createAccount => 'Create Account';

  @override
  String get legacyAccount => 'Legacy Account';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get legacyAccountHelp =>
      'Use this only for an existing username account. After signing in, link a real email from Home.';

  @override
  String get legacyUsername => 'Legacy username';

  @override
  String get legacyLogin => 'Legacy login';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log in';

  @override
  String get createVerifiedAccount => 'Create a verified-email account';

  @override
  String get backToEmailLogin => 'Back to email login';

  @override
  String get useLegacyAccount => 'Use a legacy username account';

  @override
  String get sessionEnded => 'Your session ended. Please sign in again.';

  @override
  String get findTheImposter => 'Find the Imposter';

  @override
  String welcomeUser(String username) {
    return 'Welcome, $username!';
  }

  @override
  String get readyToFindImposter => 'Ready to find the Imposter?';

  @override
  String get startPlaying => 'Start Playing';

  @override
  String get enterUsername => 'Enter your username';

  @override
  String get enterNewPassword =>
      'Enter a new password for your verified account.';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get recoveryLinkExpired =>
      'This password recovery link is no longer valid.';

  @override
  String get accountAlreadySecured => 'This account already uses a real email.';

  @override
  String get accountUpgradeExplanation =>
      'Link a real email to preserve this account and its user ID. Accounts are never merged automatically.';

  @override
  String get realEmail => 'Real email';

  @override
  String get verificationEmailSentHelp =>
      'Check your inbox and open the verification link. Return here afterward to set a password if needed.';

  @override
  String get accountPassword => 'Account password';

  @override
  String get gameMode => 'Game Mode';

  @override
  String get onlineModeDescription => 'Each player joins from their own device';

  @override
  String get sharedDeviceDescription => 'Pass & play on one connected device';

  @override
  String get sharedDeviceSetupNotice =>
      'Shared-Device Mode requires an internet connection and an active signed-in session. Players still pass this device between turns.';

  @override
  String get createNewRoom => 'Create New Room';

  @override
  String get createRoomDescription =>
      'Choose a category and rounds to start the game';

  @override
  String get noInternet =>
      'No internet connection. Check your network and try again.';

  @override
  String get categoriesLoadFailed =>
      'Failed to load categories. Please try again.';

  @override
  String get enterRoomCode => 'Enter Room Code';

  @override
  String get roomNotFound => 'Room not found';

  @override
  String get roomNotFoundHelp =>
      'Room not found. Check the code and try again.';

  @override
  String get waitingRoom => 'Waiting Room';

  @override
  String get copyCode => 'Copy Code';

  @override
  String get shareRoomCode => 'Share Room Code';

  @override
  String shareRoomMessage(String code) {
    return 'Join my Guess Party room!\n\nRoom Code: $code\n\nEnter this code in the app to join the game!';
  }

  @override
  String playersNeededToStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Need $count more players to start',
      one: 'Need 1 more player to start',
    );
    return '$_temp0';
  }

  @override
  String get selectCategory => 'Select Category';

  @override
  String get numberOfRounds => 'Number of Rounds';

  @override
  String roundCount(int count) {
    return '$count rounds';
  }

  @override
  String playerCount(int count) {
    return '$count players';
  }

  @override
  String minuteCount(int count) {
    return '$count min';
  }

  @override
  String get enterRoomCodeValidation => 'Please enter a room code';

  @override
  String get roomCodeLengthValidation => 'Room code must be 6 digits';

  @override
  String get enterPlayerNames => 'Enter Player Names';

  @override
  String get enterPlayerNamesHelp =>
      'Enter names for players who will play on this device';

  @override
  String playerNumber(int number) {
    return 'Player $number';
  }

  @override
  String get enterName => 'Enter name...';

  @override
  String get minimumPlayersHelp =>
      'At least 2 players are required to start the game';

  @override
  String get categoryPlaces => 'Places';

  @override
  String get categoryAnimals => 'Animals';

  @override
  String get categoryFootballPlayers => 'Football Players';

  @override
  String get categoryIslamicFigures => 'Islamic Figures';

  @override
  String get categoryDailyProducts => 'Daily Products';

  @override
  String get categoryFoods => 'Foods';

  @override
  String get leaveGameTitle => 'Leave Game?';

  @override
  String get leaveGameMessage =>
      'Are you sure you want to leave? This will affect the current game.';

  @override
  String get stay => 'Stay';

  @override
  String get syncingPlayer => 'Syncing your player. Try again.';

  @override
  String get backOnlineSynced => 'Back online. Game synced.';

  @override
  String get loadingGame => 'Loading game...';

  @override
  String get waitingForPlayers => 'Waiting for players...';

  @override
  String get syncingRole => 'Syncing your role...';

  @override
  String get skipHintsConfirmation =>
      'Are you sure you want to skip to voting?';

  @override
  String get skipVotingConfirmation =>
      'Are you sure you want to skip to results?';

  @override
  String get sharedGameScreen => 'Shared game screen';

  @override
  String get sharedGameScreenHelp => 'Continue the round on the shared device.';

  @override
  String get character => 'Character';

  @override
  String get privateRoundLoading =>
      'Your private round information is still loading.';

  @override
  String get rolesArePrivate => 'Roles are private';

  @override
  String get useRevealMemory =>
      'Use what you saw during the pass-device reveal.';

  @override
  String get youAreImposter => 'You are the Imposter';

  @override
  String get imposterHelp =>
      'You do not know the character. Read the chat, blend in, and infer the answer.';

  @override
  String get stayConvincing => 'Stay convincing';

  @override
  String roundTitle(int number) {
    return 'Round $number';
  }

  @override
  String ofTotalRounds(int total) {
    return 'of $total';
  }

  @override
  String get viewFinalLeaderboard => 'View Final Leaderboard';

  @override
  String get waitingForHostLeaderboard =>
      'Waiting for the host to show the leaderboard...';

  @override
  String get startNextRound => 'Start Next Round';

  @override
  String get waitingForHostNextRound =>
      'Waiting for the host to start the next round...';

  @override
  String get finalLeaderboard => 'Final Leaderboard';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get exitRoleReveal => 'Exit Role Reveal?';

  @override
  String get exitRoleRevealMessage =>
      'Are you sure you want to exit? The game will be cancelled.';

  @override
  String get loadingSharedSession => 'Loading shared-device session...';

  @override
  String playerProgress(int current, int total) {
    return 'Player $current of $total';
  }

  @override
  String get passPhoneTo => 'Pass the phone to';

  @override
  String get protectRole => 'Make sure others cannot see!';

  @override
  String get youAreThe => 'You are the';

  @override
  String get imposterUpper => 'IMPOSTER!';

  @override
  String get innocentUpper => 'INNOCENT!';

  @override
  String get blendIn => 'Blend in! Do not get caught!';

  @override
  String get nextPlayer => 'Next Player';

  @override
  String get startGameExclamation => 'Start Game!';

  @override
  String get revealMyRole => 'Reveal My Role';

  @override
  String get revealRoleAction => 'Reveal Role';

  @override
  String get passDeviceTo => 'Pass device to';

  @override
  String get tapToSeeRole => 'Tap to see your role';

  @override
  String get doNotLetOthersSee => 'Do not let others see!';

  @override
  String get continueAction => 'Continue';

  @override
  String get imposterRevealHelp =>
      'Pretend to know the character and blend in with the others!';

  @override
  String get innocentRevealHelp =>
      'Give hints about your character without revealing too much!';

  @override
  String get unableToLoadPlayerInfo => 'Unable to load player information';

  @override
  String get discussHints => 'Discuss and give hints verbally!';

  @override
  String get discussHintsHelp =>
      'Talk about the character without revealing yourself. The timer will move to voting automatically.';

  @override
  String get onlineHintHelp =>
      'Give a hint about the character without revealing yourself!';

  @override
  String get writeHint => 'Write your hint here';

  @override
  String get sendHint => 'Send Hint';

  @override
  String get hintExample => 'Example: It is used in a kitchen';

  @override
  String get hintRequired => 'Please write a hint first';

  @override
  String get hintTooShort => 'Hint must be at least 3 characters';

  @override
  String get hintTooLong => 'Hint is too long (maximum 100 characters)';

  @override
  String get localVotingHelp =>
      'Find the Imposter! Each player taps their own name, then picks who they suspect.';

  @override
  String get onlineVotingHelp => 'Vote for who you think is the Imposter!';

  @override
  String get tapOwnNameToVote => 'Tap your name to vote ↓';

  @override
  String get chooseSuspect => 'Choose a suspect:';

  @override
  String whoDoYouSuspect(String name) {
    return '$name, who do you suspect?';
  }

  @override
  String get tapPlayerToSuspect => 'Tap the player you think is the Imposter';

  @override
  String get cannotVoteForSelf => 'Cannot vote for self';

  @override
  String get cannotVoteSelf => 'You cannot vote for yourself';

  @override
  String get changeVote => 'Change Vote?';

  @override
  String changeVoteTo(String name) {
    return 'Change your vote to $name?';
  }

  @override
  String get showResultsNow => 'Show Results Now →';

  @override
  String get finalizingResults => 'Finalizing Results...';

  @override
  String votesProgress(int submitted, int required) {
    return 'Votes ($submitted/$required)';
  }

  @override
  String get hintsPhaseTitle => 'Hints Phase';

  @override
  String get votingPhaseTitle => 'Voting Phase';

  @override
  String get resultsTitle => 'Results';

  @override
  String get reportReasonHint => 'Tell us what happened';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get loadingMessages => 'Loading...';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get pageNotFound => 'Page Not Found';

  @override
  String get gameDataUnavailable => 'Game data unavailable.';

  @override
  String get enterUsernameShort => 'Enter username';

  @override
  String get yourUsername => 'Your Username';

  @override
  String get usernameRequired => 'Please enter your username';

  @override
  String get usernameTooShort => 'Username must be at least 2 characters';

  @override
  String get noPlayersYet => 'No players yet';

  @override
  String get reconnectingToGame => 'Reconnecting to game...';

  @override
  String get noHintsYet => 'No hints yet...';

  @override
  String hintsSubmitted(int submitted, int required) {
    return 'Hints Submitted ($submitted/$required)';
  }

  @override
  String get hiddenHint => 'Hidden hint';

  @override
  String get voteSubmittedWaiting => 'Vote submitted! Waiting for results...';

  @override
  String get syncingPlayerInfoHelp => 'Syncing player info... Please wait.';

  @override
  String get allVotesWaitingHost => 'All votes in! Waiting for host...';

  @override
  String get voteForPlayerPrompt => 'Tap the player you think is the Imposter';

  @override
  String get voteCountSingular => '1 vote';

  @override
  String voteCountPlural(int count) {
    return '$count votes';
  }

  @override
  String get vote => 'Vote';

  @override
  String get creatingRound => 'Creating Round...';

  @override
  String get imposterCaughtTitle => 'Imposter Caught';

  @override
  String get imposterEscapedTitle => 'Imposter Escaped';

  @override
  String get groupFoundHiddenPlayer => 'The group found the hidden player.';

  @override
  String get imposterAvoidedVote => 'The imposter avoided the vote.';

  @override
  String get imposterWas => 'The Imposter was:';

  @override
  String get votingResults => 'Voting Results';

  @override
  String mostVoted(String name, int count) {
    return 'Most voted: $name ($count votes)';
  }
}
