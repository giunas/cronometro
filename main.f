\ Ordine di inclusione dei file
\ start.f
\ lcd.f
\ HDMI.f
\ main.f

HEX

\ Dichiarazione dell'indirizzo del registro GPEDS0 come costante
3F200040 CONSTANT GPEDS0 

\ Dichiarazione dell'indirizzo del registro GPAREN0 come costante
3F20007C CONSTANT GPAREN0

\ Dichiarazione della costante che indica un secondo e che ha valore 1 000 000 usec in decimale o 
\ F4240 in hex
F4240 CONSTANT SEC


\ Variabile che memorizza il valore del tempo da visualizzare su lcd 
VARIABLE COUNTER

\ Variabile che memorizza il valore attuale del CLO + 1 secondo 
VARIABLE COMP0

\ Contatore circolare per i parziali
VARIABLE COUNTERP

\ Flag che permette di stabilire se siamo passati o meno dallo stop
VARIABLE FLAG 

\ Flag per disegnare lo start sull'hdmi
VARIABLE DSFLAG

\ Inizializzazione delle variabili utilizzate
0 COMP0 !
0 COUNTER !
0 COUNTERP !
1 FLAG !
1 DSFLAG !

\ Rendiamo sensibili ai fronti di salita le GPIO0, GPIO1, GPIO5, GPIO6, a cui sono associati i pulsanti, quindi
\ avremo 0110 0011 che equivale a 99 in decimale o 0x63 in esadecimale
: GPAREN! 63 GPAREN0 ! ;

\ Stampa sull'LCD la home con le possibili azioni
\ ( -- )
: PRINTHOME S" 1.START" 0 0 LCDSTRING S" 3.PAUSE" 9 0 LCDSTRING S" 2.STOP" 0 1 LCDSTRING S" 4.PART." 9 1 LCDSTRING ;

\ Queste word ci permettono di stampare i secondi, i minuti e le ore ed eventualmente gli zero più significativi del \ cronometro
\ (sec -- )
DECIMAL : PRINTSEC DUP 15 0 LCDNUMBER 10 < IF 0 14 0 LCDNUMBER THEN ;
\ (min -- )
DECIMAL : PRINTMIN DUP 12 0 LCDNUMBER 10 < IF 0 11 0 LCDNUMBER THEN ;
\ (hour -- )
DECIMAL : PRINTHOUR DUP 9 0 LCDNUMBER 10 < IF 0 8 0 LCDNUMBER THEN ;


\ Queste word ci permettono di stampare i secondi, i minuti ed eventualmente gli zero più significativi dei parziali
\ (sec -- )
DECIMAL : PRINTSECPART DUP 4 COUNTERP @ LCDNUMBER 10 < IF 0 3 COUNTERP @ LCDNUMBER THEN ;
\ (min -- )
DECIMAL : PRINTMINPART DUP 1 COUNTERP @ LCDNUMBER 10 < IF 0 0 COUNTERP @ LCDNUMBER THEN ;

\ La Mod Swap Word restituisce il MOD 60 di un numero passato, in particolare quello del cronometro, il cui valore
\ è inizialmente espresso in secondi. La MSW quindi pone sullo stack il resto e il quoto della divisione per 60
\ ed effettua successivamente uno swap. 
\ (n1 -- n3 n2)
: MSW 60 /MOD SWAP ;

\ Stampiamo nell'ordine prima i secondi, poi i minuti, poi le ore e infine le colon del cronometro
\ ( -- )
DECIMAL : PRINTCOUNT COUNTER @ MSW PRINTSEC MSW PRINTMIN PRINTHOUR S" :" 13 0 LCDSTRING S" :" 10 0 LCDSTRING DECIMAL ;

\ Memorizza il valore attuale del CLO + 1 secondo in COMP0
: INC NOW SEC + COMP0 ! ;

\ Stampiamo nell'ordine prima i secondi, poi i minuti e infine le colon dei parziali
\ ( -- )
DECIMAL : PRINTPARTIAL COUNTER @ MSW PRINTSECPART MSW PRINTMINPART S" :" 2 COUNTERP @ LCDSTRING DECIMAL ;

\ Questa word azzera il timer quando abbiamo premuto stop
: CHECKSTOP COUNTER @ 0 <> IF 0 COUNTER ! THEN ;

\ Segnala ogni qual volta è passato un secondo confrontando CLO con COMP0
: SLEEPS HEX INC BEGIN NOW COMP0 @ < WHILE REPEAT CR ." Passato 1 sec " DROP DECIMAL ;

: INCCOUNT COUNTER @ 1 + COUNTER ! ;

\ Aggiorna il valore della riga su cui stampare il parziale corrente
: LINEA COUNTERP @ 2 MOD COUNTERP ! ;

\ Si occupa di stampare il valore del contatore, di attendere un secondo e successivamente di incrementare
\ il valore di COUNTER
: CONDCOUNT PRINTCOUNT SLEEPS INCCOUNT ;

\ Quando si preme il pulsante del parziale viene stampato a video il parziale.
\ Controlla se è stato premuto il pulsante START collegato alla GPIO5 (32) e, successivamente, il pulsante
\ per il parziale collegato alla GPIO1 (2)
: PARTIAL GPEDS0 @ 34 = IF LINEA PRINTPARTIAL COUNTERP @ 1 + COUNTERP ! THEN 2 GPEDS0 ! ;

\ Set e reset delle flag
: SETFLAG 1 FLAG ! ;
: RESETFLAG 0 FLAG ! ;
: SETDSFLAG 1 DSFLAG ! ;
: RESETDSFLAG 0 DSFLAG ! ;

\ Stampa la home se flag = 1, quindi all'avvio di MAIN ovvero se siamo passati dallo stop 
\ (così diversifichiamo dalla pausa)
: HOME
	FLAG @ 1 = IF PRINTHOME THEN
;

: START
	BEGIN
	\ Controlla se è stato premuto il pulsante START collegato alla GPIO5
	GPEDS0 @ 32 = WHILE 
	
		\ Permette di effettuare la pulizia dell'hdmi e l'inserimento del simbolo start
		\ una sola volta
		DSFLAG @ 1 = IF CLEAN DRAWSTART RESETDSFLAG THEN
		
		\ Permette di effettuare la pulizia dell'LCD solo se il programma è appena stato avviato
		\ o se si proviene dallo stop
		FLAG @ 1 = IF LCDCLR SLEEPS RESETFLAG THEN
		
		CONDCOUNT
		
		\ In questo modo "rimaniamo in ascolto" nel caso in cui l'utente dovesse premere il pulsante
		\ del parziale
		PARTIAL
	REPEAT
	\ Resettiamo il valore di GPEDS0
	32 GPEDS0 !
;

: PAUSA
	\ Controlla se è stato premuto il pulsante PAUSA collegato alla GPIO0
	GPEDS0 @ 1 = IF
		\ Clean dello schermo HDMI
		CLEAN
		\ Disegna il simbolo di pausa sull'HDMI
		DRAWPAUSE
		\ Indica che dopo la pausa si vuole ristampare il simbolo di start
		SETDSFLAG
	THEN
	\ Resettiamo il valore di GPEDS0
	1 GPEDS0 !
;

: STOP 
	\ Controlla se è stato premuto il pulsante STOP collegato alla GPIO6
	GPEDS0 @ 64 = IF
		CHECKSTOP
		\ Indica che proveniamo dallo stop e che quindi la prossima cosa da visualizzare è la home
		SETFLAG
		\ Clear dell'LCD
		LCDCLR
		\ Clean dello schermo HDMI
		CLEAN
		\ Disegna lo stop sull'HDMI
		DRAWSTOP
		\ Indica che dopo lo stop si vuole ristampare il simbolo di start
		SETDSFLAG
	THEN
	\ Resettiamo il valore di GPEDS0
	64 GPEDS0 !
;

\ La quit e' una funzionalita' aggiuntiva.
\ Questo comando ci permette di non far nulla quando premiamo il pulsante del parziale
\ mentre il cronometro non è avviato (con la quit presente usciamo dal ciclo infinito)
: DISABLEPART GPEDS0 @ 2 = IF 2 GPEDS0 ! QUIT THEN ;

\ Ciclo principale
: MAIN
	BEGIN
	TRUE WHILE 
	HOME DISABLEPART START PAUSA STOP
	REPEAT 
;


GPAREN!
MAIN 

