######################################################################
# 			     PONG - INTRO                            #
######################################################################
#           Programmed by 					     #
#	Bruno Klaus de Aquino Afonso             		     #
######################################################################
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
	
	#where the Bitmap display lies
	bmpAddr: .word 0x10010000 
	infoAddr: .word 0x10020000
	
	#These values must be consistent with buffer space
	bmpSize : .word 65536
	infoSize : .word 65536
	displaySize: .word 512
	unitSize: .word 4
	
	
	bgColor: .word 0xFFFFFFFF	#Default BG Color
	
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

.text
Init:

#Load Title Screen Image
la   $a0, fTitleScreen      
jal LoadFile
li $a0, 0
li $a0, 0
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
j TitleProcessInputEnd
TE2_BODY:
j TitleProcessInputEnd
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
#RepaintBg - Redraws BG 
RepaintBg:
#t0 - Will be our index var when going through the bitmap
	#t1 - holds hold (displaySize^2)/(UnitSize^2)(number of words in bmp)
	#t3 - gets bmp address initially, will be pointer to current address
	lw $t3, bmpAddr
	#t4 gets unit length
	lw $t4, unitSize
	#t6 get bgColor
	lw $t6, bgColor  		
	lw $t1, bmpSize
	
	
	
	
	repaintLoop:
	#t2 - Holds 1 if index variable greater than number of words
	slt $t2, $t1, $t0 
	beq $t2, 1, repaintLoopEnd  
	
	
	
	#Store bgColor in current address, increment address
	lw $t6, ($t3) 
	sw $t6, ($t3) 
	
	addi $t3, $t3, 4 #increment address in bitmap
	addi $t0, $t0, 1  #increment counter
	
	 
	j repaintLoop
	
	repaintLoopEnd:	
	jr $ra


##################################################################################
#ClearHg - Cleans backgorund with a background color
ClearBg:

	#t0 - Will be our index var when going through the bitmap
	#t1 - holds hold (displaySize^2)/(UnitSize^2)(number of words in bmp)
	#t3 - gets bmp address initially, will be pointer to current address
	lw $t3, bmpAddr
	#t4 gets unit length
	lw $t4, unitSize
	#t6 get bgColor
	lw $t6, bgColor
  		
	lw $t1, displaySize
	
	ori $t0, $zero, 0 
	mult $t1, $t1
	mflo $t1
	
	div $t1, $t4 
	mflo $t1
	div $t1, $t4 
	mflo $t1
	
	
	
	clearLoop:
	#t2 - Holds 1 if index variable greater than number of words
	slt $t2, $t1, $t0 
	beq $t2, 1, clearLoopEnd  
	
	
	
	#Store bgColor in current address, increment address
	sw $t6, ($t3) 
	
	addi $t3, $t3, 4 #increment address in bitmap
	addi $t0, $t0, 1  #increment counter
	
	 
	j clearLoop
	
	clearLoopEnd:	
	jr $ra		
#########################################################################################
#LoadFile reads .KLAUS files and puts its bytes into a buffer
#	@param a0  the ascii.z name
LoadFile : 




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
	
	

	addi $a0, $zero, 0
	addi $a1, $zero, 0
	
	jr $ra

 
 End:
