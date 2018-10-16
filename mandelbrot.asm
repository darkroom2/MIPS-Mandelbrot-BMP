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

# s6 wolne na dekryptor

.data
.align 2
.space 2
header: .space 54
fileSize: .space 4
width: .space 4
height: .space 4
pixelCount: .space 4
pixelArray: .space 4
outputFileBegin: .space 4
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
	syscall
	move $s6, $v0	# deskryptor w s6
	
	#pobieramy header aby go pozniej zapisac do pliku out.bmp:
	li $v0, 14	# czytanie z pliku
	move $a0, $s6	# ktory "jest tu" (deskryptor)
	la $a1, header	# tu zapisujemy header
	li $a2, 54	# ktory ma 54 bajty
	syscall
	
	li $v0, 16	# zamykamy plik, mamy juz wszystkie informacje o nim
	lw $a0, $s6	# zamykamy go, aby pozniej przy otwarciu, wskaznik pliku byl na jego poczatku
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
	
	la $t0, header + 54 # adres poczatka pixeli
	sw $t0, pixelArray
	
	#majac adres headera i adres poczateku pixeli mozemy przepisac te rzeczy do nowego pliku
	li $v0, 9	# alokujemy pamiec na out.bmp
	lw $a0, fileSize # tyle ile in.bmp
	syscall
	sw $v0, outputFileBegin # zapisujemy adres poczatku zaalokowanej pamieci, aby pozniej przepisac ja do out.bmp
	
	
end:
	li $v0, 10
	syscall
	
	



















































