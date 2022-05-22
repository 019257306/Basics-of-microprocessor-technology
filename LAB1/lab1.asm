ORG 0

;---------------------------------------------------------------------
; Test procedury - wywolanie jednorazowe
;---------------------------------------------------------------------
	sjmp	test7	; testowe wywolanie procedury

;---------------------------------------------------------------------
; Test procedury - wywolanie powtarzane
;---------------------------------------------------------------------
test1:	
	mov	R0, #30h	; liczba w komorkach IRAM 30h i 31h
	lcall	dec_iram	; wywolanie procedury
	sjmp	$		; petla bez konca

test2:
	mov	DPTR, #8000h	; liczba w komorkach XRAM 8000h i 8001h
	lcall	inc_xram
	sjmp	$		; petla bez konca

test3:
	mov	R0, #30h
	mov	R1, #20h
	lcall	sub_iram
	sjmp	$		; petla bez konca

test4:
	mov	R6, #00100001b	
	mov	R7, #01000011b
	lcall	set_bits
	sjmp	$		; petla bez konca
	
test5:	
	mov	R6, #00100001b
	mov	R7, #01000011b
	lcall	shift_left
	sjmp	$		; petla bez konca
	
test6:	
	mov 	DPTR, #code_const
	lcall	get_code_const
	sjmp	$		; petla bez konca

test7:
	mov	DPTR, #1234h
	mov	R6, #26h
	mov	R7, #30h
	lcall	swap_regs
	sjmp	$		; petla bez konca
		
test8:
	mov	R2, #5
	mov 	DPTR, #8000h
	lcall	add_xram
	sjmp	$		; petla bez konca
	
;=====================================================================

;---------------------------------------------------------------------
; Dekrementacja liczby dwubajtowej w pamieci wewnetrznej (IRAM)
; R0 - adres mlodszego bajtu (Lo) liczby
;---------------------------------------------------------------------
dec_iram:	
	mov	A, @R0
	clr	C	; zabiezpieczenie
	subb 	A, #1	; operacja dekrementacji
	mov	@R0, A
	inc	R0
	mov	A, @R0
	subb 	A, #0
	mov	@R0, A

	ret

;---------------------------------------------------------------------
; Inkrementacja liczby dwubajtowej w pamieci zewnetrznej (XRAM)
; DPTR - adres mlodszego bajtu (Lo) liczby
;---------------------------------------------------------------------
inc_xram:
	movx	A, @DPTR
	add	A, #1
	movx 	@DPTR, A
	inc	DPTR
	movx 	A, @DPTR
	addc 	A, #0	; inkrementacja z uwzglednieniem pozyczki
	movx 	@DPTR, A 
	
	ret

;---------------------------------------------------------------------
; Odjecie liczb dwubajtowych w pamieci wewnetrznej (IRAM)
; R0 - adres mlodszego bajtu (Lo) odjemnej A oraz roznicy (A <- A - B)
; R1 - adres mlodszego bajtu (Lo) odjemnika B
;---------------------------------------------------------------------
sub_iram:
	mov	A, @R0
	clr	C
	subb	A, @R1
	mov	@R0,A
	inc	R0
	inc	R1	; linia 100 oraz 101 zmieszczenie o jedna komorke w prawo
	mov	A, @R0
	subb	A, @R1
	mov	@R0, A
	
	ret

;---------------------------------------------------------------------
; Ustawienie bitow parzystych (0,2, ..., 14) w liczbie dwubajtowej
; Wejscie: R7|R6 - liczba dwubajtowa
; Wyjscie: R7|R6 - liczba po modyfikacji
;---------------------------------------------------------------------
set_bits:
	mov	A, R6
	orl	A, #01010101b
	mov	R6, A
	mov	A, R7
	orl	A, #01010101b
	mov	R7, A
	
	ret

;---------------------------------------------------------------------
; Przesuniecie w lewo liczby dwubajtowej (mnozenie przez 2)
; Wejscie: R7|R6 - liczba dwubajtowa
; Wyjscie: R7|R6 - liczba po modyfikacji
;---------------------------------------------------------------------
shift_left:
	clr	C	; wyzerowanie bita 0
	mov	A, R6
	rlc	A
	mov	R6, A
	mov	A, R7
	rlc	A
	mov	R7, A
	
	ret

;---------------------------------------------------------------------
; Pobranie liczby dwubajtowej z pamieci kodu
; Wejscie: DPTR  - adres mlodszego bajtu (Lo) liczby w pamieci kodu
; Wyjscie: R7|R6 - pobrane dane
;---------------------------------------------------------------------
get_code_const:
	clr	A
	movc 	A, @A+DPTR
	mov	R6, A
	clr	A
	inc	DPTR
	movc 	A, @A+DPTR
	mov	R7, A
	
	ret

;---------------------------------------------------------------------
; Zamiana wartosci rejestrow DPTR i R7|R6
; Nie niszczy innych rejestrow
;---------------------------------------------------------------------
swap_regs:
	push	ACC

	; 	czesc mlodsza
	mov	A, DPL
	xch	A, R6
	mov	DPL, A
	
	;	czesc starsza
	mov	A, DPH
	xch	A, R7
	mov	DPH,A
	
	pop	ACC
	ret

;---------------------------------------------------------------------
; Dodanie 10 do danych w obszarze pamieci zewnetrznej (XRAM)
; DPTR - adres poczatku obszaru
; R2   - dlugosc obszaru
;---------------------------------------------------------------------
add_xram:
	mov	A, R2	; licznik
	jz	zero	; zabiezpieczenie( sprawdzamy czy dlugosc jest niezerowa)

if_not_zero:
	movx	A, @DPTR
	add	A, #10
	movx	@DPTR, A
	inc 	DPTR
	djnz	R2, if_not_zero
	
zero:
	ret

;---------------------------------------------------------------------
code_const:
	DB	LOW(1234h)
	DB	HIGH(1234h)

END
