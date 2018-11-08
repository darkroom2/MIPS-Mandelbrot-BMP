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

.eqv	iXmax	$t0
.eqv	iX	$t1
.eqv	iYmax	$t2
.eqv	iY	$t3
.eqv	Cy	$t4
.eqv	Cx	$t5
.eqv	Zx	$t6
.eqv	Zy	$t7
.eqv	Zx2	$t8
.eqv	Zy2	$t9

	.data

		.align 2	# wyrownanie do 4 bajtow
		.space 2	# aby wyrownac 54 bajtow
header:		.space 54	# do 56 ktore jest podzielne przez 4
fileSize:	.word 1
width:		.word 1		# word = 4 bajty
height:		.word 1
pixelArray:	.word 1
outputFileBegin:.word 1
padding:	.word 1
CxMin:		.word 1
CyMin:		.word 1
pixelWidth:	.word 1
pixelHeight:	.word 1

inputFile:	.asciiz "in.bmp"
outputFile:	.asciiz "out.bmp"

	.text

.macro printInt(%x, %str)
	li $v0, 1
	addu $a0, %x, $zero
	syscall
	printStr(%str)
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
	
	# pobieramy header aby go pozniej zapisac do pliku out.bmp:
	li $v0, 14	# czytanie z pliku
	move $a0, $s6	# ktory "jest tu" (deskryptor)
	la $a1, header	# tu zapisujemy header
	li $a2, 54	# ktory ma 54 bajty
	syscall
	
	li $v0, 16	# zamykamy plik, mamy juz wszystkie informacje o nim
	move $a0, $s6	# zamykamy go, aby pozniej przy otwarciu, wskaznik pliku byl na jego poczatku
	syscall
	
	# porzadkujemy przydatne info (patrz struct na gorze)
	lw $t0, header+2 # ladujemy 4bajty (mips word 32bit) rozmiaru (DWORD bfSize)
	sw $t0, fileSize # i zapisujemy do fileSize

	lw $t1, header+18 # szerokosc
	sw $t1, width

	lw $t2, header+22 # wysokosc
	sw $t2, height
	
	# majac adres headera i adres poczateku pixeli mozemy przepisac te rzeczy do nowego pliku
	li $v0, 9	# alokujemy pamiec na out.bmp
	lw $a0, fileSize # tyle ile in.bmp
	syscall
	sw $v0, outputFileBegin # zapisujemy adres poczatku zaalokowanej pamieci, aby pozniej przepisac ja do out.bmp
	
	# otwieramy plik aby przepisac jego cala zawartosc do zaalokowanej pamieci
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
	
	# obliczamy poczatek tablicy pixeli
	lw $t0, outputFileBegin
	addu $t0, $t0, 54
	sw $t0, pixelArray
	
	# padding, mamy 4bajty na pixel, wiersz musi sie konczyc na wyrownanym do 4 adresie
	lw $t0, width

	andi $t1, $t0, 0x3 # sprytne source: http://home.elka.pw.edu.pl/~sniespod/index.php?l=arko
	sw $t1, padding
	
############################################
# Glowny algorytm:
# 
	lw iXmax, width	# t0 iXmax
	li iX, 0	# t1 iX
	
	lw iYmax, height # t2 iYmax
	li iY, 0	# t3 iY
	
	printStr("Program rysujacy zbior Mandelbrota.\nPodaj przedzialy ukladu wspolrzednych rzeczywistych (podwojone, np. -3 -> -1.5, by uzyskac dokladnosc do 0.5).\nCxMin: ")
	
	li $v0, 5	# laduj CxMin
	syscall
	sll $v0, $v0, 24 # konwersja i podzial na 2
	sw $v0, CxMin
	
	move $t4, $v0 # t4 - CxMin

	printStr("CxMax: ")
	li $v0, 5	# laduj CxMax
	syscall
	sll $v0, $v0, 24 # konwersja i podzial na 2
	move $t5, $v0
	
	sub $t4, $t5, $t4 # CxMax - CxMin
	div $t4, $t4, iXmax
	sw $t4, pixelWidth # pWidth = CxMax - CxMin / iXmax
	
	printStr("CyMin: ")
	li $v0, 5	# laduj CyMin
	syscall
	sll $v0, $v0, 24 # konwersja i podzial na 2
	sw $v0, CyMin
	
	move $t4, $v0 # t4 - CyMin

	printStr("CyMax: ")
	li $v0, 5	# laduj CyMax
	syscall
	sll $v0, $v0, 24 # konwersja i podzial na 2
	move $t5, $v0
	
	printStr("\nCzekaj...\n")
	
	subu $t4, $t5, $t4 # CyMax - CyMin
	divu $t4, $t4, iYmax
	sw $t4, pixelHeight # pHeight = CyMax - CxMin / iYmax
	
	li $s6, 0	# current ireration
	li $s7, 50	# iterationMax
	lw $a3, padding
	lw $s0, pixelArray
	li $s1, 255	# kolor
