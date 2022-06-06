.model SMALL
.stack 100h
.data
current_level db 31h
keyUP equ 48h
keyDOWN  equ 50h
keyLEFT  equ 4bh
keyRIGHT equ 4dh
keyEXIT  equ 01h
FIELD_WIDTH equ 80
FIELD_UPPER_BOUND equ 2
FIELD_LOWER_BOUND equ 21

COLOR_TRAIL  equ 01100111b ;7e
COLOR_uSEA equ 00010011b
COLOR_PIRATE equ 00000100b ;19
COLOR_SHIP   equ 01100000b ;31
SYMBOL_SHIP db 31
SYMBOL_PIRATE db 3
SYMBOL_FIELD db 178
SYMBOL_TRAIL db 177
SYMBOL_uFIELD db 176

uScale dw 0000
SHIP_startX db 78
SHIP_startY db 2
SHIP_currX  db 0
SHIP_currY  db 0
SHIP_DIRECTION db 0 ;0 nothing, 1 high 2 down 3 right 4 left

PIRATE1_startX db 78
PIRATE1_startY db 5
PIRATE1_currX  db 0
PIRATE1_currY  db 0
PIRATE1_DIRECTION dw 0101h ;hb 01 - high lb 01 - left 

PIRATE2_startX db 18
PIRATE2_startY db 10
PIRATE2_currX  db 0
PIRATE2_currY  db 0
PIRATE2_DIRECTION dw 0FE01h ;hb 01 - high lb 01 - left 

PIRATES_DELAY dw 0003h
SCREEN_MSG db " >control: ", 24,' ',25, ' ',26,' ',27
db " >level "
db " >esc for exit"
db "3.14% of sailors are Pi Rates"  
MSG_win  db "NICE"
MSG_loss db "WASTED"
FLAG_WIN db 02h
FLAG_SHIP_ON_BOUND dw 0000h
FLAG_TRAIL_ON_TRAIL db 00h
.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkForFill proc
xor ax,ax
mov bl,SHIP_currX
mov bh,SHIP_currY
mov al,FIELD_WIDTH*2
mul bh
mov cl,bl
add ax,cx
mov di,ax
mov ax,es:[di]
cmp ah,COLOR_uSEA
jne noEndSea
call fillField
noEndSea:
ret
checkForFill endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkHigh_or_LowFigure proc
push di ;start line high for low
xor bx,bx
mov dl,1
checkRectLike:
add di,160
checkRectLike_loop:
add di,2
mov ax,es:[di]
cmp ah,COLOR_TRAIL
je startPrint
cmp ah,COLOR_uSEA
je checkLowFigure
jmp checkRectLike_loop
checkLowFigure:
pop di
push di
lowFigure_loop:
inc bl
mov ax,es:[di+160]
cmp ah,COLOR_TRAIL
je startPrint
cmp ah,COLOR_uSEA
je checkHighFigure
add di,160
jmp lowFigure_loop
checkHighFigure:
pop di
push di
highFigure_loop:
inc bh
mov ax,es:[di-160]
cmp ah,COLOR_uSEA
je high_or_low
sub di,160
jmp highFigure_loop
high_or_low:
cmp bl,bh
jbe lowFigure
highFigure:
pop si
push di
jmp startPrint
lowFigure:
mov cx,99
startPrint:
pop di
;sub di,2
call printArea
ret
checkHigh_or_LowFigure endp
;;;;;;;;;;;;;;;;
printArea proc
;di - current position high dot
;dl - dirrection (1 left, 0 right)
xor bx,bx
push cx
cmp dl,1
je rightF
leftF:
mov ax,es:[di+160]
cmp ah,COLOR_TRAIL
jne printArea_loop
sub di,2
jmp toHighPos
rightF:
mov ax,es:[di+160]
cmp ah,COLOR_TRAIL
jne printArea_loop
add di,2
toHighPos:
mov ax,es:[di]
cmp ah,COLOR_TRAIL
je printArea_loop
toHighPos_loop:
mov ax,es:[di-160]
cmp ah,COLOR_TRAIL
je printArea_loop
cmp ah,COLOR_uSEA
je printArea_loop
sub di,160
jmp toHighPos_loop
printArea_loop:
mov al,44
mov ah,COLOR_TRAIL
mov cx,2
stosw
sub di,2
mov ax,es:[di+160]
cmp al,SYMBOL_PIRATE
je PIRATE_HERE
cmp ah,COLOR_uSEA
je nextColumn
cmp ah,COLOR_TRAIL
je nextColumn
add di,160
jmp printArea_loop
nextColumn:
call left_right_mov
highLine:
mov ax,es:[di]
cmp al,SYMBOL_PIRATE
je PIRATE_HERE
cmp ah,COLOR_uSEA
je checkFreeSpace
cmp ah,COLOR_TRAIL
je noPirate
highLine_loop:
mov ax,es:[di-160]
cmp al, SYMBOL_PIRATE
je PIRATE_HERE
cmp ah,COLOR_uSEA
je printArea_loop
cmp ah,COLOR_TRAIL
je printArea_loop
sub di,160
jmp highLine_loop

checkFreeSpace:
pop cx
push cx
cmp cx,99
je noPirate
mov ax,es:[di]
cmp al, SYMBOL_FIELD
je noPirate
cmp al, SYMBOL_PIRATE
je PIRATE_HERE
cmp al,' '
je highLine_loop
sub di,160
jmp checkFreeSpace
Pirate_here:
call removeAllTrail
mov dx,0
jmp endPrint
noPirate:
call imposterCheck
cmp dl,99
je Pirate_here
call printAllTrail
endPrint:
pop cx
ret
printArea endp
;;;;;;;;;;;;;;;;;;;;;
left_right_mov proc
cmp dl,1
je rightO
leftO:
sub di,2
jmp exit_proc
rightO:
add di,2
exit_proc:
ret
left_right_mov endp
;;;;;;;;;;;;;;;;;;;;;;
imposterCheck proc
;dl - diraction
xor cx,cx
xor bx,bx
cmp dl,1
je r_ight
mov di,FIELD_WIDTH*8+144
push di
jmp imposterCheck_loop
PITRATE_AAA:
mov dl,99
jmp endImposter
r_ight:
mov di,FIELD_WIDTH*8+16
push di
imposterCheck_loop:
mov ax,es:[di]
cmp ch,1
jne search_start
cmp ah,COLOR_uSEA
je changePrintFlag
cmp al,SYMBOL_TRAIL
jne imposterORnot
mov ax,es:[di+2]
cmp al,SYMBOL_TRAIL
je changePrintFlag
mov ax,es:[di-2]
cmp al,SYMBOL_TRAIL
je changePrintFlag
cmp cl,0
jne changePrintFlag
jmp n_ext
imposterORnot:
inc cl
cmp al,3
je PITRATE_AAA
cmp al,' '
jne n_ext
push cx
mov al,42
mov ah,COLOR_TRAIL
mov cx,2
stosw
pop cx
sub di,2
jmp n_ext
changePrintFlag:
mov ch,0
mov cl,0
jmp c_olumn
search_start:
cmp al,SYMBOL_TRAIL
jne n_ext
mov ch,1
n_ext:
call left_right_mov
mov ax,es:[di]
cmp al,SYMBOL_FIELD
je c_olumn
cmp al,44
jne imposterCheck_loop
cmp ch,0
je c_olumn
jmp imposterCheck_loop
c_olumn:
mov ch,0
mov cl,0
inc bx
pop di
add di,160
xor cx,cx
push di
mov ax,es:[di]
cmp al,44
je c_olumn
cmp bx,16
je endImposter
jmp imposterCheck_loop 
endImposter:
pop di
ret
imposterCheck endp
;;;;;;;;;;;;;;;;;;;;;;
printAllTrail proc
xor ax,ax
xor dx,dx
mov di,FIELD_WIDTH*8
add di,4
printTrail_loop:
mov ax,es:[di]
cmp ah,COLOR_TRAIL
jne nextSymb
inc dx
mov al,SYMBOL_uFIELD
mov ah,COLOR_uSEA
mov cx,2
stosw
jmp endFieldCheck
nextSymb:
add di,2
endFieldCheck:
cmp di,3360
jne printTrail_loop
ret
printAllTrail endp
;;;;;;;;;;;;;;;;;;;;;;;;;;

