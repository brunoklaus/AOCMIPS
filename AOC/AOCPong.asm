######################################################################
# 			     PONG - INTRO                            #
######################################################################
#           Programmed by 					     #
#	Bruno Klaus de Aquino Afonso             		     #
#############s#########################################################
#	Controls (so far) :						     #
#	W to move Up menu					     #
#	S to move Down menu					     #
#	Z to select credits / go back to main menu		     #	
######################################################################
#	This program requires the Keyboard and Display MMIO          #
#       and the Bitmap Display to be connected to MIPS.              #
#								     #
#       Bitmap Display Settings:                                     #
#	Unit Width: 4						     #
#	Unit Height: 4						     #
#	Display Width: 512					     #
#	Display Height: 512					     #
#	Base Address for Display: 0x10010000     		     #
######################################################################
.data

	#A buffer is declared first to reserve space for the Display
	buffer: .space 65536 #= displaySize^2/unitSize^2 = number of words
	
	#Another buffer, where we dump the file bytes in the sys call
	#This has to be the same size as the max number of bytes in 
	#a .KLAUS file (65536 for 128x128 pixels, 8 for extra info)
	infoBuffer: .space 65544
	
	
	#A final buffer to load fonts
	fontBuffer: .space 4096
	
	
	#where the Bitmap display lies
	bmpAddr: .word 0x10010000 
	infoAddr: .word 0x10020000
	fontAddr: .word 0x10030008
	
	#These values must be consistent with buffer space
	bmpSize : .word 65536
	infoSize : .word 65536
	fontSize: .word 4096
	displaySize: .word 512
	unitSize: .word 4
	
	
	
	bgColor: .word 0x000000FF	#Default BG Color
	paddleColor: .word 0xFFFFFFFF	#Default paddle Color
	newLine : .asciiz "\n"
	
	#Finite State Machine for title Screen
	# 1 - Title, Button 1 Highlighted
	# 2 - Title, Button 2 Highlighted
	# 3 - Title, Button 3 Highlighted
	# 4 - Viewing credits
	
	TitleFMS: .word 0	
	numTitleButtons : .word 3


	#Strings of the .KLAUS files, IN ORDER
	fTitleScreen: .asciiz "titleScreenGrad.KLAUS"      # title screen 	
	fButton2P: .asciiz "button_2P.KLAUS"
	fButton4P: .asciiz "button_4P.KLAUS"
	fButtonCredits: .asciiz "button_credits.KLAUS"
	fLButtonCredits: .asciiz "lbutton_credits.KLAUS"
	fLButton2P: .asciiz "lbutton_2P.KLAUS"
	fLButton4P: .asciiz "lbutton_4P.KLAUS"
	fCreditsScreen: .asciiz "creditsGrad.KLAUS"
	.align 2
	fNumber0: .asciiz "0_00000.KLAUS"
	.align 2
	fNumber1: .asciiz "1_00000.KLAUS"
	.align 2
	fNumber2: .asciiz "2_00000.KLAUS"
	.align 2
	fNumber3: .asciiz "3_00000.KLAUS"
	.align 2
	fNumber4: .asciiz "4_00000.KLAUS"
	.align 2
	fNumber5: .asciiz "5_00000.KLAUS"
	.align 2
	fNumber6: .asciiz "6_00000.KLAUS"
	.align 2
	fNumber7: .asciiz "7_00000.KLAUS"
	.align 2
	fNumber8: .asciiz "8_00000.KLAUS"
	.align 2
	fNumber9: .asciiz "9_00000.KLAUS"
	.align 2
	fNumber10: .asciiz "10_00000.KLAUS"
	.align 2
	fDeuce: .asciiz "11_00000.KLAUS"
	.align 2
	fAdv: .asciiz "12_00000.KLAUS"
	.align 2
	
	fMinus: .asciiz "13_00000.KLAUS"
	.align 2
	fGameBG: .asciiz "gameBG.KLAUS"
	
	
	# Game Variables
	paddleW : .word 4
	paddleH : .word 30
	ballSize: .word 2
	numPlayers :.word 2
	OOBFlags : .space 16 #1 if ball out of bounds for (left, right, up, down), 0 otherwise
	
	#*_0 is for the ball, 1-4 for the players
	#X positions. Position X 1-4 stays constant
	initPosX_0: .float 64.0
	initPosX_1: .float 0.0
	initPosX_2: .float 124.0
	initPosX_3: .float 40.0
	initPosX_4: .float 84.0
	initBallVelX2Players : .float 100.0
	initBallVelY2Players : .float 100.0
	initBallVelX4Players : .float 70.0
	initBallVelY4Players : .float 70.0
	
	initPosY: .float 50.0
	initBallVelX : .float 70.0
	initBallVelY : .float 70.0
	
	
	#Now we declare the actual buffer of current game values
	posX: .space 20
	posY: .space 20
	oldPosY: .space 20 #stores positions at beginning of frame
	ballVelX: .float 0.0
	ballVelY: .float 0.0
	oldPosX: .float 0.0
	paddleVelY: .float 100.0 #velocity at which paddle moves
	#The state of all axes
	inputList: .word -1:4
	inputAddr: .word 0xFFFF0010
	
	#Place of score info
	scoreP1PosX: .word 16
	scoreP2PosX: .word 80
	scoreP1: .word 0
	scoreP2: .word 0
	
	
	#64-bit current time
	cTime_0 : .word 0	
	cTime_1: .word 0			
	frameEnded: .asciiz "Frame Ended\n"
	colDetected: .asciiz"Collision detected \n"
	frameDuration : .float 0.03333333
	
	roof: .word 4
	floor: .word 124
	
	
	
	
	

.text
Init:

#Load Title Screen Image
la   $a0, fTitleScreen      
jal LoadFile
li $a0, 0
li $a1, 0
jal DrawPNGOnDisplay

#Load Buttons

la   $a0, fLButton2P      
jal LoadFile
li $a0, 8
li $a1, 37
jal DrawPNGOnDisplay

la   $a0, fButton4P      
jal LoadFile
li $a0, 8
li $a1, 61
jal DrawPNGOnDisplay

la   $a0, fButtonCredits    
jal LoadFile
li $a0, 8
li $a1, 85
jal DrawPNGOnDisplay




addi $s0, $zero, 0
sw $s0, TitleFMS 


j TitleLoop


###########################################
#TitleLoop keeps checking for a button press
TitleLoop:

#Read from keyboard
	li $t0, 0xffff0000
	lw $t1, ($t0)
	andi $t1, $t1, 0x0001
	beqz $t1, TitleLoop #if no new input, return to loop
	lw $a0, 4($t0)
	jal TitleProcessInput #validate new input

j TitleLoop


####################################################
### Validates input for title FMS
### @param a0 the value of the input
### @return v0 1 if equals to W,S or Z. Otherwise, 0
TitleProcessInput:
andi $v0, 0
beq $a0, 119,TitleProcessUp #W
beq $a0, 115,TitleProcessDown #S
beq $a0, 122,TitleProcessEnter #Z
ori $v0, 1 #input not valid
TitleProcessInputEnd:
jr $ra




###############
TitleProcessUp:
li $t0, -1
j TitleProcessDirection
TitleProcessDown:
li $t0, 1
TitleProcessDirection:
#s0 -> increment
#t1 -> mod (number of buttons)
#t3 -> fmsState
addi $sp, $sp, -8
sw $ra, 0($sp) 
sw $s0, 4($sp)

move $s0, $t0 
lw $a0, TitleFMS
jal DrawTitleButton #Unselect the current button


lw $t1, numTitleButtons
lw $t3, TitleFMS
add $t3, $t3, $s0

div  $t3, $t1 
mfhi $t3

##We need to correct the value if it was negative
bge  $t3, $zero, UpdateTitleFMS
add $t3, $t3, $t1

UpdateTitleFMS:
sw $t3, TitleFMS

#a0 -> number of the highlighted button to be drawn
add $a0, $t3, $t1 
jal DrawTitleButton

#restore ra and s0
lw $ra, 0($sp) 
lw $s0, 4($sp)
addi $sp, $sp, 8

j TitleProcessInputEnd


###############
TitleProcessEnter:


lw $t0, TitleFMS
addi $t0, $t0, 1
addi $t4, $zero, 0 
		
		addi $t4, $t4, 1 # case 2: set temp to 1
		bne $t0, $t4, TE2_COND # false: branch to case 1 cond
		j TE1_BODY # true: branch to case 2 body
		
TE2_COND:	addi $t4, $t4, 1 
		bne $t0, $t4, TE3_COND 
		j TE2_BODY 
		
TE3_COND:	addi $t4, $t4, 1 
		bne $t0, $t4, TE4_COND 
		j TE3_BODY 

TE4_COND:	addi $t4, $t4, 1 
		bne $t0, $t4, TitleProcessInputEnd 
		j TE4_BODY
TE1_BODY: 
li $t4, 2
sw $t4, numPlayers
lwc1 $f1, initBallVelX2Players
swc1 $f1, initBallVelX
lwc1 $f1, initBallVelY2Players
swc1 $f1, initBallVelY

j InitGame
TE2_BODY:
li $t4, 4
sw $t4, numPlayers
lwc1 $f1, initBallVelX4Players
swc1 $f1, initBallVelX
lwc1 $f1, initBallVelY4Players
swc1 $f1, initBallVelY
j InitGame
TE3_BODY:

addi $sp, $sp, -4
sw $ra 0($sp)
#Update FMS
sw $t0 TitleFMS
#We have selected the credits option, so draw credits
la $a0 fCreditsScreen
jal LoadFile
li $a0, 0
li $a1, 0
jal DrawPNGOnDisplay
lw $ra 0($sp)
addi $sp, $sp, 4
j TitleProcessInputEnd
TE4_BODY:
j Init


##############################################
#Draws the desired title button on the screen
#	@param a0 the button number
DrawTitleButton:

	addi $sp, $sp, -4
	sw $ra, 0($sp) #store $ra
	


		addi $t4, $zero, 0 
		bne $a0, $t4, TB1_COND 
		j TB0_BODY # true: branch to case 0 body
		
TB1_COND:	addi $t4, $t4, 1 # case 2: set temp to 1
		bne $a0, $t4, TB2_COND # false: branch to case 1 cond
		j TB1_BODY # true: branch to case 2 body
		
TB2_COND:	addi $t4, $t4, 1 
		bne $a0, $t4, TB3_COND 
		j TB2_BODY 
		
TB3_COND:	addi $t4, $t4, 1 
		bne $a0, $t4, TB4_COND 
		j TB3_BODY 
		
TB4_COND:	addi $t4, $t4, 1 
		bne $a0, $t4, TB5_COND 
		j TB4_BODY 
TB5_COND:	addi $t4, $t4, 1 
		bne $a0, $t4, DrawTitleButtonEnd 
		j TB5_BODY 
TB0_BODY: 
la   $a0, fButton2P      
jal LoadFile
li $a0, 8
li $a1, 37
jal DrawPNGOnDisplay
j DrawTitleButtonEnd
TB1_BODY: 
la   $a0, fButton4P      
jal LoadFile
li $a0, 8
li $a1, 61
jal DrawPNGOnDisplay
j DrawTitleButtonEnd
TB2_BODY: 
la   $a0, fButtonCredits    
jal LoadFile
li $a0, 8
li $a1, 85
jal DrawPNGOnDisplay
j DrawTitleButtonEnd
TB3_BODY: 
la   $a0, fLButton2P      
jal LoadFile
li $a0, 8
li $a1, 37
jal DrawPNGOnDisplay
j DrawTitleButtonEnd
TB4_BODY: 
la   $a0, fLButton4P      
jal LoadFile
li $a0, 8
li $a1, 61
jal DrawPNGOnDisplay
j DrawTitleButtonEnd
TB5_BODY: 
la   $a0, fLButtonCredits    
jal LoadFile
li $a0, 8
li $a1, 85
jal DrawPNGOnDisplay


DrawTitleButtonEnd:
#restore ra
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
###########################################
DrawPNGOnDisplay:
#Moves the latest thing on info buffer to the display.
#	@param a0 the x position
#	@param a1 the y position

	
	addi $sp, $sp, -24
	sw $ra, 0($sp) #stuff
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)

	#t1 - holds hold (displaySize^2)/(UnitSize^2)(number of words in bmp)
	#t3 - gets info buffer address initially, will be pointer to current address
	#t2 - gets display address will not change
	#t5 - get nullColor
	
	lw $t2, infoAddr #to be incremented
	lw $t3, bmpAddr # = y' * numBytesPerLine + z'
	
	lw $t5, bgColor  		
	
	#t1 will be number of bytes in a line
	lw $t1, displaySize
	
	#getSize info
	lw $t6, 0($t2) #width
	lw $t7, 4($t2) #height
	addi $t2, $t2, 8
	
	move $s0, $a0 #s0 gets initial x , will be x'  
	move $s1, $a1 #s1 gets initial y, will be y'
	
	add $t6, $t6, $s0 #t6 now holds x+width
	add $t7, $t7, $s1 #t7 now holds y+height
	
	
	
	
	
	WhileDrawPNGOnDisplayY:

	slt $s3, $s1, $t7
	beq $s3, $zero, WhileDrawPNGOnDisplayYEnd	
	move $s0, $a0 # x' is reset to x
	
	WhileDrawPNGOnDisplayX:
	slt $s3, $s0, $t6
	beq $s3, $zero, WhileDrawPNGOnDisplayXEnd
	
	#Move pixel to mapped address
	lw $s3, ($t2)
	
	#Check if transparent
	move $t4, $s3
	srl $t4, $t4, 24
	
	blt $t4, 120, WhileDrawPNGOnEndStore  
 
	
	#t4 will get  initDisplayAddr + (numBytesPerLine * y' + x' * 4)  
	move $t4, $t1
	mult $t4, $s1
	mflo $t4
	
	add $t4, $t4, $s0
	add $t4, $t4, $s0
	add $t4, $t4, $s0
	add $t4, $t4, $s0
	
	add $t4, $t4, $t3
	#Store
	sw $s3, ($t4)  
	WhileDrawPNGOnEndStore:  
	  
	#Increment accordingly
	addi $t2, $t2, 4 #increment infobuffer ptr
	add $s0, $s0, 1	#increment x'
	j WhileDrawPNGOnDisplayX
	
	WhileDrawPNGOnDisplayXEnd:
	add $s1, $s1, 1	#increment y'
	j WhileDrawPNGOnDisplayY
			
	WhileDrawPNGOnDisplayYEnd:


	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp, 24
	
	
	jr $ra





##############################################
###########################################
DrawPaddleOnDisplay:
#So, this is pretty much a copy-paste of  DrawPNGOnDisplay.
#Main differences is the need to specify width, height.
#This also uses the PaddleColor variable instead of 
# sampling directly from the png 
#Moves the latest thing on info buffer to the display.
#	@param a0 the x position (left)
#	@param a1 the y position  (top)
#	@param a2 the width
#	@param a3 the height

	addi $sp, $sp, -24	
	sw $ra, 0($sp) #stuff
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)

	#t1 - holds hold (displaySize^2)/(UnitSize^2)(number of words in bmp)
	#t3 - gets info buffer address initially, will be pointer to current address
	#t2 - gets display address will not change
	#t5 - get nullColor
	
	lw $t3, bmpAddr # = y' * numBytesPerLine + z'
	
	#t1 will be number of bytes in a line
	lw $t1, displaySize
	
	#getSize info
	move $t6, $a2 #width
	move $t7, $a3 #height
	
	move $s0, $a0 #s0 gets initial x , will be x'  
	move $s1, $a1 #s1 gets initial y, will be y'
	
	add $t6, $t6, $s0 #t6 now holds x+width
	add $t7, $t7, $s1 #t7 now holds y+height
	
	
	WhileDrawPaddleOnDisplayY:

	slt $s3, $s1, $t7
	beq $s3, $zero, WhileDrawPaddleOnDisplayYEnd	
	move $s0, $a0 # x' is reset to x
	
	WhileDrawPaddleOnDisplayX:
	slt $s3, $s0, $t6
	beq $s3, $zero, WhileDrawPaddleOnDisplayXEnd
	
	#Move pixel to mapped address
	lw $s3, paddleColor
	#t4 will get  initDisplayAddr + (numBytesPerLine * y' + x' * 4)  
	move $t4, $t1
	mult $t4, $s1
	mflo $t4
	
	add $t4, $t4, $s0
	add $t4, $t4, $s0
	add $t4, $t4, $s0
	add $t4, $t4, $s0
	
	add $t4, $t4, $t3
	#Store
	sw $s3, ($t4)  
	  
	  
	#Increment accordingly
	addi $t2, $t2, 4 #increment infobuffer ptr
	add $s0, $s0, 1	#increment x'
	j WhileDrawPaddleOnDisplayX
	
	WhileDrawPaddleOnDisplayXEnd:
	add $s1, $s1, 1	#increment y'
	j WhileDrawPaddleOnDisplayY
			
	WhileDrawPaddleOnDisplayYEnd:


	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp, 24
	
	
	jr $ra

####################################################################################
#LoadFontNumber - Loads the font of given Number into the info buffer
LoadFontNumber:
#	@param a0 the number of the font
#	@param a1 the x pos
#	@param a2 the y pos
	#make backup
	
	addi $sp, $sp, -24
	sw $ra, 0($sp) 
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	
	lw $s0, bmpAddr
	lw $s1, infoAddr
	lw $s2, bmpSize
	lw $s3, infoSize
	lw $s4, displaySize
	#We cheat by 
	#a) change infoAddr to fontAddr so that it goes to
	#the proper location when we call LoadFile
	#b)change bmpAddr to the old (infoAddr + 8) and call DrawPNGOnDisplay
	#c) restore
	
	#do a)
	lw $t0, fontAddr
	lw $t1, fontSize
	sw $t0, infoAddr
	sw $t1, infoSize
	li $t0, 32
	sw $t0, displaySize
	
	move $t0, $a0
	sll $t0, $t0, 4
	la $a0, fNumber0
	add $a0, $a0, $t0
	#backup
	
	addi $sp, $sp, -12
	sw $a1, 0($sp) 
	sw $a2, 4($sp)
	jal LoadFile
	lw $a1, 0($sp) 
	lw $a2, 4($sp)
	addi $sp, $sp, 12
	
	#do b)
	move $t0, $s1 #t0 is old infoAddr
	add $t0, $t0, 8
	sw $t0, bmpAddr
	move $t0, $s1 #t0 is old infoSize
	sw $t0, bmpSize
	
	move $a0, $a1
	move $a1, $a2
	
	sw $s4, displaySize
	jal DrawPNGOnDisplay
	
	#do c)
	sw $s0, bmpAddr
	sw $s1, infoAddr
	sw $s2, bmpSize
	sw $s3, infoSize
	sw $s4, displaySize

	lw $ra, 0($sp) 
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp, 24
	jr $ra	

##################################################################################
#ClearBgPartial - Cleans Display by using the background. Guess what, it is another
#DrawPNGOnDisplay copypasta, but it applies the coordinates transformation
#for the target in DrawPNGOnDisplay for the source as well
ClearBgPartial:	
	#Moves the latest thing on info buffer to the display.
#	@param a0 the x position
#	@param a1 the y position
#	@param a2 the x size
#	@param a3 the y size
	
	addi $sp, $sp, -24
	sw $ra, 0($sp) #stuff
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)

	#t1 - holds hold (displaySize^2)/(UnitSize^2)(number of words in bmp)
	#t3 - gets info buffer address initially, will be pointer to current address
	#t2 - gets display address will not change
	#t5 - get nullColor
	
	lw $t2, infoAddr #to be incremented
	lw $t3, bmpAddr # = y' * numBytesPerLine + x'
	addi $t2, $t2, 8 
	lw $t5, bgColor  		
	
	#t1 will be number of bytes in a line
	lw $t1, displaySize
	
	#getSize info
	move $t6, $a2 #width
	move $t7, $a3 #height
	
	move $s0, $a0 #s0 gets initial x , will be x'  
	move $s1, $a1 #s1 gets initial y, will be y'
	
	add $t6, $t6, $s0 #t6 now holds x+width
	add $t7, $t7, $s1 #t7 now holds y+height
	
	
	
	
	
	ClearBgDisplayY:

	slt $s3, $s1, $t7
	beq $s3, $zero, ClearBgDisplayYEnd	
	move $s0, $a0 # x' is reset to x
	
	ClearBgDisplayX:
	slt $s3, $s0, $t6
	beq $s3, $zero, ClearBgDisplayXEnd
	
	
	
	
	#t4 will get  initDisplayAddr + (numBytesPerLine * y' + x' * 4)  
	move $t4, $t1
	mult $t4, $s1
	mflo $t4
	
	add $t4, $t4, $s0
	add $t4, $t4, $s0
	add $t4, $t4, $s0
	add $t4, $t4, $s0
	move $t5, $t4 #(numBytesPerLine * y' + x' * 4)  
	add $t4, $t4, $t3
	
	
 	#Get equivalent address in display
	add $t2, $t2, $t5
	lw $s3, 0($t2) #get pixel
	#Restore t2
	sub $t2, $t2, $t5
 
 
	

	#Store
	sw $s3, ($t4)  
	
	
	ClearBgEndStore:  
	  
	#Increment accordingly
	add $s0, $s0, 1	#increment x'
	j ClearBgDisplayX
	
	ClearBgDisplayXEnd:
	add $s1, $s1, 1	#increment y'
	j ClearBgDisplayY
			
	ClearBgDisplayYEnd:


	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp, 24
	
	
	jr $ra

		
