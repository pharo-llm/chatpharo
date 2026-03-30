Class {
	#name : 'ChatPharoIceTipCommentPanel',
	#superclass : 'IceTipCommentPanel',
	#instVars : [
		'generateButton'
	],
	#category : 'AI-ChatPharo-Env-Iceberg',
	#package : 'AI-ChatPharo-Env',
	#tag : 'Iceberg'
}

{ #category : 'private' }
ChatPharoIceTipCommentPanel >> appendResultText: aString [

	self defer: [ commentText text: aString ]
]

{ #category : 'private' }
ChatPharoIceTipCommentPanel >> buildPrompt [
	"Build a prompt string by iterating through the working copy diff tree roots and their children."

	^ String streamContents: [ :stream |
		self owner model workingCopyDiff treeRoots do: [ :root |
			root allChildrenDo: [ :child |
				(child value respondsTo: #printOnLLMQuery:) ifTrue: [
					stream
						<< 'On: ';
						<< child key;
						<< String lf.
					child value printOnLLMQuery: stream.
					stream
						<< String lf;
						<< '---';
						<< String lf ] ] ] ]
]

{ #category : 'private' }
ChatPharoIceTipCommentPanel >> commitMessageSystemPrompt [

	^ String streamContents: [ :stream |
		stream
			<< 'You are a Pharo developer generating an Iceberg commit message based on a diff.';
			<< String lf;
			<< 'Follow this commit template format and return ONLY the final commit message line:';
			<< String lf;
			<< ChatPharoSettings default commitMessageTemplate;
			<< String lf;
			<< 'Pick one prefix (#feat:, #fix:, #refactor:, #chore:, #comment:) and write an imperative concise message.' ]
]

{ #category : 'layout' }
ChatPharoIceTipCommentPanel >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: commentText;
		  add: (SpBoxLayout newLeftToRight
				   spacing: 5;
				   add: generateButton;
				   addLast: optionsButton;
				   yourself)
		  expand: false;
		  yourself
]

{ #category : 'private' }
ChatPharoIceTipCommentPanel >> generateCommitMessage [
	"Generates a commit message using the configured ChatPharo agent and displays it in the commentText."

	| prompt agent chat |
	prompt := self buildPrompt.
	prompt ifEmpty: [
		self defer: [ commentText text: '(No changes detected)' ].
		^ self ].
	agent := ChatPharoSettings default agent.
	agent := (agent isKindOf: ChatPharoAgent)
				 ifTrue: [ agent copyForChat ]
				 ifFalse: [ agent ].
	(agent respondsTo: #systemPrompt:) ifTrue: [
		agent systemPrompt: self commitMessageSystemPrompt ].
	self defer: [ commentText text: 'Generating commit message...' ].
	chat := ChatPharoChat new
				 agent: agent;
				 yourself.
	chat whenAnswerReceivedDo: [ :message | self appendResultText: message answer ].
	chat whenErrorReceivedDo: [ :errorMsg |
		self defer: [ commentText text: 'Error: ' , errorMsg ] ].
	chat sendMessage: prompt
]

{ #category : 'initialization' }
ChatPharoIceTipCommentPanel >> initializePresenters [

	super initializePresenters.
	generateButton := self newButton
			 icon: (self application iconNamed: #smallLeftFlush);
			 label: 'Generate commit message';
			 help: 'Generate the commit message based on the work';
			 action: [ self generateCommitMessage ];
			 yourself
]
