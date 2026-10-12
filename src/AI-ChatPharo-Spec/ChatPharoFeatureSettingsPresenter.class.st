"
I show a list of `ChatPharoSettingsFeature`s on the left — each with a check box
to switch it on or off — and, on the right, the selected feature: what it is,
its configuration panel and the tools it brings.

Applications and Extensions are two subclasses of me that only differ by the
features they list, which is why both tabs of the settings look and work alike.
"
Class {
	#name : 'ChatPharoFeatureSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'model',
		'featureTable'
	],
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'testing' }
ChatPharoFeatureSettingsPresenter class >> isAbstract [

	^ self = ChatPharoFeatureSettingsPresenter
]

{ #category : 'initialization' }
ChatPharoFeatureSettingsPresenter >> connectPresenters [

	featureTable whenSelectedItemChangedDo: [ :feature | feature ifNotNil: [ self showFeature: feature ] ]
]

{ #category : 'layout' }
ChatPharoFeatureSettingsPresenter >> defaultLayout [

	^ self layoutShowing: (SpBoxLayout newTopToBottom
			   borderWidth: 8;
			   add: (self newLabel label: self emptySelectionHint) expand: false;
			   yourself)
]

{ #category : 'layout' }
ChatPharoFeatureSettingsPresenter >> detailLayoutFor: aFeature [

	| detail tools |
	detail := SpBoxLayout newTopToBottom
		          spacing: 6;
		          borderWidth: 8;
		          add: (self newLabel label: aFeature name) expand: false;
		          add: (self newLabel label: aFeature description) expand: false;
		          add: aFeature newPresenter;
		          yourself.
	tools := aFeature tools.
	tools ifNotEmpty: [
		detail
			add: (self newLabel label: 'Tools of ' , aFeature name , ' (' , tools size printString , ')') expand: false;
			add: ((ChatPharoToolListPresenter on: model)
					 tools: tools;
					 yourself) ].
	^ detail
]

{ #category : 'accessing' }
ChatPharoFeatureSettingsPresenter >> emptySelectionHint [

	^ 'Select an entry to configure it.'
]

{ #category : 'accessing' }
ChatPharoFeatureSettingsPresenter >> features [
	"The ChatPharoSettingsFeature instances I list."

	^ self subclassResponsibility
]

{ #category : 'initialization' }
ChatPharoFeatureSettingsPresenter >> initializePresenters [

	featureTable := self newTable
		                addColumn: ((SpCheckBoxTableColumn title: 'Active' evaluated: [ :feature | feature isEnabled ])
				                 onActivation: [ :feature | feature enable: true ];
				                 onDeactivation: [ :feature | feature enable: false ];
				                 width: 50;
				                 yourself);
		                addColumn: ((SpImageTableColumn title: '' evaluated: [ :feature | self iconNamed: feature iconName ])
				                 width: 24;
				                 yourself);
		                addColumn: (SpStringTableColumn title: self listTitle evaluated: [ :feature | feature name ]);
		                items: self features;
		                yourself
]

{ #category : 'layout' }
ChatPharoFeatureSettingsPresenter >> layoutShowing: aDetailLayout [

	^ SpPanedLayout newLeftToRight
		  positionOfSlider: 30 percent;
		  add: featureTable;
		  add: aDetailLayout;
		  yourself
]

{ #category : 'accessing' }
ChatPharoFeatureSettingsPresenter >> listTitle [

	^ self subclassResponsibility
]

{ #category : 'accessing - model' }
ChatPharoFeatureSettingsPresenter >> setModelBeforeInitialization: aSettings [

	model := aSettings
]

{ #category : 'actions' }
ChatPharoFeatureSettingsPresenter >> showFeature: aFeature [

	self layout: (self layoutShowing: (self detailLayoutFor: aFeature))
]
