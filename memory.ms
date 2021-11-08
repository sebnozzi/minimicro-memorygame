// This is a very simple game of "memory" using built-in assets.
// It is intended as a solitaire game.

clear

// How long can you look at cards before hiding them again
// In seconds
SECONDS_TO_PEEK=1

// These are the images to be used.
foodFileNames = [
"Apple.png",
"Bananas.png",
"Burger.png",
"Cake.png",
"Cheese.png",
"Cookie.png",
"Donut.png",
"Muffin.png",
"Pizza.png",
"Sushi.png"]

// The grid size should reflect the amount of images
countRows=4
countCols=5

// Dimensions and visual properties of the cards
boxWidth=120
boxHeight=120
boxBorder=10
cardColor="#008BFFFF"

// Margin between cards in the board
margin=20
// Dimensions and coordinates of the board
boardWidth=(boxWidth+margin)*countCols-margin
boardHeight=(boxHeight+margin)*countRows-margin
// Make the board centered
boardOriginX=960/2-(boardWidth/2)
boardOriginY=640/2-(boardHeight/2)

// Remove pixel display from slot to do off-screen painting
// gfx still points to the (now detached) pixel display
display(5).mode = displayMode.off

createCardBackImg = function()
	boxOriginX = 0
	boxOriginY = 0
	gfx.color = cardColor
	gfx.fillRect boxOriginX,boxOriginY,boxWidth,boxHeight
	return gfx.getImage(boxOriginX,boxOriginY,boxWidth,boxHeight)
end function

cards = []

CardSprite = new Sprite
CardSprite.fileName = "UNDEFINED"
CardSprite.variant = "A/B"
CardSprite.otherPair = null
CardSprite.backImg = createCardBackImg()
CardSprite.showingFront = false
CardSprite.showBack = function()
	self.image = self.backImg
	self.showingFront = false
end function
CardSprite.showFront = function()
	self.image = self.frontImg
	self.showingFront = true
end function

createCardSprite = function(variant,fileName,cardImg)
	cardSprite = new CardSprite
	cardSprite.variant = variant
	cardSprite.frontImg = cardImg
	cardSprite.fileName = fileName
	// Setting the localBounds is necessary to later being
	// able to ask wether the sprite was clicked or not
	cardSprite.localBounds = new Bounds
	cardSprite.localBounds.width = cardImg.width
	cardSprite.localBounds.height = cardImg.height
	cardSprite.showBack
	return cardSprite
end function

for fileName in foodFileNames
	img = file.loadImage("/sys/pics/food/"+fileName)
	boxOriginX = 0
	boxOriginY = 0
	gfx.color = cardColor
	gfx.fillRect boxOriginX,boxOriginY,boxWidth,boxHeight
	gfx.color = color.white
	gfx.fillRect(boxOriginX+boxBorder,
	boxOriginY+boxBorder,
	boxWidth-(boxBorder*2),
	boxHeight-(boxBorder*2))
	imgX = boxOriginX+(boxWidth/2)-img.width/2
	imgY = boxOriginY+(boxHeight/2)-img.height/2
	if fileName == "Apple.png" then
		// Adjust position of apple, because its image is not centered
		imgX = imgX - 5
	end if
	gfx.drawImage img,imgX,imgY
	cardImg = gfx.getImage(boxOriginX,boxOriginY,boxWidth,boxHeight)
	// We now have the image of the card, let's create sprites
	cardSpriteA = createCardSprite("A",fileName,cardImg)
	cardSpriteB = createCardSprite("B",fileName,cardImg)
	cardSpriteA.otherPair = cardSpriteB
	cardSpriteB.otherPair = cardSpriteA
	cards.push cardSpriteA
	cards.push cardSpriteB
end for

// Mix all the cards!
cards.shuffle

gfx.clear
// Restore (re-attach) the pixel display
display(5).mode = displayMode.pixel
clear

// Place cards on the board / screen
cardIdx = 0
for y in range(0,countRows-1)
	for x in range(0,countCols-1)
		cardOriginX = boardOriginX+(x*(boxWidth+margin))
		cardOriginY = boardOriginY+(y*(boxHeight+margin))
		card = cards[cardIdx]
		// Adjust sprite placement because coordinates
		// refer to the center of it, not its leftBottom corner.
		// Move it by half its size.
		card.x = cardOriginX+boxWidth/2
		card.y = cardOriginY+boxHeight/2
		display(4).sprites.push card
		// Take next card
		cardIdx = cardIdx + 1
	end for
end for

// Used to signalize the user that something special
// happened with these cards. Usually that a pair was found.
glowCards = function(cardsToGlow)
	for i in range(0,1)
		for transparency in range(255,80,-40)
			tintColor = color.rgba(255,255,255,transparency)
			for card in cardsToGlow
				card.tint = tintColor
			end for
			wait 0.01
			yield
		end for
		for transparency in range(80,255,40)
			tintColor = color.rgba(255,255,255,transparency)
			for card in cardsToGlow
				card.tint = tintColor
			end for
			wait 0.01
			yield
		end for
	end for
end function

// -- MAIN PROGRAM --

wasButtonDown = false
isButtonDown = false

attemptedCards = []
pairedCards = []

attempts = 0
startTime = time

while true
	isButtonDown = mouse.button  
	
	if isButtonDown and not wasButtonDown then
		if len(attemptedCards) >= 2 then
			// Bypass user clicks if already showing 2 attempted cards
			break
		end if
		for card in cards
			if card.contains(mouse) and not card.showingFront then
				attemptedCards.push card
				card.showFront	
			end if
		end for
	end if
	
	wasButtonDown = isButtonDown
	
	if len(attemptedCards) == 2 then
		cardA = attemptedCards[0]
		cardB = attemptedCards[1]
		if cardA.otherPair == cardB then
			// Match found!
			matchedCards = [cardA, cardB]
			pairedCards = pairedCards + matchedCards
			attemptedCards = []
			hideCardsTimeout = 0
			glowCards(matchedCards)
		else
			// No match - hide the pair after a while
			wait(SECONDS_TO_PEEK)
			for s in attemptedCards
				s.showBack
			end for
			attemptedCards = []
			attempts = attempts + 1
		end if
	end if	
	
	if len(pairedCards) == len(cards) then
		// Game is won
		endTime = time
		timeTaken = round(endTime-startTime,0)
		print "Solved! (in "+attempts+" attempts and "+timeTaken+" seconds)"
		choice = input("Play again? (y/n) ")
		if choice.lower.indexOf("y") == 0 then
			// Start all over
			run
		else
			exit
		end if		
	end if
	
	if key.available then
		k = key.get
		if k == "q" or key.pressed("escape") then
			exit
		end if
	end if
	
	yield
end while
