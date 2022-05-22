ORG 0

	sjmp	test_count_even_gt10	; przyklad testu wybranej procedury

test_sum_iram:
	mov	R0, #30h	; adres poczatkowy obszaru
	mov	R2, #4		; dlugosc obszaru
	lcall	sum_iram
	sjmp	$

test_copy_iram_iram_inv:
	mov	R0, #30h	; adres poczatkowy obszaru zrodlowego
	mov	R1, #40h	; adres poczatkowy obszaru docelowego
	mov	R2, #4		; dlugosc obszaru
	lcall	copy_iram_iram_inv
	sjmp	$

test_copy_xram_iram_z:
	mov	DPTR, #8000h	; adres poczatkowy obszaru zrodlowego
	mov	R0, #30h	; adres poczatkowy obszaru docelowego
	mov	R2, #4		; dlugosc obszaru
	lcall	copy_xram_iram_z
	sjmp	$

test_copy_xram_xram:
	mov	DPTR, #8000h	; adres poczatkowy obszaru zrodlowego
	mov	R0, #LOW(8010h)	; adres poczatkowy obszaru docelowego
	mov	R1, #HIGH(8010h)
	mov	R2, #4		; dlugosc obszaru
	lcall	copy_xram_xram
	sjmp	$

test_count_even_gt10:
	mov	R0, #30h	; adres poczatkowy obszaru
	mov	R2, #4		; dlugosc obszaru
	lcall	count_even_gt10
	sjmp	$

;---------------------------------------------------------------------
; Sumowanie bloku danych w pamieci wewnetrznej (IRAM)
;
; Wejscie: R0    - adres poczatkowy bloku danych
;          R2    - dlugosc bloku danych
; Wyjscie: R7|R6 - 16-bit suma elementow bloku (Hi|Lo)
;---------------------------------------------------------------------
sum_iram:
	mov	R6, #0		; zerowanie sumy
	mov	R7, #0
	mov	A, R2
	jz	if_zero1	; koniec jesli dlugosc 0
	
loop_sum_iram:
	mov	A, @R0
	add	A, R6
	mov	R6, A
	jnc	no_transfer	; sprawdzamy czy jest przeniesienie
	inc	R7
	
no_transfer:
	inc	R0
	djnz	R2, loop_sum_iram
	
if_zero1:
	ret

;---------------------------------------------------------------------
; Kopiowanie bloku danych w pamieci wewnetrznej (IRAM) z odwroceniem
;
; Wejscie: R0 - adres poczatkowy obszaru zrodlowego
;          R1 - adres poczatkowy obszaru docelowego
;          R2 - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_iram_iram_inv:
	mov	A, R2
	jz	if_zero2
	add	A, R1
	dec	A
	mov	R1, A	; wskazuje na ostatni bajt obszaru docelowego
	
loop_copy_iram_iram_inv:
	mov	A, @R0
	mov	@R1, A
	inc	R0
	dec	R1
	djnz	R2, loop_copy_iram_iram_inv

if_zero2:
	ret

;---------------------------------------------------------------------
; Kopiowanie bloku z pamieci zewnetrznej (XRAM) do wewnetrznej (IRAM)
; Przy kopiowaniu powinny byc pominiete elementy zerowe
;
; Wejscie: DPTR - adres poczatkowy obszaru zrodlowego
;          R0   - adres poczatkowy obszaru docelowego
;          R2   - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_xram_iram_z:
	mov	A, R2
	jz	if_zero3

loop_copy_xram_iram_z:
	movx	A, @DPTR
	
	
check_if_zero:
	jz	skip_zero
	mov	@R0, A
	inc	R0	; liczba nie zerem wiec zwiekszamy adres docelowy
	
skip_zero:
	inc	DPTR	; zawsze zwiekszamy adres zrodlowy
	djnz	R2, loop_copy_xram_iram_z

if_zero3:
	ret

;---------------------------------------------------------------------
; Kopiowanie bloku danych w pamieci zewnetrznej (XRAM -> XRAM)
;
; Wejscie: DPTR  - adres poczatkowy obszaru zrodlowego
;          R1|R0 - adres poczatkowy obszaru docelowego
;          R2    - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_xram_xram:
	mov	A, R2
	jz	if_zero4

loop_copy_xram_xram:
	movx	A, @DPTR
	inc	DPTR
	
	push	DPH
	push	DPL
	
	mov	DPH, R1
	mov	DPL, R0
	
	movx	@DPTR, A
	inc	DPTR
	
	mov	R1, DPH
	mov	R0, DPL
	
	pop	DPL
	pop	DPH
	
	
	djnz	R2, loop_copy_xram_xram
	

if_zero4:
	ret

;---------------------------------------------------------------------
; Zliczanie w bloku danych w pamieci wewnetrznej (IRAM)
; liczb parzystych wiekszych niz 10
;
; Wejscie: R0 - adres poczatkowy bloku danych
;          R2 - dlugosc bloku danych
; Wyjscie: A  - liczba elementow spelniajacych warunek
;---------------------------------------------------------------------
count_even_gt10:
	mov	A, R2
	jz	if_zero5
	
	mov	R6, #0	; licznik
	
loop_count_even_gt10:
	mov	A, @R0
	cjne	A, #11, check_if_less

check_if_less:
	jc	final_check

check_parity:
	;rrc	A
	;jc	final_check
	
	jb	ACC.0, final_check	; sprawdzamy parzystosc
	inc	R6
	
final_check:
	inc 	R0
	djnz	R2, loop_count_even_gt10
	
	mov	A, R6

if_zero5:
	ret

END
