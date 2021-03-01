.DATA
_2pi  DT 6.28318530717958647692528676656

.CODE
; функция, возвращающая 0
zero PROC;[+]
	xor rax, rax
	ret
zero ENDP

; Среднеквадратическое отклонение
rmse_asm PROC;[+]
local tmp:REAL8
local n:DWORD
	;rcx=массив 1
	;rdx=массив 2
	;r8=data_size=длина массива
	mov n, r8d
	finit
	fldz; загрузка нуля - начальное значение для суммы квадратов
	test r8d, r8d; проверка на пустой массив
	jz @exit

	@loop:;[
		fld QWORD PTR [rcx]
		fsub QWORD PTR [rdx]
		fmul st, st
		faddp st(1), st
		add rcx, 8
		add rdx, 8
		dec r8d
		jnz @loop;]
	fild n; загрузка длины массива	
	fdivp st(1), st;
	fsqrt

@exit:
	fstp tmp
	movsd xmm0,tmp
	ret
rmse_asm ENDP

; slow hartley transform
ht_asm PROC;[+]
local sqrtn:REAL10;
local _2pin:REAL10;
local k:DWORD;
local n:DWORD;
;
;rcx=data_in 
;rdx=data_out
;r8d=n
;
and r8, 0ffffffffh
mov n, r8d
mov r11, rcx;=data_in 
xor rcx, rcx;=счётчик
; n
mov r9, r8;
dec r9
shr r9, 1;

mov r10, r8;
sub r10, 2;
shl r10, 3;

;
finit
fld _2pi
fild n
fdivp st(1), st
fstp _2pin
;
fld1
fild n
fsqrt
fdivp st(1),st
;
mov rax, r11;=data_in 
mov rcx, r8;

fldz;                     2~| sqrtn | 0 |
@loop0:;[
	fadd QWORD PTR [rax]; 2~| sqrtn | 0+[rax] |
	add rax, 8;
	loop @loop0;]
fmul st, st(1)
fstp QWORD PTR [rdx];     0~||
fstp sqrtn
add rdx, 8;

mov k, 1;
@loop1:;[
	mov rax, r11;
	fld QWORD PTR [rax];=sub; 1~| sub |
	fld st(0);=sum;           2~| sub | sum |
	add rax, 8;
	fld _2pin;                3~| sub | sum | 2pi/n |

	fild k;                   4~| sub | sum | 2pi/n | k |
	fmulp st(1),st;=w;        3~| sub | sum | w |
	fsincos;                  4~| sub | sum | sin(w) | cos(w) |

	fld1;=u;                  5~| sub | sum | sin(w) | cos(w) | u |
	fldz;=v;                  6~| sub | sum | sin(w) | cos(w) | u | v |

	mov rcx, r8;
	dec rcx
	@loop2:;[
		fld st(1);                7~| sub | sum | sin(w) | cos(w) | u | v | u |
		fmul st(0),st(4);         7~| sub | sum | sin(w) | cos(w) | u | v | u*sin(w) |
		fld st(1);                8~| sub | sum | sin(w) | cos(w) | u | v | u*sin(w) | v |
		fmul st,st(4);            8~| sub | sum | sin(w) | cos(w) | u | v | u*sin(w) | v*cos(w) |
		faddp st(1),st;           7~| sub | sum | sin(w) | cos(w) | u | v | u*sin(w)+v*cos(w) |
		fxch st(1);=v`;           7~| sub | sum | sin(w) | cos(w) | u | v` | v |
		fmul st, st(4);           7~| sub | sum | sin(w) | cos(w) | u | v` | v*sin(w) |
		fxch st(2);               7~| sub | sum | sin(w) | cos(w) | v*sin(w) | v` | u |
		fmul st,st(3);            7~| sub | sum | sin(w) | cos(w) | v*sin(w) | v` | u*cos(w) |
		fsubrp st(2),st;=u`;      6~| sub | sum | sin(w) | cos(w) | u` | v` |
		
		fld st(0);                7~| sub | sum | sin(w) | cos(w) | u` | v` | v` |
		fadd st, st(2);           7~| sub | sum | sin(w) | cos(w) | u` | v` | v`+u` |
		fmul QWORD PTR [rax];=a;  7~| sub | sum | sin(w) | cos(w) | u` | v` | a |
		faddp st(5),st;           6~| sub | sum+a | sin(w) | cos(w) | u` | v` |
		
		fld st(0);                7~| sub | sum+a | sin(w) | cos(w) | u` | v` | v` |
		fsubr st, st(2);          7~| sub | sum+a | sin(w) | cos(w) | u` | v` | u`-v` |
		fmul QWORD PTR [rax];=b;  7~| sub | sum+a | sin(w) | cos(w) | u` | v` | b |
		faddp st(6),st;           6~| sub+b | sum+a | sin(w) | cos(w) | u` | v` |
		
		add rax, 8;
		loop @loop2;]
	
	fcompp;                   4~| sub+b | sum+a | sin(w) | cos(w) |
	fcompp;                   2~| sub+b | sum+a |
	fld sqrtn;                3~| sub+b | sum+a | sqrtn
	fmul st(1), st;           3~| sub+b | (sum+a)*sqrtn | sqrtn
	fxch st(1);               3~| sub+b | sqrtn | (sum+a)*sqrtn
	fstp QWORD PTR [rdx];     2~| sub+b | sqrtn |
	fmulp st(1), st;		  1~| (sub+b)*sqrtn |
	fstp QWORD PTR [rdx+r10]; 0~||
	;
	add rdx,8;
	sub r10, 16;
	inc k;
	dec r9;
	jnz @loop1;]

test r10, r10
jnz @exit

mov rax, r11;
fldz
mov rcx, r8;
shr rcx, 1

@loop3:;[
	fadd QWORD PTR [rax]
	fsub QWORD PTR [rax+8]
	add rax, 16
	loop @loop3;]
fld sqrtn
fmulp st(1), st
fstp QWORD PTR [rdx]

@exit:
ret
ht_asm ENDP
;------------
;------------
END