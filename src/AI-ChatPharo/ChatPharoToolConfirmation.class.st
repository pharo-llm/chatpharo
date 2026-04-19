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
		'sessionAllowList'
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
	"The set of tool names that are considered system-mutating and must
	 be confirmed by the user before running. The list is intentionally
	 declarative so that adding a new mutating tool is a one-line change."

	^ #(
		"Class-level mutations"
		'create_class'
		'remove_class'
		'rename_class'
		'rename_classes_in_package'
		'move_class_to_package'
		'add_instance_variable'
		'remove_instance_variable'
		'set_class_comment'

		"Method-level mutations"
		'add_method'
		'remove_method'
		'rename_method'
		'move_method_to_protocol'
		'set_method_comment'

		"Package-level mutations"
		'create_package'
		'set_package_comment'

		"Code execution (even sandboxed, still an action)"
		'sandbox_evaluate'
		'evaluate_expression'
		'open_playground'

		"Temporal tools: the model creating/deleting its own tools"
		'create_temporal_tool'
		'delete_temporal_tool'
		'delete_all_temporal_tools'
	) asSet
]

{ #category : 'class initialization' }
ChatPharoToolConfirmation class >> reset [
	"Drop the singleton. Mostly useful for tests."

	<script>
	Default := nil
]

{ #category : 'building - actions' }
ChatPharoToolConfirmation >> actionLabelFor: aToolName [
	"A short human verb describing what the tool is about to do, used as
	 the headline of the confirmation dialog."

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
	^ labels at: aToolName ifAbsent: [ 'Run tool ', aToolName ]
]

{ #category : 'private' }
ChatPharoToolConfirmation >> cancellationPayloadFor: aToolName reason: aString [
	"The payload returned to the LLM when the user denies a tool call.
	 It follows the same dictionary shape all tool responses use, so the
	 model sees it as a normal (unsuccessful) result and can plan around it."

	^ Dictionary new
		at: 'cancelled' put: true;
		at: 'tool' put: aToolName;
		at: 'reason' put: (aString ifEmpty: [ 'The user did not authorize this operation.' ]);
		at: 'hint' put: 'Do not retry this operation without the user''s explicit agreement. Ask the user before trying again.';
		yourself
]

{ #category : 'public' }
ChatPharoToolConfirmation >> clearSessionApprovals [
	"Drop all ""always allow"" approvals for the current session. Call this
	 when starting a fresh chat so users re-consent to mutations."

	self sessionAllowList removeAll
]

{ #category : 'public' }
ChatPharoToolConfirmation >> confirmToolNamed: aToolName arguments: anArguments [
	"Ask the gate (or fallback) to confirm a tool invocation. Always
	 returns a ChatPharoToolConfirmationDecision — never nil, never throws."

	^ [
		(self gate
			confirmToolNamed: aToolName
			arguments: anArguments
			action: (self actionLabelFor: aToolName)
			summary: (self summaryForTool: aToolName arguments: anArguments))
			ifNil: [ ChatPharoToolConfirmationDecision deny ] ]
		on: Error
		do: [ :e |
			"If the UI layer fails, err on the safe side: deny."
			ChatPharoToolConfirmationDecision
				denyWithReason: 'Confirmation dialog failed: ', e messageText ]
]

{ #category : 'accessing' }
ChatPharoToolConfirmation >> gate [
	"The pluggable confirmation gate. Defaults to a UIManager-based fallback
	 so the system keeps working even when the Spec UI is not loaded."

	^ gate ifNil: [ gate := ChatPharoToolConfirmationFallbackGate new ]
]

{ #category : 'accessing' }
ChatPharoToolConfirmation >> gate: aGate [
	"Install a gate. The Spec presenter calls this at class initialization
	 to swap the fallback dialog for the rich Spec one."

	gate := aGate
]

{ #category : 'public' }
ChatPharoToolConfirmation >> guardToolNamed: aToolName arguments: anArguments ifDeniedDo: aBlock [
	"Main entry point used by ChatPharoTool. Runs through the full policy:

	 1. If confirmation is globally disabled, allow.
	 2. If the tool is read-only, allow.
	 3. If the user already approved this tool for the session, allow.
	 4. Otherwise, ask the gate and honour the answer.

	 On denial, evaluates aBlock with the cancellation payload the tool
	 must return to the model."

	| decision |
	self isEnabled ifFalse: [ ^ self ].
	(self isMutatingTool: aToolName) ifFalse: [ ^ self ].
	(self isApprovedForSession: aToolName) ifTrue: [ ^ self ].

	decision := self confirmToolNamed: aToolName arguments: anArguments.

	decision isAlways ifTrue: [
		self sessionAllowList add: aToolName ].
	decision isAllow ifTrue: [ ^ self ].

	^ aBlock value: (self
		cancellationPayloadFor: aToolName
		reason: decision reason)
]

{ #category : 'initialization' }
ChatPharoToolConfirmation >> initialize [

	super initialize.
	gate := nil.
	sessionAllowList := Set new
]

{ #category : 'testing' }
ChatPharoToolConfirmation >> isApprovedForSession: aToolName [

	^ self sessionAllowList includes: aToolName
]

{ #category : 'testing' }
ChatPharoToolConfirmation >> isEnabled [
	"Driven by the user setting. If the settings object is not yet
	 reachable (early boot), default to enabled — safe by default."

	^ [ ChatPharoSettings default confirmBeforeMutatingTools ]
		on: Error
		do: [ true ]
]

{ #category : 'testing' }
ChatPharoToolConfirmation >> isMutatingTool: aToolName [

	^ self class mutatingToolNames includes: aToolName
]

{ #category : 'accessing' }
ChatPharoToolConfirmation >> sessionAllowList [

	^ sessionAllowList ifNil: [ sessionAllowList := Set new ]
]

{ #category : 'private' }
ChatPharoToolConfirmation >> summaryForTool: aToolName arguments: anArguments [
	"Build a human-readable, multi-line description of what is about to
	 happen. Used by whichever gate displays the prompt — the fallback
	 UIManager path as well as the Spec dialog."

	| stream dict |
	dict := anArguments isDictionary
		ifTrue: [ anArguments ]
		ifFalse: [ Dictionary new ].
	stream := (String new: 256) writeStream.
	stream nextPutAll: (self actionLabelFor: aToolName); nextPutAll: String cr.
	stream nextPutAll: '('; nextPutAll: aToolName; nextPutAll: ')'; nextPutAll: String cr; nextPutAll: String cr.
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
		stream nextPutAll: '(no arguments)'; nextPutAll: String cr ].
	^ stream contents
]

{ #category : 'private' }
ChatPharoToolConfirmation >> renderArgumentValue: aValue [
	"Render an argument value for human display. Keeps long strings
	 (e.g. method source) readable by clipping with a tail indicator."

	| text limit |
	aValue isNil ifTrue: [ ^ '(none)' ].
	aValue isString ifTrue: [
		limit := 600.
		text := aValue.
		text size > limit ifTrue: [
			^ (text copyFrom: 1 to: limit) , ' … (', text size asString, ' chars)' ].
		^ text ].
	(aValue isKindOf: Collection) ifTrue: [
		^ '[', (', ' join: (aValue collect: [ :each | self renderArgumentValue: each ])), ']' ].
	^ aValue printString
]
