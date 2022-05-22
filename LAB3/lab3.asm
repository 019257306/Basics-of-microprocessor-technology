;------------------------------------------------------------------------------
LEDS		EQU	P1			; diody LED na P1 (0 = ON)
;------------------------------------------------------------------------------
TIME_MS		EQU	10			; czas w [ms]
CYCLES		EQU	(1000 * TIME_MS)	; czas w cyklach (f = 12 MHz)
LOAD		EQU	(65536 - CYCLES)	; wartosc ladowana do TH0|TL0
;------------------------------------------------------------------------------
SEC_100		EQU	30h			; sekundy x 0.01
SEC		EQU	31h			; sekundy
MIN		EQU	32h			; minuty
HOUR		EQU	33h			; godziny
;------------------------------------------------------------------------------

ORG 0

	sjmp	leds_loop
	lcall	init_time		; inicjowanie czasu
	
time_loop:
	lcall	delay_10ms
	;lcall	delay_timer_10ms	; opoznienie 10 ms timerem
	;lcall	delay_nx10ms		; opoznienie 10 ms
	lcall	update_time		; aktualizacja czasu
	jnc	time_loop		; nie bylo zmiany sekund
					; tutaj zmiana sekund
	sjmp	time_loop

leds_loop:
	mov	R7, #50			; opoznienie 500 ms
	;lcall	delay_nx10ms
	lcall	leds_change_2		; zmiana stanu diod
	sjmp	leds_loop

;---------------------------------------------------------------------
; Opoznienie 10 ms (zegar 12 MHz)
;---------------------------------------------------------------------
delay_10ms:			; 2 lcall
	mov	R2, #99		;1	
		
loop:
	mov	R3, #48		;1
	djnz	R3, $		;2	48 * 2 = 96
	nop			;1
	djnz	R2, loop 	;2	
	
	; 2 + 1 + (1 + 96 + 1 + 2) * 99 = 9903
	
	mov	R3, #47		;1
	djnz	R3, $		;2	47 * 2 = 94
	ret			;2
	; 9903 + 97  = 10000

;---------------------------------------------------------------------
; Opoznienie n * 10 ms (zegar 12 MHz)
; R7 - czas x 10 ms
;---------------------------------------------------------------------
delay_nx10ms:
	lcall	delay_10ms
	djnz	R7, delay_nx10ms
	ret

;---------------------------------------------------------------------
; Opoznienie 10 ms z uzyciem Timera 0 (zegar 12 MHz)
;---------------------------------------------------------------------
delay_timer_10ms:
	clr 	TR0			; Zatrzymanie timera
	anl	TMOD, #0F0h
	orl	TMOD, #01h		; Zaprogramowanie trybu 16-bitowego
	mov	TL0, #LOW(LOAD)	
	mov	TH0, #HIGH(LOAD) 	; Wpisanie odpowiednich wartosci do rejestrow licznika
	clr	TF0			; wyzerowanie flagi przepelnienia timera
	setb	TR0			; Uruchomienie timera
	jnb 	TF0, $			; Czekanie na ustawienie flagi przepelnienia timera  (jesli zero - powt)
	ret

;---------------------------------------------------------------------
; Inicjowanie czasu w zmiennych: HOUR, MIN, SEC, SEC_100
;---------------------------------------------------------------------
init_time:
	mov	HOUR,	#0
	mov	MIN,	#0
	mov	SEC,	#59
	mov	SEC_100,#0
	ret

;---------------------------------------------------------------------
; Aktualizacja czasu w postaci (HOUR : MIN : SEC) | SEC_100
; Przy wywolywaniu procedury co 10 ms
; wykonywana jest aktualizacja czasu rzeczywistego
;
; Wyjscie: CY - sygnalizacja zmiany sekund (0 - nie, 1 - tak)
;---------------------------------------------------------------------
update_time:
	clr	F0			; wyzerowanie flagi zmiany sekund
	inc	SEC_100			
	mov	A, SEC_100			
	cjne	A, #100, finish1	
	mov	SEC_100, #0		
	setb	F0			
	inc	SEC					
	mov	A, SEC				
	cjne	A, #60, finish1
	mov	SEC, #0	
	inc	MIN					
	mov	A, MIN				
	cjne	A, #60, finish1		
	mov	MIN, #0
	inc	HOUR				
	mov	A, HOUR				
	cjne	A, #24, finish1		
	mov	HOUR, #0
	
finish1:
	mov	C, F0			
	ret

;---------------------------------------------------------------------
; Zmiana stanu LEDS - wedrujaca w lewo dioda
;---------------------------------------------------------------------
leds_change_1:
	mov	A, LEDS
	cjne	A, #0FFh, left_rotate	; czy diody nie sa ustawione jak na poczatku
	mov	A, #0FEh		; zapalenie ostatniej diody
	sjmp	finish2	
	
left_rotate:		 
	rl	A			
	
finish2:
	mov	LEDS, A	
	ret
	

;---------------------------------------------------------------------
; Zmiana stanu LEDS - narastajacy pasek od prawej
;---------------------------------------------------------------------
leds_change_2:
	mov	A, LEDS
	;cjne	A, #0FFh, check				; czy diody nie sa ustawione w jak na poczatku
	;mov	A, #0FEh				; zapalenie ostatniej diody
	;sjmp	finish3
	
	
check:
	jnz	 left_rotate_until_turn_off 		; czy wszystkie diody nie sa zapalone
	mov	A, #0FFh				; wylaczenie wszystkich diod
	sjmp	finish3	
	
left_rotate_until_turn_off:
	clr	C
	rlc	A				
	;anl	A, #0FEh			
		
finish3:
	mov	LEDS, A	
	ret

END
