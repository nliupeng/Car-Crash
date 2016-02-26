#
#	Nelly Liu Peng
#	CS 264-02 Computer Organization and Assembly Programming
#	Lab3 
#	03/04/2015
#
#------------------------------------------------------------------------------
# 	DESCRIPTION:  
#		A -- Accelerating
#		B -- Braking (default)
#		C -- Crash
#		S -- Speed (default = 0)
#------------------------------------------------------------------------------

# Useful links:
# https://studentportalen.uu.se/sakaiportal/tool/f75059ad-724b-47d4-b352-6c4aaadc6953?uusp-locale=sv_SE&uusp.userId=guest
# http://inst.eecs.berkeley.edu/~cs61cl/fa08/labs/lab25.html



########################################################
##                      Data area                     ##
########################################################
	.data
	
# Memory mapped I/0, i.e., each I/O device register appears as a
# special memory location. These addresses are too large to use
# as an immediate value so we store them as "constants" in memory.

Rec_Controller: 	.word 	0xFFFF0000

Acceleration:		.asciiz "car acel\n"
Brake:				.asciiz "car brak\n"
carCrash:			.asciiz "car crash\n"
AirbagNo:			.asciiz "Airbag no deploy\n\n"
AirbagYes:			.asciiz "Airbags deployed\n\n"
AmbNo:				.asciiz "Airbags deploy Ambulance no alert\n\n"
AmbYes:				.asciiz "Airbags deploy Ambulance alerted!\n\n"		
NewLine:			.asciiz "\n"		
	
StringBuffer:		.space	3			# 3 bytes used to store user's customized speed
	
	
########################################################
##                     Text area                      ##
########################################################
	.text
main:

# --- Initial default status -----------------------------
	addi	$s1, $0, 0x42				# $s1 = Status. Initial status, B = car on brake
	add		$s6, $0, $0					# $s6 = Speed. Initial speed, 0 mph

# --- Definining characters and their ASCII values -------
	addi	$s2, $0, 0x41				# $s2 = A = 0x41
	addi	$s3, $0, 0x42				# $s3 = B = 0x42
	addi 	$s4, $0, 0x43				# $s4 = C = 0x43
	addi	$s5, $0, 0x53				# $s5 = S = 0x53
	
# --------------------------------------------------------
	lw		$s0, Rec_Controller			# Load receiver controller address
poll:
	lw		$t0, 0($s0)  				# $t0 = receiver controller value
	andi	$t0, $t0, 1					# Isolate ready bit
	beqz	$t0, poll					# Keep polling until ready
	
	lw 		$t1, 4($s0)					# Device ready, get char from receiver data

# --- Checking inputs ------------------------------------
	beq 	$t1, $s2, A_Check
	beq		$t1, $s3, B_Check
	beq 	$t1, $s4, Crash
	beq		$t1, $s5, Speed
	j 		poll						# All other inputs are ignored
	
# --------------------------------------------------------	
A_Check:
	beq		$s1, $s2, no_changeA		# If status is A, no change
	add		$s1, $0, 0x41				# If not, change status $s1 to A
	la		$a0, Acceleration			# $a0 = address of string "car acel"
	jal		printString
no_changeA:
	j		poll						# Go back to polling the keyboard
	
# --------------------------------------------------------	
B_Check:
	beq		$s1, $s3, no_changeB		# If status is B, no change
	add		$s1, $0, 0x42				# If not, change status $s1 to B
	la		$a0, Brake 					# $a0 = address of string "car brak"
	jal		printString
no_changeB:
	j		poll						# Go back to polling the keyboard

# --------------------------------------------------------	
Crash:
	la		$a0, carCrash				# $a0 = address of string "car crash"
	jal		printString
	
	# --- Definining speed limits ------------------------
	addi	$t0, $0, 15					# $t0 = 15 mph
	addi	$t1, $0, 45					# $t1 = 45 mph
		
	ble		$s6, $t0, airbag_noDeploy	# If $s6 = [0-15mph], airbags will not be deployed
	blt		$s6, $t1, airbag_deploy		# If $s6 = (15mph-45mph), airbags will be deployed
	beq		$s1, $s3, noAmbulance		# If $s6 = [45mph+) and status = B, no ambulance alerted
	