loop1:
	# Cy = CyMin + iY * PixelHeight;
	lw $a0, pixelHeight
	mulu Cy, $a0, iY # iY * pH
	lw $a0, CyMin
	addu Cy, Cy, $a0 # t4 Cy

	# if (fabs(Cy) < PixelHeight / 2) Cy = 0.0;
	lw $a0, pixelHeight
	srl $a0, $a0, 1 # pH/2
	abs $a1, Cy	# abs(Cy)
	nop
	bge $a1, $a0, loop2
	nop
	li Cy, 0	# Cy = 0.0; 

	loop2:

		# Cx = CxMin + iX * PixelWidth;
		lw $a0, pixelWidth
		mulu Cx, $a0, iX # iX * pW
		lw $a0, CxMin
		addu Cx, Cx, $a0 # t5 Cx

		# Zx = 0.0;
		li Zx, 0
		# Zy = 0.0;
		li Zy, 0
		# Zx2 = Zx * Zx;
		mulu Zx2, Zx, Zx
		# Zy2 = Zy * Zy;
		mulu Zy2, Zy, Zy

		# for (Iteration = 0; Iteration < IterationMax && ((Zx2 + Zy2) < ER2); Iteration++) {
		loop3:
			addu $a2, Zx2, Zy2 # ER2
			bge $a2, 134217728, next3 #134217728 to 4.0 w formacie 7b.25b
			nop
	
			# Zy = 2 * Zx * Zy + Cy;
			mult Zx, Zy
			mfhi Zy
			sll Zy, Zy, 7
			mflo $a1
			srl $a1, $a1, 25
			or Zy, Zy, $a1
			
			sll Zy, Zy, 1	# *2
			addu Zy, Zy, Cy
		
			# Zx = Zx2 - Zy2 + Cx;
			subu Zx, Zx2, Zy2
			addu Zx, Zx, Cx
			
			# Zx2 = Zx * Zx;
			mult Zx, Zx
			mfhi Zx2
			sll Zx2, Zx2, 7
			mflo $a1
			srl $a1, $a1, 25
			or Zx2, Zx2, $a1
		
			# Zy2 = Zy * Zy;
			mult Zy, Zy
			mfhi Zy2
			sll Zy2, Zy2, 7
			mflo $a1
			srl $a1, $a1, 25
			or Zy2, Zy2, $a1
		
			addiu $s6, $s6, 1	# increment iterator
			nop
			blt $s6, $s7, loop3
			nop
	next3:		
		addiu $s0, $s0, 3 # przesuwamy pixel nawet jesli nie kolorujemy go
		 
		# if (Iteration == IterationMax)
		nop
		blt $s6, $s7, next2
		nop
		# kolorujemy srodek
		sb $s1, -1($s0)
		sb $s1, -2($s0)
		sb $s1, -3($s0)
		
		# else 	
	next2:
		li $s6, 0
		addiu iX, iX, 1
		nop
		blt iX, iXmax, loop2
		nop
		# dodanie paddingu
		addu $s0, $s0, $a3
next1:
	li iX, 0
	addiu iY, iY, 1
	nop
	blt iY, iYmax, loop1
	nop
# 
############################### Koniec
# 
	# zapisujemy zaalokowany wczesniej plik
	li $v0, 13	# otwieramy plik
	la $a0, outputFile # output.bmp
	li $a1, 1
	li $a2, 0
	syscall
	move $s6, $v0	# deskryptor w s6
	
	# zapisz do plik
	li $v0, 15
 	move $a0, $s6      # file descriptor 
 	lw $a1, outputFileBegin
 	lw $a2, fileSize
 	syscall
 	
 	# zamkniecie tego pliku
	li $v0, 16	# ostatecznie zamykamy plik out.bmp
	move $a0, $s6
	syscall
end:
	li $v0, 10
	syscall
