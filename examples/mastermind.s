# -----------------------------------
# 2024-11-11 Soobin Rho | Annotation
# -----------------------------------
# The operation of MasterMind
# What makes it go?
# -----------------------------------
# In this file, I've replaced all the original comments, and replaced
# them with my own comments, as instructed.
#
# Basically, this code starts with `.eqv` directives that tell the assembler
# that a certain constant variable is a certain integer -- e.g. `DIGIT_MAX` is 8.
# The macros are then defined for printing stuff. It's notable that throughout this
# code, the program makes use of functions a lot whenever it's beneficial to do so.
# The use of macro here by the author, I believe, suggests there are certain things
# that are better done by macros than functions, such as printing a string or a newline.
#
# The main text part of the code contains the instructions to initialize the data structures
# required; generate the secret code using the random integer system call; check and validate
# the user's input for a guess; check how many of the digits are correct and how many of the digits are
# the right digits but in an incorrect position; and exit the program if the answer is found.

.eqv    NUMBER_DIGITS, 4
.eqv    DIGIT_MAX, 8

.macro printStr (%str) 		
        .data
myLabel:
        .asciz %str
        .text
        li a7, 4
        la a0, myLabel
        ecall
.end_macro

.macro printLn 				
         .data
CRstring:
        .string "\n"
        .text
        li a7, 4
        la a0, CRstring
        ecall
.end_macro

.data

SecretCode: .word 0,0
CopyCode:   .word 0,0
userNumber: .word 0,0

secretString: .string "solu\n"

.text
.globl _start

# 1. Initialize the required data structures.
_start:
        jal ra, generateCode
        
# 2. Check the user's guess.
user:
        printStr("Please enter your guess: ")
        la a0, userNumber
        li a1, 10
        li a7, 8                 	
        ecall                         

        la a0, userNumber				
        la a1, secretString		
        jal ra, strcmp
        bnez a0, noSecretString
        jal ra, printSol				
        j user					       

# 3. Validate the user input.
noSecretString:
        la a0, userNumber
        jal ra, strlen					
        addi a0, a0, -5					
        bnez a0, userError		

        li t2, '\n'						
        li t3, DIGIT_MAX				
        la t0, userNumber
nextDigit:
        lb t1, 0(t0)					
        beq t1, t2, afterCheck			
        addi t1, t1, -48				
        sb t1, 0(t0)					
        addi t0, t0, 1					
        bltz t1, userError				
        bge t1, t3, userError				
        j nextDigit					

afterCheck:
        la a6, SecretCode
        la a0, CopyCode
        lw t0, 0(a6)					
        sw t0, 0(a0)					
        
        la a1, userNumber				
        li s11, 0						
        li t1, -1					
        li t2, -2						
        li t3, 4						
# 4. Check how many digits are correct.
loopCorrectMatches:
        lb t4, 0(a0)					
        lb t5, 0(a1)					
        bne t4, t5, noMatch	
        addi s11, s11, 1				
        sb t1, 0(a0)					
        sb t2, 0(a1)					
noMatch:
        addi a0, a0, 1					
        addi a1, a1, 1
        addi t3, t3, -1					
        bnez t3, loopCorrectMatches
        
        printStr("Number of correct matches: ")
        mv a0, s11
        li a7, 1						
        ecall							
        printLn  						
        addi s11, s11, -4			
        beqz s11, userWin			

        li s11, 0						
        li t1, -1						
        li t2, -2					
        la a0, CopyCode					
        li s0, 4						

# 5. Check how many digits are correct digits but in wrong positions.
outerLoop:
        la a1, userNumber				
        li s1, 4						
innerLoop:
        beq s0, s1, noMatch2				
        lb t4, 0(a0)
        lb t5, 0(a1)
        bne t4, t5, noMatch2
        	
        addi s11, s11, 1
        sb t1, 0(a0)
        sb t2, 0(a1)
noMatch2:
        addi a1, a1, 1					
        addi s1, s1, -1				
        bnez s1, innerLoop

        addi a0, a0, 1					
        addi s0, s0, -1				
        bnez s0, outerLoop
        
        printStr("Number of incorrect positions: ")
        mv a0, s11
        li a7, 1						
        ecall							
        printLn   					
        j user							

userError:
        printStr("Guess should be 4 digits, each between 0 and 7\n")
        j user							

# 6. Exit if the answer is found.
userWin:
        printStr("Congratulations!\n")
        li a7, 10                 		
        ecall                           

# 7. Helper functions.
generateCode:
        la t0, SecretCode               
        li t1, NUMBER_DIGITS            
loop:
        li a0, 0
        li a1, DIGIT_MAX                
        li a7, 42                       
        ecall                           
        sb a0, 0(t0)                   
        addi t0, t0, 1                  
        addi t1, t1, -1                 
        bnez t1, loop                  
        ret

printSol:
        la t0, SecretCode               
        li t1, NUMBER_DIGITS            
loopSol:
        lb a0, 0(t0)                    
        li a7, 1                        
        ecall                           
        addi t0, t0, 1                  
        addi t1, t1, -1                 
        bnez t1, loopSol                
        printLn
        ret

strlen:
        li t1, -1                       
loopStrlen:
        lbu t0, 0(a0)                   
        addi a0, a0, 1                  
        addi t1, t1, 1                  
        bnez t0, loopStrlen             
        mv a0, t1                       
        ret

strcpy:
        lb t0, 0(a0)                    
        sb t0, 0(a1)                    
        addi a0, a0, 1                 
        addi a1, a1, 1                  
        bnez t0, strcpy                 
        ret                             

strcmp:
        lbu t0, 0(a0)                   
        lbu t1, 0(a1)                   
        sub t1, t0, t1                 
        addi a0, a0, 1                  
        addi a1, a1, 1                 
        beqz t0, endStrcmp             
        beqz t1, strcmp                
endStrcmp:                            
        mv      a0, t1                  
        ret
