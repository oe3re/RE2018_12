INCLUDE Irvine32.inc

BufSize = 11 ;//velicina buffera. Izabrano je 11 polja jer je najveca dozvoljena otpornost 999 Moma,
			 ;//dakle 7 cifara plus 0dh i 0ah za novi red

.data

;//stringovi za iscrtavanje boja
str1 byte "..CRNA..", 0
str2 byte "   ", 0
str3 byte 0dh, 0ah, 0

;//stringovi za ispisivanje odgovarajucih poruka

porUnosa LABEL BYTE
BYTE "Unesi zeljenu vrednost otpornika (vrednost 0oma gasi program)...", 0dh, 0ah
porUnDuz DWORD($ - porUnosa)
ispisanoBY DWORD ?

porLosaVr LABEL BYTE
BYTE "Uneta vrednost nije standardna...", 0dh, 0ah
porLVDuz DWORD($ - porLosaVr)
ispisBY DWORD ?

buffer BYTE BufSize DUP(? )
procitanoBY DWORD ?

consoleHandle HANDLE 0

otpornost DWORD 0
cifra DWORD ?
stepen10 DWORD ?
pomocna DWORD ?
prsten1 WORD 0
prsten2 WORD 0
prsten3 WORD 0
prsten4 WORD 0
pom WORD 0

.code

kodirajBoju proc c uses eax ulazni : word

	mov ebx, 0
	cmp bx, ulazni
	jne necrna
	mov cifra, 128
	jmp obojeno
necrna :

	mov ebx, 1
	cmp bx, ulazni
	jne nebraon
	mov cifra, 4
	jmp obojeno
nebraon :

	mov ebx, 2
	cmp bx, ulazni
	jne necrvena
	mov cifra, 12
	jmp obojeno
necrvena :

	mov ebx, 3
	cmp bx, ulazni
	jne nenarandzasta
	mov cifra, 6
	jmp obojeno
nenarandzasta :

	mov ebx, 4
	cmp bx, ulazni
	jne nezuta
	mov cifra, 14
	jmp obojeno
nezuta :

	mov ebx, 5
	cmp bx, ulazni
	jne nezelena
	mov cifra, 2
	jmp obojeno
nezelena :

	mov ebx, 6
	cmp bx, ulazni
	jne neplava
	mov cifra, 9
	jmp obojeno
neplava :

	mov ebx, 7
	cmp bx, ulazni
	jne neljubicasta
	mov cifra, 5
	jmp obojeno
neljubicasta :

	mov ebx, 8
	cmp bx, ulazni
	jne nesiva
	mov cifra, 7
	jmp obojeno
nesiva :

	mov ebx, 9
	cmp bx, ulazni
	jne nebela
	mov cifra, 15
	jmp obojeno
nebela :

obojeno :

	ret
kodirajBoju endp

prikaziPrstenove proc c uses eax,
			arg1 : word, arg2 : word, arg3 : word, arg4 : word

	xor eax, eax
	xor ebx, ebx

	mov edx, offset str3
	call writestring

	mov ecx, 5

oboji :

	mov eax, 0
	call SetTextColor
	mov edx, offset str2
	call writestring

	mov bx, arg1
	mov eax, 16
	mul ebx
	add eax, ebx
	call SetTextColor
	mov edx, offset str1
	call writestring

	mov eax, 0
	call SetTextColor
	mov edx, offset str2
	call writestring

	mov bx, arg2
	mov eax, 16
	mul ebx
	add eax, ebx
	call SetTextColor
	mov edx, offset str1
	call writestring

	mov eax, 0
	call SetTextColor
	mov edx, offset str2
	call writestring

	mov bx, arg3
	mov eax, 16
	mul ebx
	add eax, ebx
	call SetTextColor
	mov edx, offset str1
	call writestring

	mov eax, 0
	call SetTextColor
	mov edx, offset str2
	call writestring

	mov bx, arg4
	mov eax, 16
	mul ebx
	add eax, ebx
	call SetTextColor
	mov edx, offset str1
	call writestring

	mov edx, offset str3
	call writestring

	dec ecx
	jnz oboji

	ret
prikaziPrstenove endp


main proc

	unesi_novu_vrednost: ;// stvorena petlja kako bi korisnik mogao da unosi nove vrednosti, bez stalnog gasenja i paljenja programa

	mov eax, 15 ;// kako bi tekst bio beo na crnoj pozadini
	call SetTextColor

	;// pocetne vrednosti prstenova na otporniku
	mov prsten1, 0
	mov prsten2, 0
	mov prsten3, 0
	mov prsten4, 0
	;// vrednost otpornosti i pomocne promenljive
	mov otpornost, 0
	mov pom, 0

	;// ciscenje registara
	xor eax, eax
	xor ebx, ebx
	xor edx, edx
	xor ecx, ecx

	;// ispisivanje poruke za unos i preuzimanje unete vrednosti
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov consoleHandle, eax

	INVOKE WriteConsole, consoleHandle, ADDR porUnosa, porUnDuz, ADDR ispisanoBY, 0

	INVOKE GetStdHandle, STD_INPUT_HANDLE
	mov consoleHandle, eax

	INVOKE ReadConsole, consoleHandle, ADDR buffer,
	BufSize, ADDR procitanoBY, 0

	;// duzina procitanog stringa umanjena za 2 simbola (0dh, 0ah), daje broj cifara
	mov eax, procitanoBY
	sub eax, 2
	mov procitanoBY, eax

	;//ako otpornost ima vise od 2 cifre, skace na obradu, ako nema, upisuje direktno vrednosti prstenova
	mov ebx, 2
	cmp eax, ebx
	jg vise_od_dve
	mov ebx, 1
	cmp eax, ebx
	je ima_jednu
	xor ebx, ebx
	mov bl, buffer[0]
	sub ebx, 48
	mov prsten2, bx
	mov bl, buffer[1]
	sub ebx, 48
	mov prsten3, bx
	jmp nemanula

ima_jednu:
	mov bl, buffer[0]
	sub ebx, 48
	mov eax, ebx
	jz kraj_rada ;//ukoliko je uneta vrednost otpornosti 0 oma, program se gasi
	mov prsten3, bx
	jmp nemanula
vise_od_dve:

	;//obrada ukoliko uneta otpornost ima vise od 2 cifre
	mov ecx, procitanoBY ;//zadaje se counter
	;// ideja ove petlje je citati cifru po cifru iz bafera i
	;// mnoziti svaku sa odgovarajucim stepenom 10, zatim sabirati
	;// da bi se na kraju dobila otpornost kao integer umesto stringa
petlja1:
	xor eax, eax
	xor ebx, ebx
	mov stepen10, 10
	mov ebx, procitanoBY
	sub ebx, ecx
	mov al, buffer[ebx]
	sub al, 48 ;// iz bafera je procitana prva cifra kao znak iz ASCII tabele, te je 
	;// neophodno oduzeti od procitane vrednosti 48 kako bi se dobila cifra
	mov cifra, eax ;// procitana cifra se upisuje u pomocnu promenljivu cifra
	push ecx ;// vrednost countera privremeno upisana na stack zbog promene istog 
	dec ecx
	mov eax, ecx
	jz poslCif
	mov eax, 1
	;// unutrasnja petlja za racunanje stepena 10 za svaku cifru
unutrasnjaP :
	mul stepen10
	loop unutrasnjaP
	mov stepen10, eax
	jmp sracunato
poslCif:
	mov stepen10, 1
sracunato :
	pop ecx
	mov ebx, stepen10
	mov eax, cifra
	mul ebx
	add otpornost, eax
	loop petlja1

	;//ako otpornost ima 3 cifre, skace na kraj
	mov eax, procitanoBY
	sub eax, 3
	jz kraj

	;// ako otpornost ima vise od 3 cifre, proverava je i trazi najblizu
	;// zamenu ukoliko uneta vrednost nije standardna

	mov ecx, procitanoBY
petlja2:
	xor eax, eax
	mov ebx, procitanoBY
	sub ebx, ecx
	add ebx, 3
	mov al, buffer[ebx];// cita cifru po cifru iz bafera(4. cifru, 5. cifru...) i svaku uporedjuje sa nulom
	sub al, 48
	jz ispravnaCif
	;// ukoliko neka od unetih cifara nakon prve 3 nije 0, ispisuje da uneta vrednost nije
	;// standardna i trazi najblizu zamenu
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov consoleHandle, eax

	INVOKE WriteConsole, consoleHandle, ADDR porLosaVr, porLVDuz, ADDR ispisBY, 0

	mov ecx, procitanoBY
	sub ecx, 3
	mov eax, 1
	mov ebx, 10
	;// odredjivanje stepena 10 npr za otpornost 12300 je 10^2, isto i za 12345
stepenpetlja:
	mul ebx
	loop stepenpetlja
	mov stepen10, eax
	mov eax, otpornost 
	div stepen10
	mul stepen10
	mov ebx, eax
	xor eax, eax
	xor edx, edx
	mov eax, stepen10
	shr eax, 1	;//zamena za eax/2
	add eax, ebx ;// ovim smo nasli otpornost 12350 za slucaj unete otpornosti 12300
	 ;// sada je neophodno uporediti da li je uneta otpornost veca ili manja od 12350
	 ;// i time dobijamo standardnu vrednost koja je najbliza unetoj

	sub eax, otpornost
	jle manjaje
	mov otpornost, ebx
	jmp losa_vrednost
manjaje:
	add ebx, stepen10
	mov otpornost, ebx
	jmp losa_vrednost

ispravnaCif:
	mov eax, ecx
	sub eax, 4
	jz kraj
	dec ecx
	mov eax, ecx
	jnz petlja2 ;//koriscen jump umesto loop jer je broj operacija u ovoj petlji prevelik za loop
				
losa_vrednost:
kraj:

	;// u ovom trenutku imamo standardnu vrednost otpornosti bilo da je takvu uneo
	;// korisnik ili je program morao da je prilagodi

	;// sada upisuje vrednost prve 3 cifre promenljive otpornik u promenljive 
	;// prsten1, prsten2, prsten3
	mov ecx,3
	mov eax, otpornost
	mov pomocna, eax
loopPrstena:
	;// prvo izvlaci cifru
	mov eax, 3
	sub eax, ecx
	jnz NPCifra
	mov cifra, 0
NPCifra:
	mov eax, procitanoBY
	mov ebx, 3
	sub ebx, ecx
	sub eax, ebx
	push ecx
	mov ecx, eax
	mov eax, 1
	mov ebx, 10
loopUnutr:
	mul ebx
	loop loopUnutr
	pop ecx
	mov stepen10, eax
	mul cifra
	mov ebx, pomocna
	sub ebx, eax
	mov pomocna, ebx
	mov eax, stepen10
	mov esi, 10
	div esi
	mov esi, eax
	mov eax, ebx
	mov ebx, esi
	div ebx
	mov cifra, eax

	;//sad upisuje cifru u prsten1, prsten2 ili prsten3
	mov ebx, 3
	sub ebx, ecx
	jnz nije_prva
	mov prsten1,ax
nije_prva:
	mov ebx, 2
	sub ebx, ecx
	jnz nije_druga
	mov prsten2, ax
nije_druga:
	mov prsten3, ax

	dec ecx
	jnz loopPrstena

	;//prsten4 se odredjuje zasebno
	mov eax, procitanoBY
	sub eax, 3
	jng nemanula
	mov prsten4, ax
nemanula:

	;// kodiranje boja zbog asemblera po tabeli datoj u izvestaju
	push prsten1
	call kodirajBoju ;// poziv procesa za kodiranje
	add esp, 2 ;// ciscenje stacka
	mov eax, cifra
	mov prsten1, ax

	push prsten2
	call kodirajBoju
	add esp, 2
	mov eax, cifra
	mov prsten2, ax

	push prsten3
	call kodirajBoju
	add esp, 2
	mov eax, cifra
	mov prsten3, ax

	push prsten4
	call kodirajBoju
	add esp, 2
	mov eax, cifra
	mov prsten4, ax

	;// vrednosti prstenova upisujemo na stack radi poziva procesa za iscrtavanje prstenova
	push pom
	push prsten4
	push pom
	push prsten3
	push pom
	push prsten2
	push pom
	push prsten1

	call prikaziPrstenove ;// poziv procesa za iscrtavanje
	add esp, 4 * 4 ;// ciscenje stacka 

	jmp unesi_novu_vrednost

kraj_rada:

	invoke ExitProcess,0
main endp
end main