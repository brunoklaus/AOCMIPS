.data
myFloat: .float  1.000

.text
lwc1  $f1, myFloat
mfc1 $a0, $f1
jal BisectionMethod

mtc1 $v0, $f12
li $v0, 2
syscall

j End
BisectionMethod:
#Calculates the sqrt of x, given that sqrt(c) is in [0, 1]
#	@param a0 c
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

End: