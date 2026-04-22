"
Central policy object that decides whether a tool call coming from the LLM
is allowed to run. It is the single choke-point between the model's
intention (""I want to create class Foo"") and the live system being
actually modified.

Responsibilities:

- Keep the canonical set of **mutating** tool names: create_class,
  add_method, remove_method, sandbox_evaluate, etc. Read-only tools
  (get_packages, describe_package, ...) bypass confirmation entirely.
- Ask a **gate** object for a human decision when a mutating tool is
  invoked. The gate is pluggable: the Spec UI package installs a rich
  Spec dialog, the headless fallback uses `UIManager default` so things
  still work in the absence of Spec (or in tests).
- Remember ""always allow"" choices **for the current session only**. The
  session cache is intentionally not persisted: users should reconfirm in
  a fresh ChatPharo session.
- Speak the exact shape expected back by `ChatPharoTool` when the user
  denies a call: a Dictionary the model can read, rather than an Error.

Why this lives in AI-ChatPharo and not in AI-ChatPharo-Tools or
AI-ChatPharo-Spec: the Tools package cannot depend on Spec (the Spec
package requires AI-ChatPharo, not the other way around), but both need
to agree on a single policy object. `AI-ChatPharo` is the common base.

Typical call site:

```smalltalk
ChatPharoToolConfirmation default
    guardToolNamed: functionName
    arguments: parsedArgs
    ifDeniedDo: [ :cancellation | ^ cancellation ].
```
"
Class {
	#name : 'ChatPharoToolConfirmation',
	#superclass : 'Object',
	#instVars : [
		'gate',
		'sessionAllowList',
		'sessionDenyList'
	],
	#classInstVars : [
		'Default'
	],
	#category : 'AI-ChatPharo',
	#package : 'AI-ChatPharo'
}

{ #category : 'accessing' }
ChatPharoToolConfirmation class >> default [

	^ Default ifNil: [ Default := self new ]
]

{ #category : 'mutating tools' }
ChatPharoToolConfirmation class >> mutatingToolNames [
	"TODO: this must be dynamic "
	^ #( 'create_class' 'remove_class' 'rename_class' 'rename_classes_in_package' 'move_class_to_package' 'add_instance_variable'
	     'remove_instance_variable' 'set_class_comment' 'add_method' 'remove_method' 'rename_method' 'move_method_to_protocol'
	     'set_method_comment' 'create_package' 'set_package_comment' 'sandbox_evaluate' 'evaluate_expression' 'open_playground'
	     'create_temporal_tool' 'delete_temporal_tool' 'delete_all_temporal_tools' ) asSet
]

{ #category : 'class initialization' }
ChatPharoToolConfirmation class >> reset [

	<script>
	Default := nil
]

{ #category : 'building - actions' }
ChatPharoToolConfirmation >> actionLabelFor: aToolName [

	| labels |
	labels := Dictionary new
		          at: 'create_class' put: 'Create class';
		          at: 'remove_class' put: 'Remove class';
		          at: 'rename_class' put: 'Rename class';
		          at: 'rename_classes_in_package' put: 'Rename classes in package';
		          at: 'move_class_to_package' put: 'Move class to another package';
		          at: 'add_instance_variable' put: 'Add instance variable';
		          at: 'remove_instance_variable' put: 'Remove instance variable';
		          at: 'set_class_comment' put: 'Update class comment';
		          at: 'add_method' put: 'Add or replace method';
		          at: 'remove_method' put: 'Remove method';
		          at: 'rename_method' put: 'Rename method';
		          at: 'move_method_to_protocol' put: 'Move method to protocol';
		          at: 'set_method_comment' put: 'Update method comment';
		          at: 'create_package' put: 'Create package';
		          at: 'set_package_comment' put: 'Update package comment';
		          at: 'sandbox_evaluate' put: 'Evaluate code in sandbox';
		          at: 'evaluate_expression' put: 'Evaluate Smalltalk expression';
		          at: 'open_playground' put: 'Open Playground with code';
		          at: 'create_temporal_tool' put: 'Create temporal tool';
		          at: 'delete_temporal_tool' put: 'Delete temporal tool';
		          at: 'delete_all_temporal_tools' put: 'Delete all temporal tools';
		          yourself.
	^ labels at: aToolName ifAbsent: [ 'Run tool ' , aToolName ]
]

{ #category : 'private' }
ChatPharoToolConfirmation >> cancellationPayloadFor: aToolName reason: aString [

	^ Dictionary new
		  at: 'cancelled' put: true;
		  at: 'tool' put: aToolName;
		  at: 'reason' put: (aString ifEmpty: [ 'The user did not authorize this operation.' ]);
		  at: 'hint' put: 'Do not retry this operation without the user''s explicit agreement. Ask the user before trying again.';
		  yourself
]

{ #category : 'public' }
ChatPharoToolConfirmation >> clearSessionApprovals [

	self sessionAllowList removeAll.
	self sessionDenyList removeAll
]

{ #category : 'public' }
ChatPharoToolConfirmation >> confirmToolNamed: aToolName arguments: anArguments [

	^ [
		  (self gate
			   confirmToolNamed: aToolName
			   arguments: anArguments
			   action: (self actionLabelFor: aToolName)
			   summary: (self summaryForTool: aToolName arguments: anArguments)) ifNil: [ ChatPharoToolConfirmationDecision deny ] ]
		  on: Error
		  do: [ :e |
			  ChatPharoToolConfirmationDecision denyWithReason: 'Confirmation dialog failed: ' , e messageText ]
]

{ #category : 'accessing' }
ChatPharoToolConfirmation >> gate [

	^ gate ifNil: [ gate := ChatPharoToolConfirmationFallbackGate new ]
]

{ #category : 'accessing' }
ChatPharoToolConfirmation >> gate: aGate [

	gate := aGate
]

{ #category : 'public' }
ChatPharoToolConfirmation >> guardToolNamed: aToolName arguments: anArguments ifDeniedDo: aBlock [

	| decision |
	self isEnabled ifFalse: [ ^ self ].
	(self isMutatingTool: aToolName) ifFalse: [ ^ self ].
	(self isDeniedForSession: aToolName) ifTrue: [
		^ aBlock value: (self
				  cancellationPayloadFor: aToolName
				  reason: 'This tool was denied earlier with ''do not ask again'' for this chat.') ].
	(self isApprovedForSession: aToolName) ifTrue: [ ^ self ].

	decision := self confirmToolNamed: aToolName arguments: anArguments.

	decision isAlways ifTrue: [ self sessionAllowList add: aToolName ].
	decision isAlwaysDeny ifTrue: [
		self sessionDenyList add: aToolName.
		^ aBlock value: (self cancellationPayloadFor: aToolName reason: decision reason) ].
	decision isAllow ifTrue: [ ^ self ].

	^ aBlock value: (self cancellationPayloadFor: aToolName reason: decision reason)
]

{ #category : 'initialization' }
ChatPharoToolConfirmation >> initialize [

	super initialize.
	gate := nil.
	sessionAllowList := Set new.
	sessionDenyList := Set new
]

{ #category : 'testing' }
ChatPharoToolConfirmation >> isApprovedForSession: aToolName [

	^ self sessionAllowList includes: aToolName
]

{ #category : 'testing' }
ChatPharoToolConfirmation >> isDeniedForSession: aToolName [

	^ self sessionDenyList includes: aToolName
]

{ #category : 'testing' }
ChatPharoToolConfirmation >> isEnabled [

	^ [ ChatPharoSettings default confirmBeforeMutatingTools ]
		  on: Error
		  do: [ true ]
]

{ #category : 'testing' }
ChatPharoToolConfirmation >> isMutatingTool: aToolName [

	^ self class mutatingToolNames includes: aToolName
]

{ #category : 'private' }
ChatPharoToolConfirmation >> renderArgumentValue: aValue [

	| text limit |
	aValue isNil ifTrue: [ ^ '(none)' ].
	aValue isString ifTrue: [
			limit := 600.
			text := aValue.
			text size > limit ifTrue: [ ^ (text copyFrom: 1 to: limit) , ' … (' , text size asString , ' chars)' ].
			^ text ].
	(aValue isKindOf: Collection) ifTrue: [ ^ '[' , (', ' join: (aValue collect: [ :each | self renderArgumentValue: each ])) , ']' ].
	^ aValue printString
]

{ #category : 'accessing' }
ChatPharoToolConfirmation >> sessionAllowList [

	^ sessionAllowList ifNil: [ sessionAllowList := Set new ]
]

{ #category : 'accessing' }
ChatPharoToolConfirmation >> sessionDenyList [

	^ sessionDenyList ifNil: [ sessionDenyList := Set new ]
]

{ #category : 'private' }
ChatPharoToolConfirmation >> summaryForTool: aToolName arguments: anArguments [

	| stream dict |
	dict := anArguments isDictionary
		        ifTrue: [ anArguments ]
		        ifFalse: [ Dictionary new ].
	stream := (String new: 256) writeStream.
	stream
		nextPutAll: (self actionLabelFor: aToolName);
		nextPutAll: String cr.
	stream
		nextPutAll: '(';
		nextPutAll: aToolName;
		nextPutAll: ')';
		nextPutAll: String cr;
		nextPutAll: String cr.
	dict keys asSortedCollection do: [ :key |
			| value rendered |
			value := dict at: key.
			rendered := self renderArgumentValue: value.
			stream
				nextPutAll: key asString;
				nextPutAll: ': ';
				nextPutAll: rendered;
				nextPutAll: String cr ].
	dict isEmpty ifTrue: [
			stream
				nextPutAll: '(no arguments)';
				nextPutAll: String cr ].
	^ stream contents
]
