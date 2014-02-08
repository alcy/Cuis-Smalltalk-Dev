'From Squeak3.7 of ''4 September 2004'' [latest update: #5989] on 26 August 2008 at 1:17:48 pm'!
	"System level event handling."
	anEvent wasHandled ifTrue:[^self]. "not interested"
	anEvent hand removePendingBalloonFor: self.
	anEvent wasHandled: true.

	(anEvent controlKeyPressed
			and: [Preferences cmdGesturesEnabled])
		ifTrue: [^ self invokeMetaMenu: anEvent].

	"Make me modal during mouse transitions"
	anEvent hand newMouseFocus: self event: anEvent.
	anEvent blueButtonChanged ifTrue:[^self blueButtonDown: anEvent].

	self mouseDown: anEvent.
	anEvent hand removeHaloFromClick: anEvent on: self.

	(self handlesMouseStillDown: anEvent) ifTrue:[
		self startStepping: #handleMouseStillDown: 
			at: Time millisecondClockValue + self mouseStillDownThreshold
			arguments: {anEvent copy resetHandlerFields}
			stepTime: self mouseStillDownStepRate ].
! !
	"Add the items for changing the current fill style of the Morph"
	aMenu add: 'change color...' translated action: #changeColor! !
	"Add a handle within the halo box as per the haloSpec, and set it up to respond to the given event by sending the given selector to the given recipient.  Return the handle."

	| handle aPoint iconName colorToUse |
	aPoint := self 
				positionIn: haloBox
				horizontalPlacement: handleSpec horizontalPlacement
				verticalPlacement: handleSpec verticalPlacement.
	handle := OldEllipseMorph 
				newBounds: (Rectangle center: aPoint extent: HandleSize asPoint)
				color: (colorToUse := Color colorFrom: handleSpec color).
	self addMorph: handle.
	(iconName := handleSpec iconSymbol) ifNotNil: 
			[| form |
			form := ScriptingSystem formAtKey: iconName.
			form ifNotNil: 
					[handle addMorphCentered: ((OldImageMorph new)
								image: form;
								color: colorToUse makeForegroundColor;
								lock)]].
	handle 
		on: #mouseUp
		send: #endInteraction
		to: self.
	handle 
		on: eventName
		send: selector
		to: recipient.
	handle 
		setBalloonText: (target balloonHelpTextForHandle: handle) translated.
	^handle! !
	"Clean up after a user interaction with the a halo control"

	(target isInWorld not or: [owner isNil]) ifTrue: [^self].
	self isInWorld 
		ifTrue: [
			"make sure handles show in front, even if flex shell added"
			self comeToFront.
			self addHandles]! !
	"create the [accept] button"

	| result frame |
	result := (OldSimpleButtonMorph new)
				target: self;
				color: Color lightGreen.
	result borderColor: (Preferences menuAppearance3d 
				ifTrue: [#raised]
				ifFalse: [result color twiceDarker]).
	result
		label: 'Accept(s)' translated;
		actionSelector: #accept.
	result setNameTo: 'accept'.
	frame := OldLayoutFrame new.
	frame
		rightFraction: 0.5;
		rightOffset: -10;
		bottomFraction: 1.0;
		bottomOffset: -2.
	result layoutFrame: frame.
	self addMorph: result.
	^result! !
	"create the [cancel] button"

	| result frame |
	result := (OldSimpleButtonMorph new)
				target: self;
				color: Color lightRed.
	result borderColor: (Preferences menuAppearance3d 
				ifTrue: [#raised]
				ifFalse: [result color twiceDarker]).
	result
		label: 'Cancel(l)' translated;
		actionSelector: #cancel.
	result setNameTo: 'cancel'.
	frame := OldLayoutFrame new.
	frame
		leftFraction: 0.5;
		leftOffset: 10;
		bottomFraction: 1.0;
		bottomOffset: -2.
	result layoutFrame: frame.
	self addMorph: result.
	^result! !
	"Present this menu at the given point under control of the given  
	hand."

	| evt |
	self items isEmpty ifTrue: [^self].
	MenuIcons decorateMenu: self.
	(self submorphs select: [:m | m isKindOf: OldUpdatingMenuItemMorph]) 
		do: [:m | m updateContents].
	"precompute width"
	self 
		positionAt: aPoint
		relativeTo: (selectedItem ifNil: [self items first])
		inWorld: aWorld.
	aWorld addMorphFront: self.
	"Acquire focus for valid pop up behavior"
	hand newMouseFocus: self.
	aBoolean ifTrue: [hand newKeyboardFocus: self].
	evt := hand lastEvent.
	(evt isKeyboard or: [evt isMouse and: [evt anyButtonPressed not]]) 
		ifTrue: 
			["Select first item if button not down"

			self moveSelectionDown: 1 event: evt].
	self changed! !
	"PRIVATE - create an arrow with aSymbolDirectionDirection,  
	finalSizeInteger and aColor  
	 
	aSymbolDirectionDirection = #top, #bottom. #left or #right  
	 
	Try with:  
	(ScrollBar createArrowOfDirection: #top size: 32 color: Color  
	lightGreen) asMorph openInHand.  
	"

	| resizeFactor outerBox arrow resizedForm |
	resizeFactor := 4.
	outerBox := OldRectangleMorph new.
	outerBox
		extent: finalSizeInteger asPoint * resizeFactor;
		borderWidth: 0;
		color: aColor.
	""
	arrow := self createArrowOfDirection: aSymbolDirection in: outerBox bounds.
	arrow color: aColor muchDarker.
	outerBox addMorphCentered: arrow.
	""
	resizedForm := outerBox imageForm 
				magnify: outerBox imageForm boundingBox
				by: 1 / resizeFactor
				smoothing: 4.
	""
	^(resizedForm replaceColor: aColor withColor: Color transparent) 
		trimBordersOfColor: Color transparent! !
	"PRIVATE - create a box with finalSizeInteger and aColor  
	 
	Try with:  
	(ScrollBar createBoxOfSize: 32 color: Color lightGreen) asMorph  
	openInHand.  
	"

	| resizeFactor outerBox innerBox resizedForm |
	resizeFactor := 4.
	outerBox := OldRectangleMorph new.
	outerBox
		extent: finalSizeInteger asPoint * resizeFactor;
		borderWidth: 0;
		color: aColor.
	""
	innerBox := self createBoxIn: outerBox bounds.
	innerBox color: aColor muchDarker.
	outerBox addMorphCentered: innerBox.
	""
	resizedForm := outerBox imageForm 
				magnify: outerBox imageForm boundingBox
				by: 1 / resizeFactor
				smoothing: 4.
	""
	^(resizedForm replaceColor: aColor withColor: Color transparent) 
		trimBordersOfColor: Color transparent! !
	"Build the appearance menu for the world."
	^self fillIn: (self menu: 'appearance...') from: {
		{'system fonts...' . { self . #standardFontDo} . 'Choose the standard fonts to use for code, lists, menus, window titles, etc.'}.
		nil.
		{#menuColorString . { Preferences . #toggleMenuColorPolicy} . 'Governs whether menu colors should be derived from the desktop color.'}.
		nil.
		{'full screen on' . { self . #fullScreenOn} . 'puts you in full-screen mode, if not already there.'}.
		{'full screen off' . { self . #fullScreenOff} . 'if in full-screen mode, takes you out of it.'}.
		nil.
		{'set display depth...' . {self. #setDisplayDepth} . 'choose how many bits per pixel.'}.
		{'set desktop color...' . {self. #changeBackgroundColor} . 'choose a uniform color to use as desktop background.'}.
	}! !
	"Answer a table defining default values for all the preferences in the release.  Returns a list of (pref-symbol, boolean-symbol) pairs"

	^  #(
		(abbreviatedBrowserButtons false)
		(alternativeBrowseIt false)
		(alternativeScrollbarLook true)
		(alternativeWindowLook true)
		(annotationPanes false)
		(automaticFlapLayout true)
		(automaticPlatformSettings true)
		(balloonHelpEnabled true)
		(browseWithPrettyPrint false)
		(browserShowsPackagePane false)
		(canRecordWhilePlaying false)
		(caseSensitiveFinds false)
		(changeSetVersionNumbers true)
		(checkForSlips true)
		(classicNewMorphMenu false)
		(cmdDotEnabled true)
		(collapseWindowsInPlace false)
		(colorWhenPrettyPrinting false)
		(confirmFirstUseOfStyle true)
		(conversionMethodsAtFileOut false)
		(cpuWatcherEnabled false)
		(debugHaloHandle true)
		(debugPrintSpaceLog false)
		(debugShowDamage false)
		(decorateBrowserButtons true)
		(diffsInChangeList true)
		(diffsWithPrettyPrint false)
		(dismissAllOnOptionClose false)
		(fastDragWindowForMorphic true)
		(fullScreenLeavesDeskMargins true)
		(hiddenScrollBars false)
		(higherPerformance false)
		(honorDesktopCmdKeys true)
		(ignoreStyleIfOnlyBold true)
		(inboardScrollbars true)
		(logDebuggerStackToFile true)
		(menuButtonInToolPane false)
		(menuColorFromWorld false)
		(menuKeyboardControl false)  
		(modalColorPickers true)
		(mouseOverForKeyboardFocus false)
		(noviceMode false)
		(optionalButtons true)
		(personalizedWorldMenu true)
		(projectsSentToDisk false)
		(propertySheetFromHalo false)
		(restartAlsoProceeds false)
		(reverseWindowStagger true)
		(scrollBarsNarrow false)
		(scrollBarsWithoutMenuButton false)
		(selectiveHalos false)
		(showBoundsInHalo false)
		(simpleMenus false)
		(smartUpdating true)
		(soundQuickStart false)
		(soundStopWhenDone false)
		(soundsEnabled true)
		(systemWindowEmbedOK false)
		(thoroughSenders true)
		(twentyFourHourFileStamps true)
		(uniqueNamesInHalos false)
		(warnIfNoChangesFile true)
		(warnIfNoSourcesFile true))


"
Preferences defaultValueTableForCurrentRelease do:
	[:pair | (Preferences preferenceAt: pair first ifAbsent: [nil]) ifNotNilDo:
			[:pref | pref defaultValue: (pair last == #true)]].
Preferences chooseInitialSettings.
"! !
	"The classic bright Squeak look.  Windows have saturated colors and relatively low contrast; scroll-bars are of the flop-out variety and are on the left.  Many power-user features are enabled."

	self setPreferencesFrom:
	#(
		(alternativeScrollbarLook false)
		(alternativeWindowLook false)
		(annotationPanes true)
		(automaticFlapLayout true)
		(balloonHelpEnabled true)
		(browseWithPrettyPrint false)
		(browserShowsPackagePane false)
		(classicNewMorphMenu false)
		(cmdDotEnabled true)
		(collapseWindowsInPlace false)
		(colorWhenPrettyPrinting false)
		(debugHaloHandle true)
		(debugPrintSpaceLog false)
		(debugShowDamage false)
		(decorateBrowserButtons true)
		(diffsInChangeList true)
		(diffsWithPrettyPrint false)
		(fastDragWindowForMorphic true)
		(fullScreenLeavesDeskMargins true)
		(hiddenScrollBars false)
		(ignoreStyleIfOnlyBold true)
		(inboardScrollbars false)
		(logDebuggerStackToFile true)
		(menuButtonInToolPane false)
		(menuColorFromWorld false)
		(menuKeyboardControl true)  
		(mouseOverForKeyboardFocus true)
		(noviceMode false)
		(optionalButtons true)
		(personalizedWorldMenu true)
		(propertySheetFromHalo false)
		(restartAlsoProceeds false)
		(reverseWindowStagger true)
		(scrollBarsNarrow false)
		(scrollBarsWithoutMenuButton false)
		(selectiveHalos false)
		(simpleMenus false)
		(smartUpdating true)
		(systemWindowEmbedOK false)
		(thoroughSenders true)
		(warnIfNoChangesFile true)
		(warnIfNoSourcesFile true))! !

	self setPreferencesFrom:

	#(	
		(alternativeScrollbarLook true)
		(alternativeWindowLook true)
		(annotationPanes true)
		(balloonHelpEnabled false)
		(browseWithPrettyPrint false)
		(browserShowsPackagePane false)
		(caseSensitiveFinds true)
		(checkForSlips true)
		(cmdDotEnabled true)
		(collapseWindowsInPlace false)
		(colorWhenPrettyPrinting false)
		(diffsInChangeList true)
		(diffsWithPrettyPrint false)
		(fastDragWindowForMorphic true)
		(honorDesktopCmdKeys false)
		(ignoreStyleIfOnlyBold true)
		(inboardScrollbars true)
		(menuColorFromWorld false)
		(menuKeyboardControl true)  
		(mouseOverForKeyboardFocus false)
		(noviceMode false)
		(optionalButtons true)
		(personalizedWorldMenu false)
		(restartAlsoProceeds false)
		(scrollBarsNarrow true)
		(scrollBarsWithoutMenuButton false)
		(simpleMenus false)
		(smartUpdating true)
		(thoroughSenders true)
	"Similar to the brightSqueak theme, but with a number of idiosyncratic personal settings.   Note that mouseOverForKeyboardFocus & caseSensitiveFinds are both true"


	self setPreferencesFrom:
	#(
		(abbreviatedBrowserButtons false)
		(accessOnlineModuleRepositories noOpinion)
		(alternativeBrowseIt noOpinion)
		(alternativeScrollbarLook false)
		(alternativeWindowLook false)
		(annotationPanes true)
		(automaticFlapLayout true)
		(automaticPlatformSettings noOpinion)
		(balloonHelpEnabled true)
		(browseWithPrettyPrint false)
		(browserShowsPackagePane false)
		(canRecordWhilePlaying noOpinion)
		(caseSensitiveFinds true)
		(changeSetVersionNumbers true)
		(checkForSlips true)
		(classicNewMorphMenu false)
		(cmdDotEnabled true)
		(collapseWindowsInPlace false)
		(colorWhenPrettyPrinting false)
		(confirmFirstUseOfStyle true)
		(conservativeModuleDeActivation noOpinion)
		(conversionMethodsAtFileOut true)
		(cpuWatcherEnabled noOpinion)
		(debugHaloHandle true)
		(debugPrintSpaceLog true)
		(debugShowDamage false)
		(decorateBrowserButtons true)
		(diffsInChangeList true)
		(diffsWithPrettyPrint false)
		(dismissAllOnOptionClose true)
		(duplicateControlAndAltKeys false)
		(extraDebuggerButtons true)
		(fastDragWindowForMorphic true)
		(fullScreenLeavesDeskMargins true)
		(hiddenScrollBars false)
		(higherPerformance noOpinion)
		(honorDesktopCmdKeys true)
		(ignoreStyleIfOnlyBold true)
		(inboardScrollbars false)
		(lenientScopeForGlobals noOpinion)
		(logDebuggerStackToFile true)
		(menuButtonInToolPane false)
		(menuColorFromWorld false)
		(menuKeyboardControl true)  
		(modalColorPickers true)
		(modularClassDefinitions noOpinion)
		(mouseOverForKeyboardFocus true)
		(noviceMode false)
		(optionalButtons true)
		(personalizedWorldMenu true)
		(projectsSentToDisk noOpinion)
		(propertySheetFromHalo false)
		(restartAlsoProceeds false)
		(reverseWindowStagger true)
		(scrollBarsNarrow false)
		(scrollBarsWithoutMenuButton false)
		(selectiveHalos false)
		(showBoundsInHalo false)
		(simpleMenus false)
		(smartUpdating true)
		(soundQuickStart noOpinion)
		(soundsEnabled true)
		(soundStopWhenDone noOpinion)
		(strongModules noOpinion)
		(swapControlAndAltKeys noOpinion)
		(swapMouseButtons  noOpinion)
		(systemWindowEmbedOK false)
		(thoroughSenders true)
		(twentyFourHourFileStamps false)
		(uniqueNamesInHalos false)
		(warnIfNoChangesFile true)
		(warnIfNoSourcesFile true))! !

	self setPreferencesFrom:

	#(	
		(alternativeScrollbarLook true)
		(alternativeWindowLook false)
		(annotationPanes false)
		(balloonHelpEnabled false)
		(browseWithPrettyPrint false)
		(browserShowsPackagePane false)
		(caseSensitiveFinds true)
		(checkForSlips false)
		(cmdDotEnabled true)
		(collapseWindowsInPlace false)
		(colorWhenPrettyPrinting false)
		(diffsInChangeList false)
		(diffsWithPrettyPrint false)
		(fastDragWindowForMorphic true)
		(honorDesktopCmdKeys false)
		(ignoreStyleIfOnlyBold true)
		(inboardScrollbars true)
		(menuColorFromWorld false)
		(menuKeyboardControl false)  
		(mouseOverForKeyboardFocus true)
		(noviceMode false)
		(optionalButtons false)
		(personalizedWorldMenu false)
		(restartAlsoProceeds false)
		(scrollBarsNarrow false)
		(scrollBarsWithoutMenuButton false)
		(simpleMenus false)
		(smartUpdating false)
		(thoroughSenders false)
	"Settings generally similar to those found in a standard browser-plug-in-based Squeak image"

	self setPreferencesFrom: #(
		(alternativeScrollbarLook true)
		(alternativeWindowLook true)
		(honorDesktopCmdKeys false)
		(menuKeyboardControl false)
		(propertySheetFromHalo true)