yesAmbulance:							# Else, $s6 = [45mph+) and status = A, ambulance alerted
	la		$a0, AmbYes					# $a0 = address of string "Airbags deploy Ambulance alerted!"	
	jal		printString
	j 		poll
	
noAmbulance:
	la		$a0, AmbNo					# $a0 = address of string "Airbags deploy Ambulance no alert"
	jal		printString
	j 		poll
	
airbag_noDeploy:
	la		$a0, AirbagNo				# $a0 = address of string "Airbag no deploy"
	jal 	printString
	j		poll

airbag_deploy:
	la		$a0, AirbagYes				# $a0 = address of string "Airbags deployed"
	jal		printString
	j 		poll

# --------------------------------------------------------	
Speed:
	move	$a0, $s5					# Print char S
	jal		printChar
	la		$t2, StringBuffer			# $t2 = address where input string is to be stored
poll_S:
	lw		$t0, 0($s0)  				# $t0 = receiver controller value
	andi	$t0, $t0, 1					# Isolate ready bit
	beqz	$t0, poll_S					# Keep polling until ready
	
	lw 		$t1, 4($s0)					# Device ready, get char from receiver data
	move	$a0, $t1	
	jal		printChar					# Print char on screen as user types input
	
	beq		$t1, $s5, exit_S			# If char = S, end of input, exit loop	
	sb		$t1, 0($t2)					# Store the char into our buffer
	addi	$t2, $t2, 1					# Give space for next char
	j		poll_S

exit_S:		
	# --- Updating speed ---------------------------------
	la		$a0, StringBuffer			# $a0 = address of stored input string
	jal		translateSpeed	
	move	$s6, $v0					# Update speed $s6
	jal		reset_StringBuffer			# Reset StringBuffer for later use
	
	la		$a0, NewLine				# $a0 = address of string "\n"
	jal 	printString
	
	j		poll
	
# --- Functions ------------------------------------------		
printString:
poll_m:
	lw 		$t0, 8($s0)					# $t0 = transmitter controller value
	andi	$t0, $t0, 1					# Isolate ready bit
	beqz	$t0, poll_m					# Keep polling monitor until ready

	lb		$t2, 0($a0)                 # Monitor ready, load a byte from string
	sb		$t2, 12($s0)				# Display data on monitor
	addi	$a0, $a0, 1					# Get the next byte from the string
	beqz	$t2, exit					# Exit loop when entire string printed
	j 		poll_m
exit:
	jr 		$ra
# --------------------------------------		
printChar:
poll_mc:
	lw 		$t0, 8($s0)					# $t0 = transmitter controller value
	andi	$t0, $t0, 1					# Isolate ready bit
	beqz	$t0, poll_mc				# Keep polling monitor until ready
	
	sw		$a0, 12($s0)				# Monitor ready, display data on monitor
	jr		$ra
# --------------------------------------	
translateSpeed:
	addi 	$t2, $0, 0x30				# $t2 = 0x30, <-- ASCII value of '0'
	addi	$t3, $0, 10					# $t3 = 10, for mult purposes (move number to tenth, hundredth.. place)
	add		$v0, $0, $0					# $v0 = total resulting integer
readChar:
	lb		$t0, 0($a0)					# $t0 = a char of string
	beqz	$t0, endString				# If current char is null, no input at all
	sub		$t0, $t0, $t2				# $t0 = the integer represented by a char (Integer = Ascii - 0x30) 	
	lb		$t1, 1($a0)					# $t1 = a char after $t0
	beqz	$t1, dontMult				# If next char is null, don't multiply current char
	add		$v0, $v0, $t0				# Store integer sum read
	mul		$v0, $t3, $v0  				# Multiply the number $v0 by 10 to increase its nth's place		
	addi	$a0, $a0, 1					# Get next chars of string
	j		readChar
dontMult:
	add		$v0, $v0, $t0				# Add last integer to total resulting integer
endString:
	jr 		$ra
# --------------------------------------		
reset_StringBuffer:
	la		$t0, StringBuffer			# $t0 = address where string is stored
clear:
	sb		$0, 0($t0)					# Store null (Ascii = 0) in buffer	
	lb		$t1, 1($t0)					# Get next byte and check if it's null
	beqz	$t1, exit_R					# If null, buffer space cleared, exit	
	addi	$t0, $t0, 1					# Go to next byte
	j		clear
exit_R:
	jr		$ra
	
	
	