HEX

\ Dichiarazione dei colori in esadecimale (formato ARGB)
00FFFFFF CONSTANT WHITE
00000000 CONSTANT BLACK 
00FF0000 CONSTANT RED
00FFFF00 CONSTANT YELLOW

\ Dichiarazione del base address del framebuffer
3E8FA000 CONSTANT FRAMEBUFFER

VARIABLE DIM

\ Contatore utilizzato nei cicli per disegnare le linee orizzontali
VARIABLE COUNTERH
: RESETCOUNTERH 0 COUNTERH ! ;
: +COUNTERH COUNTERH @ 1 + COUNTERH ! ;
RESETCOUNTERH

\ Contatore utilizzato nei cicli per tenere traccia del numero di riga corrente
VARIABLE NLINE
: RESETNLINE 1 NLINE ! ;
: +NLINE NLINE @ 1 + NLINE ! ;
RESETNLINE


\ Restituisce l'indirizzo del punto centrale dello schermo. Coordinata ((larghezza-1)/2, (altezza-1)/2)
( -- addr )
: CENTER FRAMEBUFFER 200 4 * + 180 1000 * + ;

\ Colora, con il colore presente sullo stack, il pixel corrispondente all'indirizzo presente sullo stack,
\ dopodiché punta al pixel a destra
( color addr -- color addr_col+1 )
: RIGHT 2DUP ! 4 + ; 

\ Colora, con il colore presente sullo stack, il pixel corrispondente all'indirizzo presente sullo stack,
\ dopodiché punta al pixel in basso
( color addr -- color addr_row+1 )
: DOWN 2DUP ! 1000 + ; 

\ Colora, con il colore presente sullo stack, il pixel corrispondente all'indirizzo presente sullo stack,
\ dopodiché punta al pixel a sinistra
( color addr -- color addr_col-1 )
: LEFT 2DUP ! 4 - ;

\ Ripristina il valore di partenza dell'indirizzo a seguito di COUNTERH * 4 spostamenti a destra
( addr_endline_right -- addr )
: RIGHTRESET COUNTERH @ 4 * - ;

\ Ripristina il valore di partenza dell'indirizzo a seguito di COUNTERH * 4 spostamenti a sinistra
( addr_endline_left -- addr )
: LEFTRESET COUNTERH @ 4 * + ;


\ Disegna una linea verso destra di dimensione pari a 48 pixel
: RIGHTDRAW
	BEGIN COUNTERH @ DIM @ < WHILE +COUNTERH RIGHT REPEAT RIGHTRESET RESETCOUNTERH ;
\ Disegna una linea verso sinistra di dimensione pari a 48 pixel
: LEFTDRAW
	BEGIN COUNTERH @ DIM @ < WHILE +COUNTERH LEFT REPEAT LEFTRESET RESETCOUNTERH ;

\ Disegna il simbolo di pausa (due pipe distanziate)
: DRAWPAUSE
	30 DIM !
	\ Disegna la prima linea della seconda pipe
	WHITE CENTER RIGHTDRAW

	\ Disegna la prima linea della prima pipe, spostandosi di 32 pixel a sinistra
	WHITE CENTER 80 - LEFTDRAW

	\ Ciclo che disegna due pipe, distanziate, di altezza 105 pixel
	BEGIN NLINE @ 70 <
	WHILE
		\ Disegna l'n-esima linea della prima pipe
		DOWN LEFTDRAW
		2SWAP
		
		\ Disegna l'n-esima linea della seconda pipe
		DOWN RIGHTDRAW
		2SWAP
		
		+NLINE
	REPEAT 
	4DROP RESETNLINE
;

\ Disegna o il simbolo di stop o pulisce la porzione di schermo su cui disegnamo.
\ Partendo da CENTER-32px-48px, quindi CENTER-80px, e poichè ogni spostamento di 1px su una riga
\ vale 4, abbiamo 320 in dec e cioè 140 in hex
: DRAWSQUARE
	80 DIM !
	CENTER 140 - RIGHTDRAW
	
	\ Ciclo che disegna un simbolo di stop di altezza 105 pixel
	BEGIN NLINE @ 70 <
	WHILE
		DOWN RIGHTDRAW
		+NLINE
	REPEAT 
	2DROP RESETNLINE
;

\ Disegna il simbolo di start.
: DRAWSTART 
	RED CENTER 80 -
	BEGIN NLINE @ 70 <=
	WHILE
		\ Permette di rappresentare le linee del triangolo superiore del simbolo start
		NLINE @ 37 <= IF
			NLINE @ DIM !
		\ Permette di rappresentare le linee del triangolo inferiore del simbolo start
		ELSE
			70 NLINE @ - DIM !
		THEN
			\ Disegna una linea verso destra di dimensione variabile e dipendente dal numero di riga 				\ memorizzato in NLINE.
			DOWN RIGHTDRAW
			+NLINE		
	REPEAT
	2DROP RESETNLINE	
;

: DRAWSTOP YELLOW DRAWSQUARE ;
: CLEAN BLACK DRAWSQUARE ;

