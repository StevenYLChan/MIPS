#---------------------------------------------------------------
# The main program performs endianness conversion. The program reads an integer
# from the terminal, inverts the byte order of that integer, and then prints out
# the new big-endian integer using the print_int system call.
#
# Register Usage:
#
#       a0: contains the number to be performed on
#      
#
#---------------------------------------------------------------
.data
prompt:                    #string display message
	.asciiz "Enter an integer: "
mask:
        .word 0xFF         #11111111 mask

.text
main:
    
#print the prompt dialog
	la $a0,prompt      #load prompt 
        li $v0,4           #output prompt 

	syscall            #make the call

#reads integer and saves in t0
	li $v0 5           #read integer
	syscall            #make the call
	move $t0,$v0       #move integer into $t0

#----------------------------------------------------------------------
# Grabs a 32-bit number and inverts the bytes
#
#
# Inputs:
#          a0    number to be inverted
#          ra    return address
#
#
# Register Usage
#
#       t0: integer input
#       t1: mask used, which was previously defined as 11111111
#       t2: resulting register from 'and' usage of 2 registers
#       t3: register used for all inverted bytes
#
#----------------------------------------------------------------------

#get index 3 byte and put as index 0                                   
        lw $t1, mask       #create mask
        and $t2,$t0,$t1    #get least significant byte
        add $t3,$t2,$zero  #move the 8 bits into a new register
        sll $t3,$t3,24     #shift the 8 bits from being LSBs to MSBs

#get index 2 byte and put as index 1
        sll $t1,$t1,8      #shift 8 bits over for next mask
        and $t2,$t0,$t1    #get next byte
        sll $t2,$t2,8      #shift 8 bits left to swap positions
        or $t3,$t3,$t2     #or to preserve first byte stored

#get index 1 and put as index 2
        sll $t1,$t1,8      #shift 8 bits over for next mask
        and $t2,$t0,$t1    #get next byte
        srl $t2,$t2,8      #shift 8 bits right to swap positions
        or $t3,$t3,$t2     #or to preserve previous bytes stored

#get index 0 and put as index 3
        sll $t1,$t1,8      #shift 8 bits over for next mask
        and $t2,$t0,$t1    #get next byte
        srl $t2,$t2,24     #shift 24 bits right to swap positions
        or $t3,$t3,$t2     #or to preserve previous bytes stored

#prints the integer
        move $a0 $t3       #move $t3 into $a0
	li $v0 1           #print out number using system call print_int
	syscall            #make the call
	
	jr $ra