checkRight_or_LeftFigure proc
xor bx,bx
mov si,di
push di
checkLeftSize_loop:
inc bl
sub di,2
mov ax,es:[di-2]
cmp ah,COLOR_uSEA
je checkRightSize_loop
cmp ah,COLOR_TRAIL
je leftOne
nexAreaSymbol_L:
jmp checkLeftSize_loop

checkRightSize_loop:
inc bh
add si,2
mov ax,es:[si+2]
cmp ah,COLOR_uSEA
je compareSizes
cmp ah,COLOR_TRAIL
je rightOne
jmp checkRightSize_loop
compareSizes:
cmp bh,bl
jbe rightOne
leftOne:
mov dl,0
jmp endCheckSize
rightOne:
mov dl,1
mov di,si
endCheckSize:
pop di
ret
checkRight_or_LeftFigure endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;
removeAllTrail proc
xor ax,ax
mov di,FIELD_WIDTH*8
add di,4
removeTrail_loop:
mov ax,es:[di]
cmp ah,COLOR_TRAIL
jne nextScanSymb
mov al,' '
mov ah,00h
mov cx,2
stosw
jmp endFieldScan
nextScanSymb:
add di,2
endFieldScan:
cmp di,3360
jne removeTrail_loop
ret
removeAllTrail endp
;;;;;;;;;;;;;;;;;;;;;;;;;;
fillField proc
;bh - y bl - x
mov ch,FLAG_TRAIL_ON_TRAIL
cmp ch,1
jne fillSq
mov ch,0
mov FLAG_TRAIL_ON_TRAIL,ch
call removeAllTrail
jmp endFill
fillSq:
xor ax,ax
mov bh,4
mov bl,10
mov di,FIELD_WIDTH*8
add di,4
push di
searchTrailLine_loop:
mov ax,es:[di]
cmp ah,COLOR_TRAIL
jne next
jmp checkTrailDiraction
next:
add bl,2
cmp bl,146
jne nextSymbol
pop di
add di,160
push di
inc bh
mov bl,6
nextSymbol:
add di,2
jmp searchTrailLine_loop
checkTrailDiraction:
pop si ;for correct ret
push di ;FIRST MEET
mov ax,es:[di+160] ;if no down line
cmp ah,COLOR_TRAIL
jne noDownTrail
mov dl,0
downDir_loop:
add di,160
mov ax,es:[di+160] 
cmp ah,COLOR_TRAIL
je downDir_loop
;stop down
mov ax,es:[di+2] 
cmp ah,COLOR_TRAIL
je rightDir_loop
mov ax,es:[di-2] 
cmp ah,COLOR_TRAIL
je leftDir_loop
jmp checkSize

leftDir_loop:
sub di,2
mov ax,es:[di-2] 
cmp ah,COLOR_TRAIL
je leftDir_loop
mov dl,0
mov ax,es:[di+160] 
cmp ah,COLOR_TRAIL 
je downDir_loop
jmp tohighPosition
rightDir_loop:
add di,2
mov ax,es:[di+2] 
cmp ah,COLOR_TRAIL
je rightDir_loop
mov dl,1
mov ax,es:[di+160] 
cmp ah,COLOR_TRAIL 
je downDir_loop
jmp tohighPosition

checkSize:
call checkRight_or_LeftFigure
startPrintArea:
pop di ;first meet (high dot)
call printArea
mov ax,uScale
add ax,dx
mov uScale,ax
jmp endFill
noDownTrail:
call checkHigh_or_LowFigure 
mov ax,uScale
add ax,dx
mov uScale,ax
pop si
jmp endFill
tohighPosition:
mov ax,es:[di-160]
cmp ah,COLOR_TRAIL
je startPrintArea
cmp ah,COLOR_uSEA
je startPrintArea
sub di,160
jmp tohighPosition
endFill:
ret
fillField endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkScale proc
xor cx,cx
mov ax,uScale
cmp ax,931
jbe noWin
mov ax,0
mov uScale,ax
mov cl,01h
mov FLAG_WIN,cl
noWin:
ret
checkScale endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
printMSG proc
print_loop: 
lodsb
stosw
loop print_loop
ret
printMSG endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawField proc
mov al,SYMBOL_FIELD
mov ah,COLOR_uSEA
mov cx,FIELD_WIDTH-11
mov di, FIELD_WIDTH*4+12
cld
rep stosw
mov cx,FIELD_WIDTH-11
mov di, FIELD_WIDTH*6+12
cld
rep stosw

mov cx,FIELD_WIDTH-11
mov di, FIELD_WIDTH*40+12
cld
rep stosw
mov cx,FIELD_WIDTH-11
mov di, FIELD_WIDTH*42+12
cld
rep stosw
mov bx,FIELD_WIDTH*6
add bx,12
left:
add bx,160
mov cx,2
mov di,bx
cld
rep stosw
cmp bx,FIELD_WIDTH*40+12
jne left

mov bx,FIELD_WIDTH*4
right:
add bx,146
mov cx,2
mov di,bx
cld
rep stosw
add bx,14
cmp bx,FIELD_WIDTH*40
jne right

mov si,offset SCREEN_MSG
mov cx,18
mov di,FIELD_WIDTH*44
mov ah,02h
call printMSG
mov cx,8
mov di,FIELD_WIDTH*46
call printMSG
mov al, current_level
mov cx,1
stosb
mov cx,14
mov di,FIELD_WIDTH*48
call printMSG
mov ah,01101111b

mov cx,29
mov di, 252
call printMSG
ret
drawField endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawELEMENT proc ;bl - currX bh - currY   dh-color dl-symb
xor ax,ax 
mov al,FIELD_WIDTH*2
mul bh
mov cl,bl
add ax,cx
mov di,ax
mov ax,dx ;достали цвет и символ
mov cx,2
stosw
ret
drawELEMENT endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1

pirateMove proc
;dl - dir bl - x bh - y
;hb fe - high lb fe - left
getNewPositionInformation:
xor ax,ax 
xor cx,cx
mov al,FIELD_WIDTH*2
mul bh
mov cl,bl
add ax,cx
mov di,ax
HorizontalMovement:
cmp dh,01
jne moveUp
inc bh
add di,FIELD_WIDTH*2
mov ax,es:[di]
jmp checkHorizontalMovement
moveUp:
dec bh
sub di,FIELD_WIDTH*2
mov ax,es:[di]
checkHorizontalMovement:
cmp ah,COLOR_TRAIL
je killUser
cmp ah,COLOR_uSEA
jne VerticalMovement
changeHorizontalMovement:
cmp dh,01
jne changeUp2Down
sub bh,2
sub di,FIELD_WIDTH*4
not dh
jmp VerticalMovement
changeUp2Down:
add bh,2
add di,FIELD_WIDTH*4
not dh
VerticalMovement:
cmp dl,01
jne moveLeft
add bl,2
mov ax,es:[di+2]
jmp checkVerticalMovement
moveLeft:
sub bl,2
mov ax,es:[di-2]
checkVerticalMovement:
cmp ah,COLOR_TRAIL
je killUser
cmp ah,COLOR_uSEA
jne endCheck
changeVerticalMovement:
cmp dl,01
jne changeLeft2Right
sub bl,4
not dl
jmp endCheck
changeLeft2Right:
add bl,4
not dl
jmp endCheck
killUser:
mov al,00
mov FLAG_WIN,al
endCheck:

ret
pirateMove endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Pirates proc
mov ah,00
int 1ah
cmp dx,PIRATES_DELAY
jb noPirateMove
call zeroizeCounter
call getPiratesPosition
call drawPirates
noPirateMove:
ret
Pirates endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
getPiratesPosition proc
mov dx,PIRATE1_DIRECTION
mov bl,PIRATE1_currX
mov bh,PIRATE1_currY
push bx
call pirateMove
mov PIRATE1_DIRECTION,dx
mov PIRATE1_currX,bl
mov PIRATE1_currY,bh
pop bx
mov dl,' '
mov dh,0h
call drawELEMENT
mov dx,PIRATE2_DIRECTION
mov bl,PIRATE2_currX
mov bh,PIRATE2_currY
push bx
call pirateMove
mov PIRATE2_DIRECTION,dx
mov PIRATE2_currX,bl
mov PIRATE2_currY,bh
pop bx
mov dl,' '
mov dh,0h
call drawELEMENT
ret
getPiratesPosition endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawPirates proc
mov dh,COLOR_PIRATE
mov dl,SYMBOL_PIRATE
mov bl,PIRATE1_currX
mov bh,PIRATE1_currY
call drawELEMENT

mov dh,COLOR_PIRATE
mov dl,SYMBOL_PIRATE
mov bl,PIRATE2_currX
mov bh,PIRATE2_currY
call drawELEMENT
ret
drawPirates endp

moveShip proc
;0 nothing, 1 high 2 down 4 right 3 left
mov bl,SHIP_currX
mov bh,SHIP_currY
mov ax, FLAG_SHIP_ON_BOUND
cmp al,SYMBOL_uFIELD
jne nextMoveStep
conqueredTerritory:
mov dl,SYMBOL_uFIELD
mov dh,COLOR_uSEA
call drawELEMENT
nextMoveStep:
mov dl,SHIP_DIRECTION
push bx
cmp dl,0
jne upMove
pop bx
jmp endMoveProc
upMove:
cmp dl,1
jne downMove
cmp bh,FIELD_UPPER_BOUND
je noMove
dec bh
mov SHIP_currY,bh
jmp draw_uTrace
downMove:
cmp dl,2
jne leftMove
cmp bh,FIELD_LOWER_BOUND
je noMove
inc bh
mov SHIP_currY,bh
jmp draw_uTrace
leftMove:
cmp dl,3
jne rightMove
cmp bl,12
je noMove
sub bl,2
mov SHIP_currX,bl
jmp draw_uTrace
rightMove:
cmp bl,148
je noMove
add bl,2
mov SHIP_currX,bl
jmp draw_uTrace
noMove:
mov dl,00
mov SHIP_DIRECTION,dl
draw_uTrace:
xor cx,cx
xor ax,ax
mov al,FIELD_WIDTH*2
mul bh
mov cl,bl
add ax,cx
mov di,ax
mov cx,es:[di]
mov FLAG_SHIP_ON_BOUND,cx
cmp ch,COLOR_TRAIL
jne uTrail
mov ah,1
mov FLAG_TRAIL_ON_TRAIL,ah
uTrail:
pop bx
xor ax,ax 
xor cx,cx
mov al,FIELD_WIDTH*2
mul bh
mov cl,bl
add ax,cx
mov di,ax
mov ax,es:[di]
cmp ah, COLOR_uSEA
je endMoveProc
mov dl,SYMBOL_TRAIL
mov dh,COLOR_TRAIL
call drawELEMENT
call checkForFill
jmp endMoveProc
endMoveProc:
ret
moveShip endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

userAction proc
highDirection:
cmp ah,keyUP
jne lowDirection
mov dl,1
mov SHIP_DIRECTION,dl
jmp endHandling
lowDirection:
cmp ah,keyDOWN
jne leftDirection
mov dl,2
mov SHIP_DIRECTION,dl
jmp endHandling
leftDirection:
cmp ah,keyLEFT
jne rightDirection
mov dl,3
mov SHIP_DIRECTION,dl
jmp endHandling
rightDirection:
cmp ah,keyRIGHT
jne endHandling
mov dl,4
mov SHIP_DIRECTION,dl
endHandling:
ret
userAction endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
zeroizeCounter proc
mov cx,0
mov dx,0
mov ah,01h
int 1ah
ret
zeroizeCounter endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
crashCheck proc
jmp crashTest
deathFlag:
mov al,00
mov FLAG_WIN,al
jmp endCrashTest
crashTest:
xor ax,ax
xor cx,cx
mov bl,SHIP_currX
mov bh, SHIP_currY
mov al,FIELD_WIDTH*2
mul bh
mov cl,bl
add ax,cx
mov di,ax

mov bl,PIRATE1_currX
mov bh,PIRATE1_currY
xor ax,ax

mov al,FIELD_WIDTH*2
mul bh
mov cl,bl
add ax,cx
mov si,ax

mov bl,PIRATE2_currX
mov bh,PIRATE2_currY

xor ax,ax

mov al,FIELD_WIDTH*2
mul bh
mov cl,bl
add ax,cx
mov dx,ax

cmp di,si
je deathFlag
cmp di,dx
je deathFlag
endCrashTest:
ret
crashCheck endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:  
mov ax,@data
mov ds,ax
mov ax, 0b800h
mov es, ax

newGame:
mov ax,3
int 10h
mov al,03h
mov FLAG_WIN,al
mov al,SHIP_startX
mov SHIP_currX,al
mov al,SHIP_startY
mov SHIP_currY,al
mov al,0
mov SHIP_DIRECTION,al
mov al,PIRATE1_startX
mov PIRATE1_currX,al
mov al,PIRATE1_startY
mov PIRATE1_currY,al

mov al,PIRATE2_startX
mov PIRATE2_currX,al
mov al,PIRATE2_startY
mov PIRATE2_currY,al
call zeroizeCounter
call drawPirates
startGame:
call drawField
call moveShip
mov dh,COLOR_SHIP
mov dl,SYMBOL_SHIP
mov bl,SHIP_currX
mov bh,SHIP_currY
call drawELEMENT
call Pirates
mov ah,FLAG_WIN
cmp ah,00h
je EndGame
shipDelay:
mov dx,0fde8h
mov ah,86h
mov cx,0
int 15h 
call crashCheck
mov ah,FLAG_WIN
cmp ah,00h
je EndGame
call checkScale
cmp cl,01h
je nextLevel
mov ah,1
int 16h
jz startGame
xor ah,ah               
int 16h                     
cmp ah,keyEXIT
je EXIT
cmp ah,11h
je nextLevel
call userAction
jmp startGame

nextLevel:
mov al,current_level
cmp al,33h
je EndGame
inc al
mov current_level,al
mov bx,PIRATES_DELAY
cmp al,32h
jne hardMode
sub bx,2h
mov PIRATES_DELAY,bx
jmp newGame
hardMode:
sub bx,1h
mov PIRATES_DELAY,bx
jmp newGame


EndGame:
xor ax,ax
mov cx,160
mov al, ' '
mov di,FIELD_WIDTH*24
mov ah,01001000b
cld
rep stosb
mov al,FLAG_WIN
cmp al,0
jne userWin
userLose:
mov si,offset MSG_loss
mov cx,6
mov di,FIELD_WIDTH*24+74
mov ah,024h
call printMSG
mov ah,1h
int 21h
jmp EXIT

userWin:
mov si,offset MSG_win
mov cx,4
mov di,FIELD_WIDTH*24+76
mov ah,02Fh
call printMSG
mov ah,1h
int 21h
EXIT:
xor ax,ax
mov ax,3
int 10h
mov ah,4ch
int 21h
end start