#########################################################################################
#LoadFile reads .KLAUS files and puts its bytes into a buffer
#	@param a0  the ascii.z name
LoadFile: 

	addi $sp, $sp, -8
	sw $ra, 0($sp) #stuff
	sw $s6, 4($sp)



#open a file for writing
	li   $v0, 13       # system call for open file
	li   $a1, 0        # Open for reading
	li   $a2, 0
	syscall            # open a file (file descriptor returned in $v0)
	move $s6, $v0      # save the file descriptor
#read from file
	li   $v0, 14       # system call for read from file
	move $a0, $s6      # file descriptor 
	lw   $a1, infoAddr  # address of buffer to which to read
	lw $a2,  infoSize
	syscall            # read from file

# Close the file 
	li   $v0, 16       # system call for close file
	move $a0, $s6      # file descriptor to close
	syscall            # close file
	
	
	lw $ra, 0($sp) #stuff
	lw $s6, 4($sp)
	addi $sp, $sp, 8
			
	
	jr $ra
#################################################################
######## add64 : adds two 64-bit numbers
#### param a0 first number, least significant part
#### param a2 first number, most significant part
#### param a3 second number, least significant part
#### param a4 second number, most significant part
#### return v0 result, least significant part
#### return v1 result, most significant part

add64: addu  $v0, $a0, $a2    # add least significant word
       nor   $t0, $a2, $zero  # ~a2
       sltu  $t0, $a0, $t0    # set carry-in bit (capturing overflow)
       addu  $v1, $t0, $a1    # add in first most significant word
       addu  $v1, $v1, $a3    # add in second most significant word
       jr $ra
#PS: To capture the carry bit in a unsigned sum is equivalent to test if the sum
# can not be contained in a 32 bit register. I.e. if a0 + a2 > 2^32 - 1

#################################################################
######## sub64 : subtracts two 64-bit numbers
#### param a0 first number, least significant part
#### param a2 first number, most significant part
#### param a3 second number, least significant part
#### param a4 second number, most significant part
#### return v0 result, least significant part
#### return v1 result, most significant part

sub64: 
###IF one number equals the other, return 0

	bne $a0, $a2, subNotEquals
	bne $a1, $a3, subNotEquals
	ori $v0, $v0, 0
	ori $v1, $v1, 0
	jr $ra

	subNotEquals:
        nor $a3, $a3, $zero    # ~b1
       nor $a2, $a2, $zero    # ~b0
       
       
       addi $sp, $sp, -4	
       sw $ra, 0($sp) #restore
       jal add64
       lw $ra, 0($sp) #restore
       addi $sp, $sp, 4
        
       # adding 1 to v1v0
       ori $a0, $v0, 0
       ori $a1, $v1, 0
       ori $a2, $zero, 1
       ori $a3, $zero, 0
       
       addi $sp, $sp, -4	
       sw $ra, 0($sp) #restore
       jal add64
       lw $ra, 0($sp) #restore
       addi $sp, $sp, 4
       jr $ra

######################################################
###Here we initialize the game variables, and jump straight into
### the main loop.
  InitGame:
  
  
 #Store initial x positions
  la $t0, posX
  l.s $f1, initPosX_0
  s.s $f1, 0($t0)
  l.s $f1, initPosX_1
  s.s $f1, 4($t0)
  l.s $f1, initPosX_2
  s.s $f1, 8($t0)
  l.s $f1, initPosX_3
  s.s $f1, 12($t0)
  l.s $f1, initPosX_4
  s.s $f1, 16($t0)
  
  #Set ball velocity
  l.s $f1, initBallVelX
  s.s $f1, ballVelX
  l.s $f1, initBallVelY
  s.s $f1, ballVelY


#ALL Y positions of paddles are the same  
  la $t0, posY
  l.s $f1, initPosY 
  s.s $f1, 4($t0)
  s.s $f1, 8($t0)
  s.s $f1, 12($t0) 
  s.s $f1, 16($t0)
# The Y ball pos is 0
sub.s $f1, $f1, $f1
s.s $f1, 0($t0)
  
  
      
#Load BG
  la   $a0, fGameBG 
  jal LoadFile
  li $a0, 0
  li $a1, 0
  jal DrawPNGOnDisplay

#Load Initial scores
  li $a0, 0
  sw $a0, scoreP1
  lw $a1, scoreP1PosX
  li $a2, 0
  jal LoadFontNumber
#Load Initial scores

  li $a0, 0
  sw $a0, scoreP2
  lw $a1, scoreP2PosX
  li $a2, 0
  jal LoadFontNumber
    
  #Update bg
li $a0, 0
li $a1, 0
li $a2, 128
li $a3, 64
jal ClearBgPartial
  
  
  #jal ClearBg

 MainLoop:
 
 	##Store current time
	li $v0,30          #get start timestamp in a0:a1
	syscall 
 	sw $a0, cTime_0
 	sw $a1, cTime_1
 	
 	
 	jal CheckAxisValues
 	jal UpdatePos
 	
 	##Check for ball out of bounds horizontally
 	la $t0, OOBFlags
 	lw $t1, 0($t0)
 	bne $t1, $zero, OutOfBoundsRight
 	lw $t1, 4($t0)
 	bne $t1, $zero, OutOfBoundsLeft
 	j OutOfBoundsEnd
 	OutOfBoundsRight:
 	addi $a0, $zero, 0
 	jal UpdateScore
 	j MainLoop
 	OutOfBoundsLeft:
 	addi $a0, $zero, 1
 	jal UpdateScore
 	j MainLoop
 	OutOfBoundsEnd:
 	
 	jal DealWithCol
 	DealWithColEnd:
 	
 	jal DrawFrame
 	
 	##Restore current time and wait till frame ends
 	lw $a0, cTime_0
 	lw $a1, cTime_1
 	jal WaitLoop
  
