######################################################################
# 			     PONG - INTRO                            #
######################################################################
#           Programmed by 					     #
#	Bruno Klaus de Aquino Afonso             		     #
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

	#Strings of the .KLAUS files
	fTitleScreen: .asciiz "titleScreen.KLAUS"      # title screen 	
	fButton2P: .asciiz "button_2P.KLAUS"
	fButton4P: .asciiz "button_4P.KLAUS"
	fButtonCredits: .asciiz "button_credits.KLAUS"
	fLButtonCredits: .asciiz "lbutton_credits.KLAUS"
	fLButton2P: .asciiz "lbutton_2P.KLAUS"
	fLButton4P: .asciiz "lbutton_4P.KLAUS"
	

.text
Init:

#Load Title Screen Image
la   $a0, fTitleScreen      
jal LoadFile
li $a0, 0
li $a0, 0
jal DrawOnDisplay

#Load Button

la   $a0, fLButton2P      
jal LoadFile
li $a0, 8
li $a1, 37
jal DrawOnDisplay

la   $a0, fButton4P      
jal LoadFile
li $a0, 8
li $a1, 61
jal DrawOnDisplay

la   $a0, fButtonCredits    
jal LoadFile
li $a0, 8
li $a1, 85
jal DrawOnDisplay


j End

###########################################
DrawOnDisplay:
#Moves the latest thing on info buffer to the display.
#	@param a0 the x position
#	@param a1 the y position

	
	sw $ra, 0($sp) #stuff
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	addi $sp, $sp, 20

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
	
	
	
	
	
	WhileDrawOnDisplayY:

	slt $s3, $s1, $t7
	beq $s3, $zero, WhileDrawOnDisplayYEnd	
	move $s0, $a0 # x' is reset to x
	
	WhileDrawOnDisplayX:
	slt $s3, $s0, $t6
	beq $s3, $zero, WhileDrawOnDisplayXEnd
	
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
	j WhileDrawOnDisplayX
	
	WhileDrawOnDisplayXEnd:
	add $s1, $s1, 1	#increment y'
	j WhileDrawOnDisplayY
			
	WhileDrawOnDisplayYEnd:


	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	lw $s4, 20($sp)
	
	
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
