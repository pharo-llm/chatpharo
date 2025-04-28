"
### `ChatPharo` Class
Represents a GUI presenter for a chat application using the Pharo Smalltalk environment.

- **`open`**: Opens a new instance of the chat presenter.
- **`defaultLayout`**: Defines the vertical layout for the chat including toolbar and notebook.
- **`initialExtent`**: Calculates the initial size of the window based on font size and row height.
- **`initializePresenters`**: Initializes the components like the notebook and toolbar.
- **`title`**: Provides the title for the chat window.
"
Class {
	#name : 'ChatPharo',
	#superclass : 'SpPresenter',
	#instVars : [
		'toolbar',
		'notebook',
		'ollamaModel'
	],
	#category : 'AI-ChatPharo-Spec',
	#package : 'AI-ChatPharo',
	#tag : 'Spec'
}

{ #category : 'instance creation' }
ChatPharo class >> new [

	^ self on: OllamaAPI new
]

{ #category : 'examples' }
ChatPharo class >> open [
	<example>
	
	^ self new open
]

{ #category : 'toolbar' }
ChatPharo >> addNewChat [

    | newPage chatName|
	 chatName := 'Chat ', notebook pages size asString.
    newPage := SpNotebookPage
        title: chatName
        icon: (self iconNamed: #announcement)
        provider: [ ChatPharoSpecChat new ].
    notebook addPage: newPage.
    notebook selectPage: newPage
]

{ #category : 'layout' }
ChatPharo >> defaultLayout [
	"Layout of ChatPharo. Nicer design wanted..."
	
	self setTitle.
    ^ SpBoxLayout newTopToBottom
		  add: (SpBoxLayout newLeftToRight 
					add: toolbar expand: false;
					add: (self ollamaModelSelect)
							expand: true fill: true padding: 20
							) expand: false;

        add: notebook;
        yourself
]

{ #category : 'toolbar' }
ChatPharo >> deleteChat: aPageTitle [ 

    "Find the page by title and remove it if found."
    | pageToDelete |
    pageToDelete := notebook pages detect: [:page | page title = aPageTitle] ifNone: [^ self].
    
    (self confirm: 'Are you sure you want to delete this chat?')
        ifTrue: [
            notebook removePage: pageToDelete.
        ].

]

{ #category : 'TOREMOVE' }
ChatPharo >> initialExtent [

	| fontWidth rowHeight |
	fontWidth := (StandardFonts defaultFont widthOfString: 'M').
	rowHeight := self class inputTextHeight.
	^ (40@25) * (fontWidth @ rowHeight)
	
]

{ #category : 'initialization' }
ChatPharo >> initializePresenters [ 
    notebook := self newNotebook.
    toolbar := self newToolbar.
    
    toolbar add: (SpToolbarButtonPresenter new
        label: 'New Chat';
        icon: (self iconNamed: #add);
        help: 'Create a new chat';
        action: [ self addNewChat ];
        yourself).

	toolbar add: (SpToolbarButtonPresenter new
    	label: 'Delete Chat';
    	icon: (self iconNamed: #delete);
    	help: 'Delete the selected chat';
    	action: [ self deleteChat: (notebook selectedPage title) ];
    	yourself).
	
    toolbar add: (SpToolbarButtonPresenter new
        label: 'Save Chat';
        icon: (self iconNamed: #smallSave);
        help: 'Save current chat';
        action: [ self saveCurrentChat ];
        yourself).
        
    toolbar add: (SpToolbarButtonPresenter new
        label: 'Load Chat';
        icon: (self iconNamed: #smallOpen);
        help: 'Load saved chat';
        action: [ self loadChat ];
        yourself).

	toolbar add: (SpToolbarButtonPresenter new
        label: 'Settings';
        icon: (self iconNamed: #smallConfiguration);
        help: 'Open settings';
        action: [ self openSettings ];
        yourself).
    
    notebook addPage: (SpNotebookPage
        title: 'Chat'
        icon: (self iconNamed: #announcement)
        provider: [ ChatPharoSpecChat newWithParent: self])
]

{ #category : 'toolbar' }
ChatPharo >> loadChat [ 

    | fileReference jsonData messages newPage |
    
    fileReference := UIManager default 
        chooseExistingFileReference: 'Load chat'
        extensions: #('json')
        path: FileLocator home.
        
    fileReference ifNotNil: [
        jsonData := STON fromString: fileReference contents.
        messages := jsonData collect: [ :dict |
            "LLMAPIChatObjectMessage 
                role: (dict at: 'role')
                content: (dict at: 'content')"
        ].
        
        newPage := SpNotebookPage
            title: fileReference basename
            icon: (self iconNamed: #announcement)
            provider: [ 
                | chat |
                chat := ChatPharoSpecChat new.
                messages do: [ :msg | chat history addMessage: msg ].
                chat
            ].
            
        notebook addPage: newPage.
        notebook selectPage: newPage
    ]
]

{ #category : 'accessing' }
ChatPharo >> notebook [

	^ notebook
]

{ #category : 'accessing' }
ChatPharo >> notebook: anObject [

	notebook := anObject
]

{ #category : 'accessing' }
ChatPharo >> ollamaModel [
	^ ollamaModel 
]

{ #category : 'layout' }
ChatPharo >> ollamaModelSelect [
	"Add to ChatPharo a select ollama model"
	^ SpDropListPresenter new
			help: 'Select ollama model';
			items: self ollamaModel modelNames;
			display: [ :e | e  ];
			whenSelectedItemChangedDo: [ :ollamaModelName | self ollamaModel model: ollamaModelName];
			yourself
		
]

{ #category : 'toolbar' }
ChatPharo >> openSettings [ 

    | settingsWindow |
    settingsWindow := ChatPharoSettings new chatSettings: self.
    settingsWindow open
]

{ #category : 'toolbar' }
ChatPharo >> saveCurrentChat [

    | fileReference jsonData currentChat |
    currentChat := notebook selectedPage presenterProvider value.
    jsonData := STON toStringPretty: (currentChat history model collect: [ :msg |
        Dictionary new
            at: 'role' put: msg role;
            at: 'content' put: msg content;
            yourself
    ]).
    
    fileReference := UIManager default 
        chooseForSaveFileReference: 'Save chat'
        extensions: #('json')
        path: FileLocator home.
        
    fileReference ifNotNil: [
        fileReference writeStream
            nextPutAll: jsonData;
            close
    ]
]

{ #category : 'accessing - model' }
ChatPharo >> setModelBeforeInitialization: initialOllamaModel [

	ollamaModel := initialOllamaModel
]

{ #category : 'initialization' }
ChatPharo >> setTitle [
	titleHolder := 'ChatPharo'. 
]

{ #category : 'accessing' }
ChatPharo >> toolbar [

	^ toolbar
]

{ #category : 'accessing' }
ChatPharo >> toolbar: anObject [

	toolbar := anObject
]