j MainLoop   
#####################
Max:
#	@param a0 a value
#	@param a1 another value
#	@return v0 the max
move $v0, $a0
bgt $a0,$a1, MaxEnd
move $v0, $a1
MaxEnd:
jr $ra

#####################
Min:
#	@param a0 a value
#	@param a1 another value
#	@return v0 the max
move $v0, $a0
blt $a0,$a1, MinEnd
move $v0, $a1
MinEnd:
jr $ra



##########################################
UpdateScore: 
#UpdateScore updates the value of the score of
# either side and redraws the screen
#	@param a0 0 iff P1 scored, 1 iff P2 scored  

addi $sp, $sp, -28
sw $ra, 0($sp)
sw $s0, 4($sp)
sw $s1, 8($sp)
sw $s2, 12($sp)
sw $s3, 16($sp)
sw $s4, 20($sp)
sw $s5, 24($sp)

xori $t2, $a0, 1
sll $a0, $a0, 2
sll $t2, $t2, 2
move $s4, $a0
move $s5, $t2

la $t0, scoreP1PosX
la $t1, scoreP1

add $s0, $t0, $s4 #s0 is the address of who scored
add $s1, $t1, $s4 #s1 is addr of old score of who scored

add $s2, $t0, $s5 #s2 is the address of who did not score
add $s3, $t1, $s5 #s3 is addr of score of who did not score

#Update screen on score
#First, draw background
la $a0, fGameBG
jal LoadFile


#increment score
lw $t0, 0($s1)
addi $a0, $t0, 1
sw $a0, 0($s1)

li $t2, 11
lw $t4, 0($s1)#t4 is A
lw $t5, 0($s3)#t5 is B
blt $t4, $t2, NormalSetScore #if who scored has <10 pts, update normally
#If A-B > 1, then game over; If A-B == 1, then A gets adv; If A-B == 0, Deuce
sub $t2, $t4, $t5
addi $t2, $t2, -1
bgtz $t2, GameOverSetScore
beqz $t2, AdvSetScore

DeuceSetScore:
#Load PA Font
li $a0, 11
la $a1, scoreP1PosX
add $a1, $a1, $s4
lw $a1, 0($a1)
li $a2, 0 
jal LoadFontNumber
#Load PB Font
li $a0, 11
la $a1, scoreP1PosX
add $a1, $a1, $s5
lw $a1, 0($a1)
li $a2, 0 
jal LoadFontNumber



j SetScoreEnd
GameOverSetScore:
j Init

AdvSetScore:
#Load PA Font
li $a0, 12
la $a1, scoreP1PosX
add $a1, $a1, $s4
lw $a1, 0($a1)
li $a2, 0 
jal LoadFontNumber
#Load PB Font
li $a0, 13
la $a1, scoreP1PosX
add $a1, $a1, $s5
lw $a1, 0($a1)
li $a2, 0 
jal LoadFontNumber

j SetScoreEnd


NormalSetScore:

#Load P1 Font
lw $a0, scoreP1
lw $a1, scoreP1PosX
li $a2, 0 
jal LoadFontNumber
#Load P2 Font

lw $a0, scoreP2
lw $a1, scoreP2PosX
li $a2, 0 
jal LoadFontNumber


SetScoreEnd:


#Redraw bg

lw $ra, 0($sp)
lw $a0, 0($s0)
li $a1, 0
li $a2, 128
li $a3, 128
jal ClearBgPartial

#Reset ball and paddle stuff

 #Store initial x positions
  la $t0, posX
  l.s $f1, initPosX_0
  s.s $f1, 0($t0)
 
  la $t0, oldPosX
  l.s $f1, initPosX_0
  s.s $f1, 0($t0)
 
  #Set ball velocity
  l.s $f1, initBallVelX
  s.s $f1, ballVelX
  l.s $f1, initBallVelY
  s.s $f1, ballVelY

#ALL Y positions of paddles are the same  
  la $t0, posY
  l.s $f1, initPosY 
  s.s $f1, 4($t0)
  s.s $f1, 8($t0)
  s.s $f1, 12($t0) 
  s.s $f1, 16($t0)
# The Y ball pos is 0
sub.s $f1, $f1, $f1
s.s $f1, 0($t0)

lw $ra, 0($sp)
lw $s0, 4($sp)
lw $s1, 8($sp)
lw $s2, 12($sp)
lw $s3, 16($sp)
lw $s4, 20($sp)
lw $s5, 24($sp)
addi $sp, $sp, 28
jr $ra
###########################################
###########################################
CheckAxisValues:
#CheckAxesValues puts the values of each axis
# and puts them into inputList. 
#TODO: Implement this. 
 #t0 gets memory mapped IO addr
 #t1 gets inputlist addt
 #t2 gets counter var
 
 lw $t0, inputAddr
 la $t1, inputList
 li $t2, 0
 
 CheckAxisValuesForLoop:
 
 lw $t3, 0($t0) #t3 gets axis value
 
 bne $t3, 2, CheckAxisValuesNotNeg
 li $t3, -1
 CheckAxisValuesNotNeg:
 sub $t3, $zero, $t3
 sw $t3, 0($t1) #store in input list
 addi $t2, $t2, 1 #increment counter
 addi $t0, $t0, 4 #increment
 addi $t1, $t1, 4 #increment
 
 blt $t2, 4, CheckAxisValuesForLoop
 CheckAxisValuesForLoopEnd:
 
 jr $ra 

  
###########################################
###########################################
UpdatePos:
#UpdatePos updates the positions of paddles
# and ball for this frame

#Set Out of Bounds flags to 0
la $t0, OOBFlags
li $t1, 0
sw $t1, 0($t0)
sw $t1, 4($t0)
sw $t1, 8($t0)
sw $t1, 12($t0)


lwc1 $f0, frameDuration #delta_t
li $t1, 0 #Counter variable i. 0 <= i < 4
la $t2, posY #holds address to current y pos
la $t7, oldPosY #holds address to current y pos
addi $t2, $t2, 4	
addi $t7, $t7, 4	




