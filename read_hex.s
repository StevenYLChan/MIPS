#---------------------------------------------------------------
# readHex makes sure input is 8 bits long then checks if it is a valid hex char.
# Checks each of the 3 cases and returns invalid if violates.
#
# Inputs:
#       a0: contains the memory address of the first character of a string of 8 ASCII #characters. This string contains the ASCII hexadecimal representation of an unsigned #integer
#       ra:    return address
# Register Usage:
#       v1: returned result tells if valid or not. returns 1 if invalid hex. returns 0# if valid hex
#       t0: store a0 for usage
#       t1: checks and measures
#       t2: checks and measures
#       t3: resultant storage
#       t4: for looping
#       t5: mask 0xff
#
#
#
#---------------------------------------------------------------

.data
mask:
        .word 0xFF                             #11111111 mask
oxStr2:		.asciiz "0x"
.text

readHex:
    addi $t3,$zero, 0                          #set 0
    lb $t0, 0($a0)                             #load into t0
                                               #'0' < $t0 < '9'
                                               #'a' < $t0 < 'f'
                                               #'A' < $t0 < 'F'
                                               #if valid then sll
    move $t4,$zero                             #set 0
    lw $t5,mask                                #load mask into t5
    j countloopfirst                           #go to countloopfirst

countloopfirst:
    addi $t4,$t4,1                             #increment loop
    j byteloop                                 #go to byteloop
countloop:   
    bge $t4, 8, finished                       #loop certain amount of times
    sll $t3,$t3,4                              #shift to get bits
    addi $t4,$t4,1                             #increment loop
    addi $a0,$a0,1                             #grab next char
    j byteloop                                 #go to byteloop
    
byteloop:
    lb $t0, 0($a0)                             #grab char and put into t0
                                               #check if between 0-9
    li $t1,0x30                                #bounded by range
    li $t2, 0x39                               #bounded by range
    and $t1,$t1,$t5                            #see if in range
    and $t2,$t2,$t5                            #see if in range
    blt $t0,$t1,testFail                       #if less than 0x30 then already not hex
    bgt $t0,$t2,testB                          #if greater than 0x39, test for next cases
                                               #will reach next line only if between 48 and 55. If outside of this would
                                               #have jumped already / branched off

    addi $t0,$t0,-0x30                         #is hex so subtract 0x30 (48 dec) since 0-9 is
                                               #48 to 57 and anything from 0 to 9 minus 48
                                               #will turn it from '0'-'9' ascii to dec rep
    or $t3,$t3,$t0                             #or so don't overwrite
    j countloop                                #jump
    
testB:
                                               #check if between A-F
    li $t1, 0x41
    li $t2, 0x46
    and $t1,$t1,$t5                            #bounded by range
    and $t2,$t2,$t5                            #bounded by range
    blt $t0,$t1,testFail                       #invalid
    bgt $t0,$t2,testC                          #if greater then check a-f
    addi $t0,$t0,-0x37                         #subtract 55 to get 10-15, which represents a-f
    or $t3,$t3,$t0                 
    j countloop    

testC:
                                               #check if between a-f
    li $t1, 0x61
    li $t2, 0x66
    and $t1,$t1,$t5                            #bounded by range
    and $t2,$t2,$t5                            #bounded by range
    blt $t0,$t1,testFail                       #invalid
    bgt $t0,$t2,testFail                       #invalid. 0x66 is max for valid hex

    addi $t0,$t0,-0x57                         #subtract 87 to get 10-15, which represents A-F
    or $t3,$t3,$t0                 
    j countloop
  
                                               #invalid hex
testFail:
    addi $v1,$v1,1
    jr $ra
                                               #proper hex
finished:
    move $v1,$zero
    move $v0,$t3
    jr $ra


#---------------------------------------------------------------
# createCountTable creates a table for use with countIntegerAccess
#
# Inputs:
#       ra:    return address
#---------------------------------------------------------------
.data
    values: .space 800                        #200*4
    counter: .space 200
    .align 2                                  #to start at an exact boundary
.text
createCountTable:
    jr $ra                                    #just return


#---------------------------------------------------------------
# printHex prints the hexadecimal representation, including the leading 0x, of the int#eger value using lowercase letters for the hexadecimal code.
#
# Inputs:
#       a0: contains an unsigned integer value
#       ra:    return address
# Register Usage:
#       v0: usage for syscall to print
#       t0: char to convert
#       t1: determinator
#       t2: mask2
#       t3: resultant
#---------------------------------------------------------------

.data
    mask2: .word 0xf0000000                   #proceeding 0's to make sure is in left most bit
.text

printHex:
    move $t0, $a0                             #move a0 into t0 to keep value
    la $a0, oxStr2                            #print '0x'
    li $v0, 4                     
    syscall

hexloop:
   li $t1, 0x3A                               #if less than this then is number
   lw $t2, mask2                              #mask2 from .data into t2

   doshift:
        beq $t0,$zero,completed               #if all equal to zero then complete
        and $t3, $t2,$t0                      #grab bits using t0 and mask
        sll $t0,$t0,4                         #next 4
        srl $t3,$t3,28                        #put it in the right place
        addi $t3,$t3,0x30                     #add back to get 0-9
        blt $t3,$t1,done                      #see if 0-9 or a-f
        addi $t3,$t3,0x27                     #add again to get a-f range
        b done

    done:
        move $a0,$t3                          #move into a0 for print
        li $v0,11                             #print
        syscall
        b doshift                             #go back for next
completed:
    j $ra

#---------------------------------------------------------------
# countIntegerAccess counts number of times integer has been accessed
#
# Inputs:
#       a0: contains an arbitrary integer value
#       ra:    return address
# Register Usage:
#       v0: the number of times the particular value passed as argument has been acces#sed
#       t0: input
#       t2: checker to see if found
#       t5: temp counter
#       t9: loop
#       s0: pointer to values[0]
#       s1: grabs value at values[0]
#       s2: pointer to counter[0]
#       s3: grabs value at counter[0]
#       s7: saved total counter
#---------------------------------------------------------------
countIntegerAccess:
                                              #t9 = loop
                                              #loop
    move $t9,$zero
    move $t5,$zero                            #temp counter
    add $s7,$s7,$t5                           #retain so add temp to overall counter
    move $t0,$a0                              #put into t0

looper:
   
    la $s0, values                           #set pointer to values[0]
    lb $s1,0($s0)                            #get number at values[0]
    la $s2, counter                          #set pointer to counter[0]
    lb $s3,0($s2)                            #get counter at counter[0]

    li $t2, 0                                #if found

search:
    beq $t9,200,write                        #if go over every single element and does                                             #not branch then doesn't exist so write
    seq $t2,$s3,$t0                          #comparison if t0 = element in array 
    bgtz $t2,quit                            #if found then t2 will equal 1
    b resume        
resume:
    addi $s2,$s2,4                           #not found. go to next number
    addi $t9,$t9,1                           #increase loop counter
    b search                                 #loop back
 
write:
    sb $t0,0($s2)                            #store the new int
    move $v0,$zero                           #does not exist so return 0
    jr $ra
quit:
    addi $s7,$s7,1                           #increase overall counter by 1
    move $v0,$s7                             #move into v0 to return
    jr $ra
