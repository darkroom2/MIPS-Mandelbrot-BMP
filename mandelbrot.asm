# https://docs.microsoft.com/en-us/windows/desktop/gdi/bitmap-storage BMP
# https://docs.microsoft.com/en-us/windows/desktop/winprog/windows-data-types wielkosci WORD itp.

# DWORD 32bit, WORD 16bit, LONG 32bit

# typedef struct tagBITMAPFILEHEADER {
# 0  WORD  bfType;	2bajty, The file type; must be BM.
# 2  DWORD bfSize;	4bajty, The size, in bytes, of the bitmap file.
# 6  WORD  bfReserved1;	2bajty, Reserved; must be zero.
# 8  WORD  bfReserved2;	2bajty, Reserved; must be zero.
# 10 DWORD bfOffBits;	4bajty, The offset, in bytes, from the beginning of the BITMAPFILEHEADER structure to the bitmap bits.
# }

# typedef struct tagBITMAPINFOHEADER {
# 14 DWORD biSize;	4bajty,
# 18 LONG  biWidth;	4bajty,
# 22 LONG  biHeight;	4bajty,
# 26 WORD  biPlanes;	2bajty,
# 28 WORD  biBitCount;	2bajty,
# 30 DWORD biCompression;	4bajty,
# 34 DWORD biSizeImage;	4bajty,
# 38 LONG  biXPelsPerMeter;	4bajty,
# 42 LONG  biYPelsPerMeter;	4bajty,
# 46 DWORD biClrUsed;	4bajty,
# 52 DWORD biClrImportant;	4bajty,
# }

.eqv iXmax $t0
.eqv iX $t1
.eqv iYmax $t2
.eqv iY $t3
.eqv pixelWidth $t4
.eqv pixelHeight $t5
.eqv iterationMax $t6
.eqv ER2 $t7
.data

.align 2
.space 2
header: .space 54
fileSize: .word 1
width: .word 1
height: .word 1
pixelCount: .word 1
pixelArray: .word 1
outputFileBegin: .word 1
padding: .word 1
bytesInLine: .word 1
CxMin: .word 1
CyMin: .word 1
inputFile: .asciiz "in.bmp"
outputFile: .asciiz "out.bmp"

.text

.macro printInt(%x)
	li $v0, 1
	addu $a0, %x, $zero
	syscall
	printStr("\n")
.end_macro
.macro printStr (%str)
	.data
str:	.asciiz %str
	.text
	li $v0, 4
	la $a0, str
	syscall
.end_macro

.globl main

main:
	li $v0, 13	# otwarcie pliku
	la $a0, inputFile # o podanej sciezce
	li $a1, 0
	li $a2, 0
	syscall
	move $s6, $v0	# deskryptor w s6
	
	#pobieramy header aby go pozniej zapisac do pliku out.bmp:
	li $v0, 14	# czytanie z pliku
	move $a0, $s6	# ktory "jest tu" (deskryptor)
	la $a1, header	# tu zapisujemy header
	li $a2, 54	# ktory ma 54 bajty
	syscall
	
	li $v0, 16	# zamykamy plik, mamy juz wszystkie informacje o nim
	move $a0, $s6	# zamykamy go, aby pozniej przy otwarciu, wskaznik pliku byl na jego poczatku
	syscall
	
	#porzadkujemy przydatne info (patrz struct na gorze)
	lw $t0, header+2 # ladujemy 4bajty (mips word 32bit) rozmiaru (DWORD bfSize)
	sw $t0, fileSize # i zapisujemy do fileSize

	lw $t1, header+18 # szerokosc
	sw $t1, width

	lw $t2, header+22 # wysokosc
	sw $t2, height
	
	mul $t1, $t1, $t2 # liczymy ilosc pixeli na obrazku
	sw $t1, pixelCount
	# test
	# b test
	#majac adres headera i adres poczateku pixeli mozemy przepisac te rzeczy do nowego pliku
	li $v0, 9	# alokujemy pamiec na out.bmp
	lw $a0, fileSize # tyle ile in.bmp
	syscall
	sw $v0, outputFileBegin # zapisujemy adres poczatku zaalokowanej pamieci, aby pozniej przepisac ja do out.bmp
	
	#otwieramy plik aby przepisac jego cala zawartosc do zaalokowanej pamieci
	li $v0, 13
	la $a0, inputFile
	li $a1, 0
	li $a2, 0
	syscall
	move $s6, $v0	# deskryptor w s6
	
	li $v0, 14	# czytamy plik
	move $a0, $s6
	lw $a1, outputFileBegin # pod tym adresem
	lw $a2, fileSize # czytamy i zapisujemy caly plik
	syscall
	
	li $v0, 16	# ostatecznie zamykamy plik in.bmp
	move $a0, $s6
	syscall
	
	#obliczamy poczatek tablicy pixeli
	lw $t0, outputFileBegin
	addu $t0, $t0, 54
	sw $t0, pixelArray
	
	#padding, mamy 4bajty na pixel, wiersz musi sie konczyc na wyrownanym do 4 adresie
	lw $t0, width

	andi $t1, $t0, 0x3 # sprytne source: http://home.elka.pw.edu.pl/~sniespod/index.php?l=arko
	sw $t1, padding

	mulu $t0, $t0, 3 # liczba bajtow w wierszu
	addu $t0, $t0, $t1 # + padding, aby uzyskac wielokrotnosc 4 (musi byc wielokrotnosc 4)
	sw $t0, bytesInLine
	
############################################
# tutaj algo mandelbrota
# https://pastebin.com/kiU52tgY
############################################	
# Mamy do dyspozycji WSZYSTKIE rejestry:
# 
# test:
	lw iXmax, height
	li iX, 0
	sll iX, iX, 16
	lw iYmax, width
	li iY, 0
	sll iY, iY, 16

	li $t4, 5 #000000101
	sll $t4, $t4, 15 # 000010.100000  # 2.5
	neg $t4, $t4
	sw $t4, CxMin # CxMin = -2.5
	
	li $t4, 2 #000000010
	sll $t4, $t4, 16 # 000010.000000  # 2.0
	neg $t4, $t4
	sw $t4, CyMin # CyMin = -2.0

	# pixelWidth = (1.5 - (-2.5)) / iXmax; 4 / iXmax
	li $t4, 4	# 00000100
	sll $t4, $t4, 16 # 000100.0000000
	divu pixelHeight, $t4, iYmax # pHeight = 4 / iYmax
	divu pixelWidth, $t4, iXmax # pWidth = 4 / iXmax
	#pixelHeight - $t5
	#pixelWidth - $t4
	li iterationMax, 200 # $t6
	
	li $t7, 4	# 00000100
	sll $t7, $t7, 16 # 000100.0000000 (4.0)
	
	# ER2 - $t7
	

	
	lw $t8, pixelArray
	li $s4, 111
loop1:
	# Cy = CyMin + iY * PixelHeight;
	mulu $s1, iY, pixelHeight
	mfhi $s2
	srl $s1, $s1, 16
	sll $s2, $s2, 16
	or $s1, $s1, $s2 
	lw $s2, CyMin
	addu $s1, $s1, $s2
	# Cy - $s1
	
	abs $s0, $s0
	srl $s1, pixelHeight, 1
	blt $s0, $s1, loop2
	li $s0, 0


loop2:
	# do stuff
	# Cx = CxMin + iX * PixelWidth;
	mulu $s0, iX, pixelWidth
	mfhi $s1
	srl $s0, $s0, 16
	sll $s1, $s1, 16
	or $s0, $s0, $s1
	lw $s1, CxMin
	addu $s0, $s0, $s1
	# Cx - $s0
	li $v0, 0	# Zx
	li $v1, 0	# Zy
	# mulu $a0, $v0, $v0 # a0 Zx2
	# mulu $a1, $v1, $v1 # a1 Zy2
	
	li $t9, 0 # iteration = 0

	loop3:
		addu $a3, $a0, $a1 #Zx2 + Zy2
		beq $t9, iterationMax, endLoop3
		bge $a3, ER2, lessIters
		# inside loop
		
		# Zy = 2 * Zx*Zy + Cy;
		mulu $v1, $v0, $v1
		mfhi $s3
		srl $v1, $v1, 16
		sll $s3, $s3, 16
		or $v1, $v1, $s3 # Zy = Zx * Zy
		sra $v1, $v1, 1 # Zy = 2 * Zx * Zy
		addu $v1, $v1, $s0 # Zy = 2 * Zx*Zy + Cy;
		
		# Zx = Zx2 - Zy2 + Cx;
		addu $v0, $s0, $a0 # Zx = Cx + Zx2
		subu $v0, $v0, $a1 # Zx = Zx - Zy2
		
		mulu $a0, $v0, $v0 # Zx2 = Zx * Zx
		mfhi $s3
		srl $a0, $a0, 16
		sll $s3, $s3, 16
		or $a0, $a0, $s3 # Zx2 = Zx*Zx
		
		mulu $a1, $v1, $v1 # Zy2 = Zy * Zy
		mfhi $s3
		srl $a1, $a1, 16
		sll $s3, $s3, 16
		or $a1, $a1, $s3 # Zy2 = Zy*Zy
		
		addiu $t9, $t9, 1
		b loop3
	endLoop3:
		sb $s4, ($t8)
		sb $s4, 1($t8)
		sb $s4, 2($t8)
	lessIters:
		addiu $t8, $t8, 3
		
	addiu iX, iX, 1
	blt iX, iXmax, loop2
		
	li iX, 0
	addiu iY, iY, 1
	blt iY, iYmax, loop1

# 
############################### Koniec
# 

	#zapisujemy zaalokowany wczesniej plik
	li $v0, 13	# otwieramy plik
	la $a0, outputFile # output.bmp
	li $a1, 1
	li $a2, 0
	syscall
	move $s6, $v0	# deskryptor w s6
	
	#zapisz do plik
	li $v0, 15
 	move $a0, $s6      # file descriptor 
 	lw $a1, outputFileBegin
 	lw $a2, fileSize
 	syscall
 	
 	#zamkniecie tego pliku
	li $v0, 16	# ostatecznie zamykamy plik out.bmp
	move $a0, $s6
	syscall
end:
	li $v0, 10
	syscall