la $t3, inputList #holds current input axis to check
UpdatePosPaddleLoop:
	
	#Store posY in oldPosY
	lwc1 $f2, 0($t2)
	swc1 $f2, 0($t7)
	
	#t4 gets current input value
	lw $t4, 0($t3)## posY = posY + vY * delta_t
	
	sub.s $f2, $f2, $f2 #f2 initially gets increment
	beqz $t4, inputCmpEnd
	bgtz $t4, inputGtZ
	bltz $t4, inputLtZ
	 
	inputGtZ:
	lwc1 $f1, paddleVelY
	mul.s $f1, $f1, $f0 #f1 = paddleVely * delta_t
	mov.s $f2, $f1 #f2 = paddleVely * delta_t
	j inputCmpEnd
	inputLtZ:
	lwc1 $f1, paddleVelY
	mul.s $f1, $f1, $f0 #f1 = paddleVely * delta_t
	sub.s $f2, $f2, $f1 #f2 =  - paddleVely * delta_t
	j inputCmpEnd
	inputCmpEnd:

	lwc1 $f5, 0($t2)
	add.s $f2, $f2, $f5	#f2 = (delta_t * paddleVelY) + posY 
	#Now f2 has the new value. Check if in bounds
	cvt.w.s  $f5, $f2            # $f5 <- (int)$f2
				    # $f3 now contains an integer!
	mfc1    $t5 ,$f5            # $t5 <- (int)((delta_t * paddleVelY) + posY)
	
	## OOB cases :#
	lw $t0, roof
	blt $t5, $t0,OOBUp #Out of bounds if less than roog
	lw $t0, floor #t0 will be floor - paddleH
	lw $t6, paddleH #Out of bounds if more than floor
	sub $t0, $t0, $t6
	
	bgt $t5, $t0, OOBDown
	j OOBEnd
	
	OOBUp:
	move $t5, $t0
	mtc1    $t5, $f4 
	cvt.s.w $f2, $f4
	
	j OOBEnd
	
	OOBDown:
	move $t5, $t0 #f2 is greater than allowed
	mtc1    $t5, $f4 
	cvt.s.w $f2, $f4
	j OOBEnd
																							
	OOBEnd:	
	#f2 now has the y pos.Store it 
	swc1 $f2, 0($t2)
																					
	#increment t2 and t3 and t7
	addi $t2, $t2, 4
	addi $t3, $t3, 4		
	addi $t7, $t7, 4
	addi $t1, $t1, 1
	
	lw $t4, numPlayers
	blt $t1, $t4, UpdatePosPaddleLoop
	
	#Print new value
	#mov.s $f12, $f2
	#li $v0, 2
	#syscall
	#la $a0, newLine
	#li $v0, 4
	#syscall
	

UpdatePosPaddleEnd:

#Update ball pos


la $t0, posX 
la $t1, oldPosX 
lwc1 $f1, 0($t0)
swc1 $f1, 0($t1)
lwc1 $f0, frameDuration
lwc1 $f2, ballVelX
mul.s $f2, $f0,$f2
add.s $f1, $f1, $f2
swc1 $f1, 0($t0)


la $t0, posY
la $t1, oldPosY
lwc1 $f1, 0($t0)
swc1 $f1, 0($t1)
lwc1 $f0, frameDuration
lwc1 $f2, ballVelY
mul.s $f2, $f0,$f2
add.s $f1, $f1, $f2
swc1 $f1, 0($t0)

#Now we deal with the case when the ball is
#out of bounds:
la $t0, OOBFlags
li $t1, 1

lwc1  $f1, posX
lwc1 $f2, posY

lw $t2, ballSize

li $t3, 128
sub $t3, $t3, $t2
mtc1 $t3, $f3
cvt.s.w $f3, $f3
c.lt.s $f1, $f3
bc1f ballUpdateOOBRight

ballUpdateOOBLeftCheck:
sub.s $f3, $f3, $f3
c.lt.s $f3, $f1
bc1f ballUpdateOOBLeft

ballUpdateOOBUpCheck:
lw $t3, roof
mtc1 $t3, $f3
cvt.s.w $f3, $f3
c.lt.s $f3, $f2
bc1f ballUpdateOOBUp

ballUpdateOOBDownCheck:
lw $t3, floor
sub $t3, $t3, $t2
mtc1 $t3, $f3
cvt.s.w $f3, $f3
c.lt.s $f3, $f2
bc1t ballUpdateOOBDown
j ballUpdateOOBEnd

ballUpdateOOBRight:
swc1 $f3, posX 
sw $t1, 0($t0)
j ballUpdateOOBLeftCheck
ballUpdateOOBLeft:
swc1 $f3, posX 
sw $t1, 4($t0)
j ballUpdateOOBUpCheck
ballUpdateOOBUp:
swc1 $f3, posY
sw $t1, 8($t0) 
j ballUpdateOOBDownCheck
ballUpdateOOBDown:
sw $t1, 12($t0)
swc1 $f3, posY 


ballUpdateOOBEnd:
 jr $ra   

  

###########################################
###########################################
DrawFrame:
#DrawFrame draws all elements for this frame
#TODO: Implement this
addi $sp, $sp, -20
sw $ra, 0($sp)
sw $s0, 4($sp)
sw $s1, 8($sp)
sw $s2, 12($sp)
sw $s3, 16($sp)

la $s0, posX #s0 holds posX current address
la $s1, oldPosY #s1 holds oldposY current address
la $s2, posY #s2 holds posY current address
andi $s3, 0 #s0 is counter var 
addi $s0, $s0, 4
addi $s1, $s1, 4
addi $s2, $s2, 4


DrawPaddleLoop:


#t0 gets (int) s0
lwc1 $f1, 0($s0)
cvt.w.s $f1, $f1
mfc1 $t0, $f1

#t1 gets (int) s1
lwc1 $f2, 0($s1)
cvt.w.s $f2, $f2
mfc1 $t1, $f2

#t2 gets (int) s2
lwc1 $f2, 0($s2)
cvt.w.s $f2, $f2
mfc1 $t2, $f2

#backup t0, t1, t2
addi $sp, $sp, -16
sw $t0, 0($sp)
sw $t1, 4($sp)
sw $t2, 8($sp)
sw $ra, 12($sp)

##Call ClearBgPartial With:
#a1 - y1 + h if y1 < y0, y0 if y1 > y0
#a3 - |y0 - y1|
move $a0, $t0 #a0 gets x pos
lw $a2, paddleW #a2 gets width

move $a1, $t1 
bgt $t2, $t1, DPLCmpYOldIsMin 
lw $a1, paddleH
add $a1, $a1, $t2
DPLCmpYOldIsMin:
   
sub $t3, $t2, $t1
bgtz $t3, DPLSubIsPositive
sub $t3, $zero, $t3
DPLSubIsPositive:
move $a3, $t3 
jal ClearBgPartial

#restore
lw $t0, 0($sp)
lw $t1, 4($sp)
lw $t2, 8($sp)
lw $ra, 12($sp)
addi $sp, $sp, 16

move $a0, $t0
move $a1, $t2
lw $a2, paddleW
lw $a3, paddleH

jal DrawPaddleOnDisplay#draw paddle

addi $s0, $s0, 4
addi $s1, $s1, 4
addi $s2, $s2, 4
addi $s3, $s3, 1

lw $t0, numPlayers
blt $s3, $t0, DrawPaddleLoop
 


#restore
lw $ra, 0($sp)
lw $s0, 4($sp)
lw $s1, 8($sp)
lw $s2, 12($sp)
lw $s2, 16($sp)
addi $sp, $sp, 20

##NOW WE JUST HAVE TO DRAW THE BALL
##We have to clear two rectangles,
#which are the points of the old ball
#not in the new ball

#-----hslice-----#
addi $sp, $sp, -4
sw $ra, 0($sp)

lwc1 $f1, oldPosX
lwc1 $f2, oldPosY
lwc1 $f3, posY
cvt.w.s $f1, $f1
cvt.w.s $f2, $f2
cvt.w.s $f3, $f3

mfc1 $a0, $f1
lw $a2, ballSize

##Assume yold < ynew
mfc1 $t0, $f2
mfc1 $t1, $f3
sub $a3, $t1, $t0
move $a1, $t0
bgtz $a3, HSliceYOldEnd

HSliceYOldGreater:

mfc1 $a1, $f3
add $a1, $a1, $a2
sub $a3, $zero, $a3


HSliceYOldEnd:
blt $a3,$a2, HSliceHasIntersection
move $a3, $a2
mfc1 $a1, $f2
HSliceHasIntersection:

jal ClearBgPartial
lw $ra, 0($sp)
addi $sp, $sp, 4

#-----vslice-----#
addi $sp, $sp, -4
sw $ra, 0($sp)

lwc1 $f1, oldPosY
lwc1 $f2, oldPosX
lwc1 $f3, posX
cvt.w.s $f1, $f1
cvt.w.s $f2, $f2
cvt.w.s $f3, $f3

mfc1 $a1, $f1
lw $a3, ballSize

##Assume xold < xnew
mfc1 $t0, $f2
mfc1 $t1, $f3
sub $a2, $t1, $t0
move $a0, $t0
bgtz $a2, VSliceXOldEnd

VSliceXOldGreater:

mfc1 $a0, $f3
add $a0, $a0, $a3
sub $a2, $zero, $a2

VSliceXOldEnd:

blt $a2 ,$a3, VSliceHasIntersection
move $a2, $a3
mfc1 $a0, $f2
VSliceHasIntersection:
jal ClearBgPartial

lw $ra, 0($sp)
addi $sp, $sp, 4


addi $sp, $sp, -4
lwc1 $f1, posX
lwc1 $f2, posY
cvt.w.s $f1, $f1
cvt.w.s $f2, $f2
mfc1 $a0, $f1
mfc1 $a1, $f2
lw $a2, ballSize
lw $a3, ballSize
jal DrawPaddleOnDisplay
lw $ra, 0($sp)
addi $sp, $sp, 4
 jr $ra 
    
##############################################
BisectionMethod:
#Calculates the sqrt of c, given that sqrt(c) is in [0, 1]
#	@param a0 c
#	@return v0 sqrt(c)
li $t0, 0
li $t1, 1
mtc1 $t0, $f0 #f0 -> ak
cvt.s.w $f0,$f0
mtc1 $t1, $f1 #f1 -> bk
cvt.s.w $f1, $f1 
mtc1 $a0, $f2 
li $t1, 2
mtc1 $t1, $f3  #f3 = 2
cvt.s.w $f3, $f3

#f4 will be xk

#t0 acts as iteration counter
BisectionLoop:
#get xk
add.s $f4, $f0, $f1
div.s $f4, $f4, $f3

#f5 will be x*x - C
mul.s $f5, $f4, $f4
sub.s $f5, $f5, $f2
sub.s $f6, $f6, $f6
c.le.s $f5, $f6
bc1t BisectionLoopFXKNeg

mov.s $f1, $f4
j BisectionLoopFXKEnd
BisectionLoopFXKNeg:
mov.s $f0, $f4
BisectionLoopFXKEnd:

addi $t0, $t0, 1
#Check conditions
bgt $t0, 10, BisectionEnd
 

j BisectionLoop
BisectionEnd:
mfc1 $v0, $f4
jr $ra
        
###########################################
###########################################
DealWithCol:
#DealWithCol checks for a ball collision
# with the paddles or the roof/floor.

addi $sp, $sp, -8

sw $s0, 0($sp)
sw $ra, 4($sp) 

#If out of bounds vertically, invert Y velocity
la $t0, OOBFlags
lw $t1, 8($t0)
bne $t1, $zero, OOBColInvertY
lw $t1, 12($t0)
bne $t1, $zero, OOBColInvertY
j CheckOOBHor
OOBColInvertY:
lwc1 $f1, ballVelY
sub.s $f2, $f2, $f2
sub.s $f2, $f2, $f1
swc1 $f2, ballVelY

CheckOOBHor:
#If out of bounds horizontally, invert X velocity
la $t0, OOBFlags
lw $t1, 0($t0)
bne $t1, $zero, OOBColInvertX
lw $t1, 4($t0)
bne $t1, $zero, OOBColInvertX
j CheckCollisions
OOBColInvertX:
lwc1 $f1, ballVelX
sub.s $f2, $f2, $f2
sub.s $f2, $f2, $f1
swc1 $f2, ballVelX



CheckCollisions:

li $s0, 1
CheckCollisionWithPaddle:
la $t0, posX
la $t1, posY
lwc1 $f1, 0($t0)
cvt.w.s $f1, $f1
mfc1 $a2, $f1

lwc1 $f1, 0($t1)
cvt.w.s $f1, $f1
mfc1 $a3, $f1

#t3 is offset
move $t3, $s0 
sll $t3, $t3, 2 
add $t0, $t0, $t3
add $t1, $t1, $t3

#read paddle values
lwc1 $f1, 0($t0)
cvt.w.s $f1, $f1
mfc1 $a0, $f1
lwc1 $f1, 0($t1)
cvt.w.s $f1, $f1
mfc1 $a1, $f1

jal BoundingBoxIntersects #Check if it intersects with paddle 
addi $s0, $s0, 1
bnez $v0, DealWithPaddleCol
lw $t6, numPlayers
blt $s0, $t6, CheckCollisionWithPaddle
beq $s0, $t6, CheckCollisionWithPaddle


CheckCollisionWithPaddleEnd:
j DealWithPaddleColEnd

DealWithPaddleCol:
li $v0, 4
la $a0, colDetected
syscall


#Load BallVelY
lwc1 $f1, ballVelY
cvt.w.s $f1, $f1
mfc1 $t6, $f1

li $t0, 2
#set flag if on top AND vy > 0
slt $t1, $v1, $t0
slt $t2, $zero, $t6 
and $t2, $t1, $t2
bnez $t2, DealWithPaddleColOnTop
bnez $t1, DealWithPaddleColOnTopC
 

#set flag if on top AND vy < 0
lw $t0, paddleH
subi $t0, $t0,2
slt $t1, $t0, $v1
slt $t2, $t6, $zero 
and $t2, $t1, $t2
bnez $t2, DealWithPaddleColOnBottom
bnez $t1, DealWithPaddleColOnBottomC


##Usual case:
#Invert X vel 
lwc1 $f1, ballVelX
sub.s $f2, $f2, $f2
sub.s $f2, $f2, $f1
	

