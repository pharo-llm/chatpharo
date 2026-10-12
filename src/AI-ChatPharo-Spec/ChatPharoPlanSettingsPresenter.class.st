"
I explain plan validation and open the Task Manager.
"
Class {
	#name : 'ChatPharoPlanSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'openTaskManagerButton'
	],
	#category : 'AI-ChatPharo-Spec-Plan',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Plan'
}

{ #category : 'layout' }
ChatPharoPlanSettingsPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 8;
		  add: 'When active, ChatPharo proposes a plan before a task with several actions,' expand: false;
		  add: 'and you approve or reject each step. Only approved steps are executed.' expand: false;
		  add: 'When inactive, plans are approved automatically and only show progress.' expand: false;
		  add: openTaskManagerButton expand: false;
		  yourself
]

{ #category : 'initialization' }
ChatPharoPlanSettingsPresenter >> initializePresenters [

	openTaskManagerButton := self newButton
		                         label: 'Open Task Manager';
		                         icon: (self iconNamed: #smallProfile);
		                         action: [ ChatPharoTaskManagerPresenter new open ];
		                         yourself
]
