"
First-launch setup wizard for ChatPharo.
* Shows when ChatPharo is first installed or settings are not configured
* Asks for developer ID to verify if user is an authorized developer
* If not a developer, collects basic user information (name, organization)
* Saves configuration to ChatPharoSettings
* **Why** – provides a friendly onboarding experience and developer verification.
```smalltalk
ChatPharoSetupPresenter open.
ChatPharoSetupPresenter openIfNeeded.
"
Class {
	#name : 'ChatPharoSetupPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'titleLabel',
		'descriptionLabel',
		'developerIdInput',
		'verifyButton',
		'skipDeveloperButton',
		'userNameInput',
		'userOrganizationInput',
		'statusLabel',
		'currentStep',
		'contentContainer',
		'isDeveloperVerified',
		'selectedLevel',
		'levelButtons',
		'tutorialCheckbox',
		'useAdvisorDefaults',
		'privacyConsentCheckbox'
	],
	#category : 'AI-ChatPharo-Spec-Setup',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Setup'
}

{ #category : 'instance creation' }
ChatPharoSetupPresenter class >> open [
	"Open the setup wizard."

	^ self new open
]

{ #category : 'instance creation' }
ChatPharoSetupPresenter class >> openForAdvisorDefaults [
	"Open the setup wizard directly at the advisor defaults step."

	| presenter |
	presenter := self new.
	presenter open.
	presenter showAdvisorDefaultsStep.
	^ presenter
]

{ #category : 'instance creation' }
ChatPharoSetupPresenter class >> openIfNeeded [
	"Open the setup wizard only if not already configured, or if advisor defaults haven't been configured."

	| settings |
	settings := ChatPharoSettings default.

	"If not configured at all, show full setup wizard"
	settings isConfigured ifFalse: [
		^ self open ].

	"If configured but advisor defaults weren't configured, show just the advisor defaults step"
	settings advisorDefaultsConfigured ifFalse: [
		^ self openForAdvisorDefaults ].

	^ nil
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> applyAdvisorDefaults [
	"Apply the advisor recommended defaults with progress indicator."

	useAdvisorDefaults := true.
	statusLabel label: 'Applying recommended settings...'.

	"Close this window temporarily and show progress"
	self window close.

	ChatPharoDefaultsProgressPresenter openAndApplyThen: [
		"Reopen setup wizard at the user info step"
		| newSetup |
		newSetup := ChatPharoSetupPresenter new.
		newSetup
			privateSetDeveloperVerified: isDeveloperVerified;
			privateSetAdvisorDefaults: true;
			privateSetSelectedLevel: selectedLevel.
		newSetup open.
		newSetup showUserInfoStep ]
]

{ #category : 'initialization' }
ChatPharoSetupPresenter >> askOkToClose [
	"Prevent closing during advisor defaults step without making a choice."

	(currentStep = #advisorDefaults and: [ useAdvisorDefaults isNil ]) ifTrue: [
		self inform: 'Please choose whether to use recommended settings or configure manually.'.
		^ false ].
	^ true
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> configureLater [
	"Skip setup for now and mark configuration as deferred."

	| settings |
	settings := ChatPharoSettings default.
	settings isConfigured: true.
	settings advisorDefaultsConfigured: true.

	ChatPharoLogger logSystem: 'User deferred configuration'
		details: (Dictionary new
			at: 'isConfigured' put: true;
			at: 'advisorDefaultsConfigured' put: true;
			yourself).

	self window close
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> createLevelOptionRow: aButton title: aTitle description: aDescription [
	"Create a styled row for a level option with button and description"

	| descLabel |
	descLabel := self newLabel
		label: aDescription;
		yourself.

	^ SpBoxLayout newHorizontal
		spacing: 12;
		add: aButton expand: false;
		add: descLabel expand: true;
		yourself
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		spacing: 16;
		borderWidth: 20;
		add: titleLabel expand: false;
		add: descriptionLabel expand: false;
		add: contentContainer expand: true;
		add: statusLabel expand: false;
		yourself
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> finishSetup [
	"Save all configuration and optionally launch the tutorial."

	| settings wantsTutorial |
	settings := ChatPharoSettings default.

	"Save user info"
	userNameInput text trimBoth ifNotEmpty: [ :name |
		settings userName: name ].
	userOrganizationInput text trimBoth ifNotEmpty: [ :org |
		settings userOrganization: org ].

	"Save developer status"
	settings isDeveloper: isDeveloperVerified.

	"Save experience level"
	settings userLevel: selectedLevel.

	"Save tutorial preference"
	wantsTutorial := tutorialCheckbox state.
	settings wantsTutorial: wantsTutorial.

	"Mark as configured"
	settings isConfigured: true.

	ChatPharoLogger logSystem: 'User configuration completed'
		details: (Dictionary new
			at: 'isDeveloper' put: isDeveloperVerified;
			at: 'hasName' put: settings userName isNotEmpty;
			at: 'hasOrganization' put: settings userOrganization isNotEmpty;
			at: 'userLevel' put: selectedLevel;
			at: 'wantsTutorial' put: wantsTutorial;
			yourself).

	self inform: 'Configuration saved successfully!'.
	self window close.

	"Launch tutorial if requested"
	wantsTutorial ifTrue: [
		self defer: [ ChatPharoTutorial start ] ]
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> generateLocalDeveloperId [
	"Generate a local developer ID for testing."

	| token |
	token := ChatPharoDeveloperConfig generateLocalDeveloperId.
	developerIdInput text: token.
	statusLabel label: 'Local Developer ID generated. Click Verify to continue.'.
	verifyButton enabled: true
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> handleWelcomeConfigureLater [

	privacyConsentCheckbox state
		ifTrue: [ self configureLater ]
		ifFalse: [
			self inform: 'You cannot use our tools without accepting the privacy and setup concerns. Please contact us and tell us what does not work for you.' ]
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> handleWelcomeContinue [

	privacyConsentCheckbox state
		ifTrue: [
				ChatPharoLogger logSystem: 'User privacy consent registered' details: (Dictionary new
						 at: 'consentGiven' put: true;
						 at: 'timestamp' put: DateAndTime now printString;
						 yourself).
				self showDeveloperStep ]
		ifFalse: [
				self inform:
					'You cannot use our tools without accepting the privacy and setup concerns. Please contact us and tell us what does not work for you.' ]
]

{ #category : 'initialization' }
ChatPharoSetupPresenter >> initialize [

	super initialize.
	currentStep := #welcome.
	isDeveloperVerified := false.
	selectedLevel := 'beginner'.
	levelButtons := Dictionary new.
	useAdvisorDefaults := nil
]

{ #category : 'initialization' }
ChatPharoSetupPresenter >> initializePresenters [

	super initializePresenters.

	titleLabel := self newLabel
		              label: 'Welcome to ChatPharo';
		              yourself.

	descriptionLabel := self newLabel
		                    label: 'Let''s set up your profile. Are you a ChatPharo developer?';
		                    yourself.

	statusLabel := self newLabel
		               label: '';
		               yourself.

	contentContainer := SpPresenter new.

	self showWelcomeStep
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.

	aWindowPresenter
		title: 'ChatPharo Setup';
		initialExtent: 500@400;
		centered
]

{ #category : 'private' }
ChatPharoSetupPresenter >> privateSetAdvisorDefaults: aBoolean [
	"Set advisor defaults choice without triggering UI update. Used when reopening wizard."
	useAdvisorDefaults := aBoolean
]

{ #category : 'private' }
ChatPharoSetupPresenter >> privateSetDeveloperVerified: aBoolean [
	"Set developer verified status without triggering UI update. Used when reopening wizard."
	isDeveloperVerified := aBoolean
]

{ #category : 'private' }
ChatPharoSetupPresenter >> privateSetSelectedLevel: aString [
	"Set selected level without triggering UI update. Used when reopening wizard."
	selectedLevel := aString
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> saveUserConfiguration [
	"Save the user configuration and close the wizard."

	| settings |
	settings := ChatPharoSettings default.

	userNameInput text trimBoth ifNotEmpty: [ :name |
		settings userName: name ].

	userOrganizationInput text trimBoth ifNotEmpty: [ :org |
		settings userOrganization: org ].

	settings isDeveloper: isDeveloperVerified.
	settings isConfigured: true.

	ChatPharoLogger logSystem: 'User configuration completed'
		details: (Dictionary new
			at: 'isDeveloper' put: isDeveloperVerified;
			at: 'hasName' put: settings userName isNotEmpty;
			at: 'hasOrganization' put: settings userOrganization isNotEmpty;
			yourself).

	self inform: 'Configuration saved successfully!'.
	self window close
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> selectLevel: aLevelString [
	"Select the given experience level"

	selectedLevel := aLevelString.
	self updateLevelButtonStyles.
	statusLabel label: 'Selected: ', (ChatPharoSettings default userLevelDisplayNameFor: aLevelString)
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> showAdvisorDefaultsStep [
	"Show the advisor defaults configuration step. User must choose to proceed."

	| defaultsContainer buttonRow yesButton noButton infoLabel descriptionText settingsLabel |
	currentStep := #advisorDefaults.

	titleLabel label: 'Advisor Recommended Settings'.
	descriptionLabel label: 'Would you like to use the recommended configuration?'.
	statusLabel label: ''.

	infoLabel := self newLabel
		             label: 'The Advisor can automatically configure ChatPharo for optimal performance.';
		             yourself.

	descriptionText := self newText
		                   text: ChatPharoSafetyAdvisor defaultSettingsDescription;
		                   enabled: false;
		                   yourself.

	settingsLabel := self newLabel
		                 label: 'You can customize all settings later from the Settings menu.';
		                 yourself.

	yesButton := self newButton
		             label: 'Yes, use recommended settings';
		             icon: (self iconNamed: #glamorousAccept);
		             action: [ self applyAdvisorDefaults ];
		             yourself.

	noButton := self newButton
		            label: 'No, I will configure manually';
		            icon: (self iconNamed: #glamorousCancel);
		            action: [ self skipAdvisorDefaults ];
		            yourself.

	defaultsContainer := SpBoxLayout newTopToBottom
		                     spacing: 12;
		                     add: infoLabel expand: false;
		                     add: descriptionText expand: true;
		                     add: settingsLabel expand: false;
		                     yourself.

	buttonRow := SpBoxLayout newHorizontal
		             spacing: 8;
		             add: yesButton expand: true;
		             add: noButton expand: true;
		             yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
			 spacing: 12;
			 add: defaultsContainer expand: true;
			 add: buttonRow expand: false;
			 yourself).

	self layout: self defaultLayout
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> showDeveloperStep [
	"Show the developer verification step."

	| idRow buttonRow infoLabel localTokenButton localTokenRow configureLaterButton |
	currentStep := #developer.

	descriptionLabel label: 'Do you have a ChatPharo Developer ID?'.
	statusLabel label: ''.

	infoLabel := self newLabel
		             label: 'If you are verified, ChatPharo Advisor will be able to recommend the best configuration.';
		             yourself.


	developerIdInput := self newTextInput
		                    placeholder: 'Enter your Developer ID...';
		                    text: (ChatPharoSettings default developerId ifEmpty: [ '12345' ]);
		                    yourself.

	verifyButton := self newButton
		                label: 'Verify ID';
		                icon: (self iconNamed: #glamorousGo);
		                action: [ self verifyDeveloperId ];
		                yourself.

	localTokenButton := self newButton
		                    label: 'Generate local token';
		                    icon: (self iconNamed: #smallNew);
		                    action: [ self generateLocalDeveloperId ];
		                    yourself.

	skipDeveloperButton := self newButton
		                       label: 'Skip (I''m not a developer)';
		                       action: [ self showAdvisorDefaultsStep ];
		                       yourself.

	idRow := SpBoxLayout newHorizontal
		         spacing: 8;
		         add: developerIdInput expand: true;
		         add: verifyButton expand: false;
		         yourself.

	localTokenRow := SpBoxLayout newHorizontal
		                 spacing: 8;
		                 add: localTokenButton expand: true;
		                 yourself.

	buttonRow := SpBoxLayout newHorizontal
		             spacing: 8;
		             add: skipDeveloperButton expand: true;
		             yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
			 spacing: 12;
			 add: infoLabel expand: false;
			 add: idRow expand: false;
			 add: localTokenRow expand: false;
			 add: buttonRow expand: false;
			 yourself).

	self layout: self defaultLayout
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> showExperienceLevelStep [
	"Show the experience level selection step."

	| levelContainer buttonRow continueButton backButton beginnerButton intermediateButton advancedButton |
	currentStep := #experienceLevel.

	titleLabel label: 'Your Pharo Experience'.
	descriptionLabel label: 'What is your experience level with Pharo?'.
	statusLabel label: ''. "Create level selection buttons with descriptions"
	beginnerButton := self newButton
		                  label: 'Beginner';
		                  icon: (self iconNamed: #smallNew);
		                  help: 'New to Pharo - I am just starting to learn';
		                  action: [ self selectLevel: 'beginner' ];
		                  yourself.

	intermediateButton := self newButton
		                      label: 'Intermediate';
		                      icon: (self iconNamed: #smallDoIt);
		                      help: 'Familiar with Pharo basics - I can write simple programs';
		                      action: [ self selectLevel: 'intermediate' ];
		                      yourself.

	advancedButton := self newButton
		                  label: 'Advanced';
		                  icon: (self iconNamed: #smallSystemBrowser);
		                  help: 'Experienced Pharo developer - I know the system well';
		                  action: [ self selectLevel: 'advanced' ];
		                  yourself.

	levelButtons := Dictionary new
		                at: 'beginner' put: beginnerButton;
		                at: 'intermediate' put: intermediateButton;
		                at: 'advanced' put: advancedButton;
		                yourself. "Highlight the currently selected level"
	self updateLevelButtonStyles.

	levelContainer := SpBoxLayout newTopToBottom
		                  spacing: 12;
		                  add:
			                  (self
				                   createLevelOptionRow: beginnerButton
				                   title: 'Beginner'
				                   description: 'New to Pharo - I am just starting to learn')
		                  expand: false;
		                  add: (self
				                   createLevelOptionRow: intermediateButton
				                   title: 'Intermediate'
				                   description: 'Familiar with Pharo basics - I can write programs')
		                  expand: false;
		                  add:
			                  (self
				                   createLevelOptionRow: advancedButton
				                   title: 'Advanced'
				                   description: 'Experienced Pharo developer - I know the system well')
		                  expand: false;
		                  yourself.

	continueButton := self newButton
		                  label: 'Continue';
		                  icon: (self iconNamed: #glamorousGo);
		                  action: [ self showTutorialOfferStep ];
		                  yourself.

	backButton := self newButton
		              label: 'Back';
		              action: [ self showUserInfoStep ];
		              yourself.

	buttonRow := SpBoxLayout newHorizontal
		             spacing: 8;
		             add: backButton expand: false;
		             add: continueButton expand: false;
		             yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
			 spacing: 12;
			 add: levelContainer expand: true;
			 add: buttonRow expand: false;
			 yourself).


	self layout: self defaultLayout
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> showTutorialOfferStep [
	"Show the tutorial offer step."

	| tutorialContainer buttonRow finishButton backButton infoLabel tutorialDescription |
	currentStep := #tutorialOffer.

	titleLabel label: 'ChatPharo Tutorial'.
	descriptionLabel label: 'Would you like a quick tour of ChatPharo?'.
	statusLabel label: ''.

	infoLabel := self newLabel
		             label: 'Learn how to get the most out of ChatPharo with our interactive tutorial.';
		             yourself.

	tutorialDescription := self newLabel
		                       label: 'The tutorial covers: starting chats, sending messages, using code suggestions, and more.';
		                       yourself.

	tutorialCheckbox := self newCheckBox
		                    label: 'Yes, show me the tutorial after setup';
		                    state: true;
		                    yourself.

	tutorialContainer := SpBoxLayout newTopToBottom
		                     spacing: 16;
		                     add: infoLabel expand: false;
		                     add: tutorialDescription expand: false;
		                     add: tutorialCheckbox expand: false;
		                     yourself.

	finishButton := self newButton
		                label: 'Finish Setup';
		                icon: (self iconNamed: #glamorousAccept);
		                action: [ self finishSetup ];
		                yourself.

	backButton := self newButton
		              label: 'Back';
		              action: [ self showExperienceLevelStep ];
		              yourself.

	buttonRow := SpBoxLayout newHorizontal
		             spacing: 8;
		             add: backButton expand: false;
		             add: finishButton expand: false;
		             yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
			 spacing: 12;
			 add: tutorialContainer expand: true;
			 add: buttonRow expand: false;
			 yourself).

	self layout: self defaultLayout
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> showUserInfoStep [
	"Show the user information collection step."

	| nameRow orgRow buttonRow infoLabel continueButton |
	currentStep := #userInfo.

	isDeveloperVerified
		ifTrue: [ descriptionLabel label: 'Developer verified! Please provide your details.' ]
		ifFalse: [ descriptionLabel label: 'Please tell us a bit about yourself (optional).' ].

	statusLabel label: ''.

	infoLabel := self newLabel
		             label: 'This information helps personalize your ChatPharo experience.';
		             yourself.

	userNameInput := self newTextInput
		                 placeholder: 'Your name...';
		                 text: ChatPharoSettings default userName;
		                 yourself.

	userOrganizationInput := self newTextInput
		                         placeholder: 'Organization/Company (optional)...';
		                         text: ChatPharoSettings default userOrganization;
		                         yourself.

	continueButton := self newButton
		                  label: 'Continue';
		                  icon: (self iconNamed: #glamorousGo);
		                  action: [ self showExperienceLevelStep ].

	nameRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Name:') expand: false;
		           add: userNameInput expand: true;
		           yourself.

	orgRow := SpBoxLayout newHorizontal
		          spacing: 8;
		          add: (self newLabel label: 'Organization:') expand: false;
		          add: userOrganizationInput expand: true;
		          yourself.

	buttonRow := SpBoxLayout newHorizontal
		             spacing: 8;
		             add: continueButton expand: false;
		             yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
			 spacing: 12;
			 add: infoLabel expand: false;
			 add: nameRow expand: false;
			 add: orgRow expand: false;
			 add: buttonRow expand: false;
			 yourself).

	self layout: self defaultLayout
]

{ #category : 'initialization' }
ChatPharoSetupPresenter >> showWelcomeStep [

	| welcomeContainer privacyLabel termsButton continueButton configureLaterButton buttonRow |
	currentStep := #welcome.

	titleLabel label: 'Welcome to ChatPharo'.
	descriptionLabel label: 'Your AI-powered assistant for Pharo development.'.
	statusLabel label: ''.

	privacyLabel := self newLabel
		                label: 'ChatPharo is fully private.';
		                yourself.

	privacyConsentCheckbox := self newCheckBox
		                          label: 'I agree with the privacy policy';
		                          state: false;
		                          yourself.

	termsButton := self newButton
		               label: 'Privacy Policy & Terms';
		               icon: (self iconNamed: #glamorousBrowse);
		               action: [ WebBrowser openOn: 'https://pharo-llm.github.io/privacy.html' ];
		               yourself.

	continueButton := self newButton
		                  label: 'Get Started';
		                  icon: (self iconNamed: #glamorousGo);
		                  action: [ self handleWelcomeContinue ];
		                  yourself.

	configureLaterButton := self newButton
		                        label: 'Configure later';
		                        action: [ self handleWelcomeConfigureLater ];
		                        yourself.

	welcomeContainer := SpBoxLayout newTopToBottom
		                    spacing: 16;
		                    add: privacyLabel expand: false;
		                    add: termsButton expand: false;
		                    yourself.

	buttonRow := SpBoxLayout newHorizontal
		             spacing: 8;
		             add: continueButton expand: false;
		             add: configureLaterButton expand: false;
		             yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
			 spacing: 12;
			 add: welcomeContainer expand: true;
			 add: privacyConsentCheckbox expand: false;
			 add: buttonRow expand: false;
			 yourself).

	self layout: self defaultLayout
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> skipAdvisorDefaults [
	"User chose to configure manually."

	useAdvisorDefaults := false.
	ChatPharoSettings default advisorDefaultsConfigured: true.
	ChatPharoLogger logSystem: 'User skipped advisor defaults'
		details: Dictionary new.
	self showUserInfoStep
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> updateLevelButtonStyles [
	"Update the visual style of level buttons to show selection"

	levelButtons keysAndValuesDo: [ :level :button |
		level = selectedLevel
			ifTrue: [ button icon: (self iconNamed: #glamorousAccept) ]
			ifFalse: [
				level = 'beginner' ifTrue: [ button icon: (self iconNamed: #smallNew) ].
				level = 'intermediate' ifTrue: [ button icon: (self iconNamed: #smallDoIt) ].
				level = 'advanced' ifTrue: [ button icon: (self iconNamed: #smallSystemBrowser) ] ] ]
]

{ #category : 'layout' }
ChatPharoSetupPresenter >> verifyDeveloperId [
	"Verify the entered developer ID against the remote list."

	| enteredId |
	enteredId := developerIdInput text trimBoth.

	enteredId isEmpty ifTrue: [
			statusLabel label: 'Please enter a Developer ID.'.
			^ self ].

	statusLabel label: 'Verifying...'.
	verifyButton enabled: false.

	[
		| isValid settings |
		isValid := ChatPharoDeveloperConfig verifyDeveloperId: enteredId.

		self defer: [
				verifyButton enabled: true.
				isValid
					ifTrue: [
							isDeveloperVerified := true.
							settings := ChatPharoSettings default.
							settings developerId: enteredId.
							settings isDeveloper: true.
							statusLabel label: 'Developer ID verified successfully!'.
							self showAdvisorDefaultsStep ]
					ifFalse: [ statusLabel label: 'Invalid Developer ID. Please try again or skip.' ] ] ] fork
]