swc1 $f2, ballVelX
#Calculate y vel
lw $t1, paddleH
add $t3, $v1, $v1
sub $t3, $t3, $t1
#f4 holds C
#f5 holds new y vel
#f6 holds (float)paddleH
#f7 holds 1 if C = (2x-h)/h > 0, -1 otherwise
#f8 gets |vx|
#f9 is 1-c*c
#calculate $f8
mov.s $f8, $f2
sub.s $f7, $f7, $f7
c.lt.s $f8, $f7
bc1f VxIsPositive
sub.s $f8, $f7, $f8  
VxIsPositive:

#calculate $f6 = paddleH
mtc1 $t1, $f6
cvt.s.w $f6, $f6

#Calculate $f4 = C
mtc1 $t3, $f4
cvt.s.w $f4, $f4
div.s $f4, $f4, $f6

li $t1, 1
bltz $t3, DealWithPaddleColCNeg
DealWithPaddleColCNeg: 
li $t1, -1
DealWithPaddleColCNegEnd:
mtc1 $t1, $f6 
cvt.s.w $f6, $f6 #f6 is multiplier
mul.s $f4, $f4, $f6 #f4 is now positive

mul.s $f5, $f4, $f8
mul.s $f5, $f5, $f6
#f8 will be 1-C*C
li $t1, 1
mtc1 $t1, $f8 
cvt.s.w $f8, $f8 
mul.s $f4, $f4, $f4 #f4 is now C*C
sub.s $f8, $f8, $f4

addi $sp, $sp, -8
sw $ra, 0($sp)
swc1 $f5, 4($sp)
mfc1 $a0,$f8
jal BisectionMethod
lw $ra, 0($sp)
lwc1 $f5, 4($sp)
addi $sp, $sp, 8 
mtc1 $v0, $f8
div.s $f5, $f5, $f8
swc1 $f5, ballVelY




j DealWithPaddleColEnd
DealWithPaddleColOnTop:
lwc1 $f1, ballVelY
sub.s $f2, $f2, $f2
sub.s $f2, $f2, $f1
swc1 $f2, ballVelY
#Set posy to be top of paddle
DealWithPaddleColOnTopC:
la $t1 posY
move $t3, $s0 
addi $t3, $t3, -1
sll $t3, $t3, 2 
add $t1, $t1, $t3
lwc1 $f1, 0($t1) #f1 has top of paddle
lw $t0, ballSize
mtc1 $t0, $f2
cvt.s.w $f2, $f2 #f2 has (float)ballsize
sub.s $f1, $f1, $f2
sub.s $f1, $f1, $f2

la $t1 posY
swc1 $f1, 0($t1)
j DealWithPaddleColEnd

DealWithPaddleColOnBottom:
lwc1 $f1, ballVelY
sub.s $f2, $f2, $f2
sub.s $f2, $f2, $f1
swc1 $f2, ballVelY
#Set posy to be bottom of paddle
DealWithPaddleColOnBottomC:
la $t1, posY
move $t3, $s0 
addi $t3, $t3, -1
sll $t3, $t3, 2 
add $t1, $t1, $t3
lwc1 $f1, 0($t1) #f1 has top of paddle
lw $t0, paddleH
mtc1 $t0, $f2
cvt.s.w $f2, $f2 #f2 has paddle height

add.s $f1, $f1, $f2

la $t1 posY
swc1 $f1, 0($t1)
j DealWithPaddleColEnd
#TODO: Implement this.
DealWithPaddleColEnd:

lw $s0, 0($sp) 
lw $ra, 4($sp)
addi $sp, $sp, 8

 jr $ra   
 
 ##############################################
 BoundingBoxIntersects:
 #BoundingBoxIntesects checks if a paddle intersects
 #with the ball,and returns the y distance of the col center
 #from the top of the paddle
 #	@param a0 the x coordinate of paddle
 #	@param a1 the y coordinate of the paddle
 #	@param a2 tthe x coordinate of the ball
 #	@param a3 the y coordinate of the ball
 #t0 -> low  x coordinate of paddle
 #t1 -> high  x coordinate of paddle
 #t2 -> low  y coordinate of paddle
 #t3 -> high  y coordinate of paddle
 #s0 -> low  x coordinate of ball
 #s1 -> high  x coordinate of ball
 #s2 -> low  y coordinate of ball
 #s3 -> high  y coordinate of ball

  addi $sp, $sp, -16
  sw $s0, 0($sp)
  sw $s1, 4($sp)
  sw $s2, 8($sp)
  sw $s3, 12($sp)
  
 move $t0, $a0 
 lw $t1, paddleW
 add $t1, $t1, $t0
 
 move $t2, $a1
 lw $t3, paddleH
 add $t3, $t3, $t2
 
 move $s0, $a2
 lw $s1, ballSize
 add $s1, $s1, $s0
 
 move $s2, $a3
 lw $s3, ballSize
 add $s3, $s3, $s2
 
 bgt $s0, $t1,BBoxIntersectsFalse
 blt $s1, $t0,BBoxIntersectsFalse
 bgt $s2, $t3,BBoxIntersectsFalse
 blt $s3, $t2,BBoxIntersectsFalse
 li $v0, 1
 #We now know that it intersects
 #The calculation of the intersection y center
 #depends on whether s2 > t2
 
 blt $s2, $t2, BBoxIntersectsOnUpper
 BBoxIntersectsOnLower:
 blt $s3, $t3, BBoxIntersectsFull
 move $v1, $s2
 add $v1, $v1, $t3
 srl $v1, $v1, 1
 j BBoxIntersectsEnd
 
 BBoxIntersectsFull:
 move $v1, $s2
 add $v1, $v1, $s3
 srl $v1, $v1, 1
 j BBoxIntersectsEnd
 
 
 BBoxIntersectsOnUpper:
 move $v1, $t2
 add $v1, $v1, $s3
 srl $v1, $v1, 1
 j BBoxIntersectsEnd
 
 
 
 BBoxIntersectsFalse:
 li $v0, 0
 BBoxIntersectsEnd:
 sub $v1, $v1, $t2
  lw $s0, 0($sp)#restore
  lw $s1, 4($sp)
  lw $s2, 8($sp)
  lw $s3, 12($sp)
  addi $sp, $sp, 16
  jr $ra
 
    
#############################
#WaitLoop waits for frame to end
# @param a0,a1 the initial frame time
WaitLoop:

	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	
	move $s0, $a0
	move $s1, $a1
	
			
	WaitFrame:
		
	li $v0,30          #get start timestamp in a0:a1
	syscall
	
	#Put initial values in a2,a3
	move $a2, $s0
	move $a3, $s1 
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	jal sub64	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	#Now we have subtracted the numbers
	
	
	
	bne  $zero, $v1, WaitFrameEnd
	li $t0, 33
	bgt  $v0, $t0, WaitFrameEnd
	j WaitFrame
	# If we got here, then frame has ended
	##print number and newline as test 
	WaitFrameEnd:
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, frameEnded
	li  $v0, 4
	#syscall
	lw $ra, 0($sp)
	addi $sp, $sp, 4
		
        jr $ra    #RETUUUUURN
          
 End:
