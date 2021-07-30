HEX

\ Dichiarazione dei registri utilizzati
3F200000 CONSTANT GPFSEL0
3F20001C CONSTANT GPSET0
3F200028 CONSTANT GPCLR0
3F003004 CONSTANT CLO

\ Indirizzi delle righe 1 e 2 dell'LCD
80 CONSTANT LCDLN1
C0 CONSTANT LCDLN2

DECIMAL

\ Dichiarazione delle GPIO utilizzate per connettere l'LCD
25 CONSTANT LCDRS
24 CONSTANT LCDE       
12 CONSTANT LCD0      
4  CONSTANT LCD1      
27 CONSTANT LCD2      
16 CONSTANT LCD3      
23 CONSTANT LCD4      
17 CONSTANT LCD5      
18 CONSTANT LCD6      
22 CONSTANT LCD7

\ Restituisce il valore attuale del registro CLO
( -- clo_value )
: NOW CLO @ ;

\ Setta un ritardo corrispondente al valore presente sullo stack
( delay -- )
: DELAY NOW + BEGIN DUP NOW - 0 <= UNTIL DROP ;

\ Maschera di 32 bit con 3 bit posti ad 1 (7 DECIMAL = 111 BIN ) adibita alla pulizia dei 3 bit del registro GPFSELn che controlla il pin che ci interessa,
\ shiftando di un multiplo di 3 posti questi bit posti ad 1.
( n1 -- n2 )
: MASK 3 * 7 SWAP LSHIFT ;


\ Prende in input il numero della GPIO. Effettua un clear dei valori nel registro GPFSEL relativo alla GPIO che ci interessa.
\ Il registro corretto GPFSEL è ottenuto prendendo la decina della GPIO passata ed utilizzando questo valore come offset partendo da GPFSEL0.
\ L'unità del numero del GPIOn viene utilizzata per spostare la maschera di un multiplo di 3 bit in modo da pulire i 3 bit del registro che
\ controllano la funzionalità della GPIOn, in modo da non alterare gli altri gruppi che corrispondono ad altre GPIO.
\ Sullo stack viene lasciato il valore di GPFSEL con i 3 bit puliti dalla maschera.
( GPIOn -- GPIOn addr_GPFSEL curr_value)
: SET 
	DUP
	10 /MOD 				( remainder quot )
	4 * 					\ moltiplico il quoziente *4 per ottenere l'offset da GPFSEL0
	GPFSEL0 + DUP @ 			\ ottengo GPFSELN dove N = quot.
			 			\ adesso mi trovo all'inizio di GPFSELN
	ROT MASK INVERT AND 2DUP SWAP !	\ abbiamo impostato i bit a zero nei tre bit che ci interessano 
;


\ Setta la GPIOn in OUTPUT
\ L'unità del numero della GPIOn viene usata per spostarsi nella posizione relativa ai 3 bit che controllano la GPIOn.
\ Poichè OUTPUT = 001, spostiamo il valore 1 a sx di un multiplo di 3 bit proporzionale all'unità della GPIOn ottenuta con l'operatore MOD.
\ Viene quindi effettuata un'operazione logica OR tra il bit 1 shifato e il valore corrente che è presente sullo stack, questo per mantenere inalterati tutti gli altri valori del registro GPFSELN. Questo valore finale viene quindi inserito nel registro GPFSELN.
( GPIOn addr_GPFSEL curr_value -- )
: OUTPUT 
	ROT
	10 MOD ( remainder )
	3 * 1 SWAP LSHIFT
	OR SWAP !
;


\ Setta il GPIOn in INPUT
\ L'unità del numero della GPIOn viene usata per spostarsi nella posizione relativa ai 3 bit che controllano la GPIOn.
\ Poichè INPUT = 000, spostiamo il valore 1 a sx di un multiplo di 3 bit proporzionale all'unità della GPIOn ottenuta con l'operatore MOD.
\ Viene quindi effettuata un'operazione logica di INVERT che trasforma 001 in 110 (mentre 001 è circondato da 0, 110 è circondato da 1), sempre shiftato di un multiplo di 3 in base all'unità del numero della GPIOn. Viene quindi effettuato un'operazione di AND per pulire il bit meno significato di quella tripletta di bit (questo perchè potrebbe essere stato posto ad OUTPUT precedentemente e quindi avere solo quel bit posto ad 1.
( GPIOn addr_GPFSEL curr_value -- )
: INPUT 
	ROT
	10 MOD ( remainder )
	3 * 1 SWAP LSHIFT
	INVERT AND ! 
;


\ Prende il valore della GPIOn e lo shifta dello stesso numero di volte, poichè c'è una corrispondenza bitn <-> GPIOn, settando quel bit nel registro GPSET0 ad 1.
( GPIOn -- )
: ON 	1 SWAP LSHIFT GPSET0 ! ;


\ Prende il valore della GPIOn e lo shifta dello stesso numero di volte, poichè c'è una corrispondenza bitn <-> GPIOn, settando quel bit nel registro GPCLR0 ad 1.
( GPIOn -- )
: OFF 	1 SWAP LSHIFT GPCLR0 ! ;



\ Effettua il set dei pin dell'LCD ad OUTPUT
( -- )
: LCD-SETUP
	LCDRS SET OUTPUT
	LCDE SET OUTPUT
	LCD0 SET OUTPUT
	LCD1 SET OUTPUT
	LCD2 SET OUTPUT
	LCD3 SET OUTPUT
	LCD4 SET OUTPUT
	LCD5 SET OUTPUT
	LCD6 SET OUTPUT
	LCD7 SET OUTPUT 
;

\ Abilita l'enable
( -- )
: LCDEON LCDE ON ;

\ Disabilita l'enable
( -- )
: LCDEOFF LCDE OFF ;


HEX

\ Controlla il bit n2 del valore n1 restituendo TRUE(-1) se quel bit è diverso da zero, quindi quel bit è posto ad 1, FALSE(0) se invece è uguale zero, quindi quel bit è posto a zero.
( n1 n2 -- flag ) 
: CHECKBIT AND 0<> ;


\ Controlla il flag. Se è TRUE(-1), setta il pin corrispondente ad ON, se è FALSE(0), setta il pin corrispondente ad OFF.
( flag pin -- ) 
: ?LCDSET SWAP IF ON ELSE OFF THEN ;


\ Prende in input dei valori esadecimali che, trasformati in binario, corrispondono alla sequenza di bit corrispondente ad una funzione che vogliamo passare all'LCD.
\ Scrive in modalità 8 bit.
\ Se RS=1 viene mandato un comando (n<0x100). Viceversa, vengono mandati dati.
\ Ogni input è rappresentato da un valore esadecimale che corrisponde al settaggio di bit ad 1 o a 0.
\ Questi bit nel comando vengono controllati uno ad uno.
\ Viene effettuato un controllo sul bit dell'input relativo al pin, per vedere se è 0 o 1. In base al suo valore, si mette in HIGH se il bit è 1, in LOW se è 0.
( n -- )
: LCDWRITE 
	DUP 100 CHECKBIT LCDRS ?LCDSET LCDEON 
	DUP 80 CHECKBIT LCD7 ?LCDSET 
	DUP 40 CHECKBIT LCD6 ?LCDSET
	DUP 20 CHECKBIT LCD5 ?LCDSET 
	DUP 10 CHECKBIT LCD4 ?LCDSET 
	DUP 08 CHECKBIT LCD3 ?LCDSET 
	DUP 04 CHECKBIT LCD2 ?LCDSET 
	DUP 02 CHECKBIT LCD1 ?LCDSET 
	DUP 01 CHECKBIT LCD0 ?LCDSET 
	DROP LCDEOFF
;


\ Pulisce il display scrivendo il carattere SPAZIO su tutta la DDRAM e riportando il puntantore all'inizio.
( -- ) 
: LCDCLR 1 LCDWRITE ;


\ Effettua l'inizializzazione dell'LCD settando le impostazioni desiderate.
( -- )
: LCD-INIT
	LCD-SETUP 
	\ Function Set: 8-bit, 2 Line, 5x8 Dots
	\ Il valore 38 è il valore in HEX che corrisponde in binario ad una configurazione della Function Set suddetta
	\ In binario 38 = 0011 1000, dove: 
	\ - i bit alla posizione 0 e 1 sono arbitrari: la loro scelta non influisce
	\ - il bit 2 (F) rappresenta il bit di controllo del formato del display. LOW=5x8, HIGH=5x11
	\ - il bit 3 (N) rappresenta il bit di controllo per decidere il n° di linee.LOW=1, HIGH=2
	\ - il bit 4 (DL) rappresenta la modalità a 4 o 8 bit. LOW=4-bit, HIGH=8-bit.
	\ - il bit 5 è 1 di default.
	38 LCDWRITE
	500 DELAY
	
	\ Entry Mode Set
	\ Setta la direzione di movimento del cursore e abilita/disabilita il display.
	\ Il valore 6 è il valore in HEX che corrisponde in binario ad una configurazione della Entry Mode Set
	\ In binario 6 = 0110, dove: 
	\ - bit 0 (S): shifta l'intero display. LOW=NoShift, HIGH=Shift
	\ - bit 1 (I/D): incrementa/decrementa l'indirizzo della DDRAM e sposta il cursore. LOW=MoveToSx-Decrement, HIGH=MoveToDx-Increment
	\ - il bit 2 è 1 di default.
	6 LCDWRITE 
	500 DELAY
	
	\ Display ON/OFF Control
	\ Setta alcune modalità visive del display
	\ Il valore C è il valore in HEX che corrisponde in binario ad una configurazione del Display ON/OFF Control
	\ In binario C = 1100, dove: 
	\ - bit 0 (B): Blink del cursore. LOW=NoBlink, HIGH=BlinkSet
	\ - bit 1 (C): Cursore presente o no. LOW=NoCursor, HIGH=CursorSet
	\ - bit 2 (D): Display ON/OFF. LOW=OFF, HIGH=ON
	\ - bit 3: 1 per default.
	C LCDWRITE 
	500 DELAY 
	
	LCDCLR 
;


DECIMAL


\ Stampa un numero sull'LCD.
\ Il numero viene scritto partendo dall'unità e scrivendo verso sx. Questo è possibile grazie alla ripetizione dell'operatore /MOD.
\ Il numero 304 in DECIMAL corrisponde a 130 in HEX = 1 0011 0000, che corrisponde al comando di scrittura nell'LCD.
\ In particolare, i 5 bit più significativi vengono lasciati sempre inalterati poichè quale numero viene scritto dipende dai 4 bit meno significativi.
\ (Basta guardare il datasheet per rendersi conto che il primo 1 indica la scrittura in DDRAM, che 0011 è comune a tutti i numeri da 0 a 9 e che
\ gli ultimi 4 bit corrispondono al valore binario effettivo del numero).
( n -- )
: LCDNTYPE BEGIN 10 /MOD SWAP 304 + LCDWRITE DUP 0= UNTIL DROP ;


HEX


\ Stampa una stringa sull'LCD.
\ Con c@ preleviamo il carattere all'interno dell'indirizzo della stringa che, sommato a 100 HEX, dà 1xx, dove xx è il valore ASCII del carattere
\ da scrivere, dando così il comando Write data to RAM all'LCD.
( addr_string lenght_string -- )
: LCDSTYPE OVER + SWAP BEGIN 2DUP <> WHILE DUP c@ 100 + LCDWRITE 1+ REPEAT 2DROP ;


\ n=0 restituisce l'indirizzo della prima linea dell'LCD (LCDLN1), altrimenti quello della seconda linea (LCDLN2)
( n -- addr_line )
: LCDLN 0 = IF LCDLN1 ELSE LCDLN2 THEN ;


\ Chiama la Set DDRAM address mandando all'LCD il comando 8x, dove x è l'offset (80 inizio linea, 81 spostati di una cella, e così via...). Setta l'indirizzo della DDRAM da cui cominciare a scrivere.
\ IndirizzoLinea + Offset = Indirizzo di partenza per la scrittura -> LCDWRITE manda il comando.
( n -- )
: LCDLN! LCDLN + LCDWRITE ;


\ Manda il comando all'LCD per far spostare il cursore e il puntatore alla DDRAM da sx a dx (incrementando il valore della DDRAM)
( -- )
: LCDCURL>R 6 LCDWRITE ;


\ Manda il comando all'LCD per far spostare il cursore e il puntatore alla DDRAM da dx a sx (decrementando il valore della DDRAM)
( -- )
: LCDCURL<R 4 LCDWRITE ;


\ Stampa un numero nella linea (0=linea 1, !0=linea 2) spostato dal lato sx dell'LCD di un certo offset.
\ In base alla linea, lascia sullo stack l'indirizzo della linea desiderata + offset.
( number offset line -- )
: LCDNUMBER LCDLN! LCDCURL<R LCDNTYPE ;


\ Stampa una stringa nella linea (0=linea 1, !0=linea 2) spostata dal lato sx dell'LCD di un certo offset.
\ In base alla linea, lascia sullo stack l'indirizzo della linea desiderata + offset.
( addr_string lenght_string offset line -- )
: LCDSTRING LCDLN! LCDCURL>R LCDSTYPE ;


LCD-INIT
