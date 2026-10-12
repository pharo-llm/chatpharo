"
I am one entry of a settings list such as Applications or Extensions: something
the user can switch on or off, configure, and whose tools they can look at.

- `isEnabled` / `enable:` — the switch. A feature that cannot be switched off
  (`beAlwaysOn`) reports itself enabled and ignores the request.
- `newPresenter` — the panel that configures me.
- `tools` — the tools I bring to the model, shown under the panel.

`ChatPharoFeatureSettingsPresenter` displays a list of me. Applications and
extensions are described the same way, so they look and behave the same.

```smalltalk
(ChatPharoSettingsFeature named: 'Memory' description: 'Long-term memory' icon: #history)
	enabledWhen: [ settings memoryEnabled ] toggledBy: [ :state | settings memoryEnabled: state ];
	configuredBy: [ ChatPharoMemoryPresenter on: settings ]
```
"
Class {
	#name : 'ChatPharoSettingsFeature',
	#superclass : 'Object',
	#instVars : [
		'name',
		'description',
		'iconName',
		'enabledBlock',
		'toggleBlock',
		'presenterBlock',
		'toolsBlock'
	],
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'instance creation' }
ChatPharoSettingsFeature class >> named: aName description: aDescription icon: anIconName [

	^ self new
		  setName: aName description: aDescription icon: anIconName;
		  yourself
]

{ #category : 'configuring' }
ChatPharoSettingsFeature >> beAlwaysOn [

	enabledBlock := [ true ].
	toggleBlock := [ :state |  ]
]

{ #category : 'configuring' }
ChatPharoSettingsFeature >> configuredBy: aBlock [
	"aBlock answers a new presenter that configures me."

	presenterBlock := aBlock
]

{ #category : 'accessing' }
ChatPharoSettingsFeature >> description [

	^ description
]

{ #category : 'actions' }
ChatPharoSettingsFeature >> enable: aBoolean [

	toggleBlock value: aBoolean
]

{ #category : 'configuring' }
ChatPharoSettingsFeature >> enabledWhen: aStateBlock toggledBy: aToggleBlock [

	enabledBlock := aStateBlock.
	toggleBlock := aToggleBlock
]

{ #category : 'accessing' }
ChatPharoSettingsFeature >> iconName [

	^ iconName
]

{ #category : 'initialization' }
ChatPharoSettingsFeature >> initialize [

	super initialize.
	self beAlwaysOn.
	toolsBlock := [ #(  ) ]
]

{ #category : 'testing' }
ChatPharoSettingsFeature >> isEnabled [

	^ enabledBlock value
]

{ #category : 'accessing' }
ChatPharoSettingsFeature >> name [

	^ name
]

{ #category : 'accessing' }
ChatPharoSettingsFeature >> newPresenter [

	^ presenterBlock value
]

{ #category : 'configuring' }
ChatPharoSettingsFeature >> providingTools: aBlock [
	"aBlock answers the tools (ChatPharoClient) I bring to the model."

	toolsBlock := aBlock
]

{ #category : 'initialization' }
ChatPharoSettingsFeature >> setName: aName description: aDescription icon: anIconName [

	name := aName.
	description := aDescription.
	iconName := anIconName
]

{ #category : 'accessing' }
ChatPharoSettingsFeature >> tools [

	^ toolsBlock value
]
