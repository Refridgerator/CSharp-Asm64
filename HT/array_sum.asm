.DATA
; ��� ���������� �� ������������, ��������� ������ ��� �������
; ���������� ��������� � ����� ������
;const_byte byte 255; ��� db
;const_word word 65535; ��� dw
;const_dword dword 4294967295; ��� dd
;const_single real4 1.0; ��� dd
;const_double real8 1.0;��� qword ��� dq
;const_extdouble real10 1.0;��� tword ��� dt
;const_128bit oword 0
;; �������
;word_array WORD 1,2,3,4
;dword_array DWORD 4 dup (?) ; �������������������� ������

.CODE

; ����� �������
array_sum_fpu PROC;[+]
	local tmp:qword; ��������� ����������, ���������� � �����
	;rdx=������ �� ������� ������� �������� �������
	;rcx=����� �������� �������

	fldz; �������� ���� � ���� FPU - ��������� �������� ��� �����

	test rcx, rcx; �������� �� ������� �����
	jz @exit

	@loop:;[ do ... while (rcx>0)
		fadd QWORD PTR [rdx]
		add rdx, 8; ������� �� ��������� ������� �������, 8 ��� sizeof(double)
		dec rcx
		jnz @loop;
		;]
@exit:
	fstp QWORD PTR tmp
	movupd xmm0, QWORD PTR tmp
	ret
array_sum_fpu ENDP


; ����� ������� c ��������������� ����� � 8 ���
array_sum_fpu_unrolled PROC;[+]
local tmp:qword; ��������� ����������, ���������� � �����
	;rdx=������ �� ������� ������� �������� �������
	;rcx=����� �������� �������

	fldz; �������� ���� � ���� FPU - ��������� �������� ��� �����

	cmp rcx, 8
	jl @step2; ���������� ������ ����, ���� ����� ������� ������ ������

	; ���� 1 - ������������ �� 8 ����� �� ����
	mov rax, rcx;= ������� �����
	and rax, -8; ���������� ���� �� ��������, �������� 8
	@loop1:;[
		fadd QWORD PTR [rdx]
		fadd QWORD PTR [rdx+8*1]
		fadd QWORD PTR [rdx+8*2]
		fadd QWORD PTR [rdx+8*3]
		fadd QWORD PTR [rdx+8*4]
		fadd QWORD PTR [rdx+8*5]
		fadd QWORD PTR [rdx+8*6]
		fadd QWORD PTR [rdx+8*7]
		add rdx, 8*8; ������� �� ��������� 8 ��������� �������
		dec rax
		jnz @loop1
		;]
	; ���� 2 - ������������ ��������
	@step2:
	and rcx, 7; ������� ����� �� ������� �� 8
	;rcx ������ ������� �����
	test rcx, rcx; �������� �� ����
	jz @exit
	
	@loop2:;[
		fadd QWORD PTR [rdx]
		add rdx, 8; ������� �� ��������� ������� �������
		dec rcx
		jnz @loop2; 
		;]
@exit:
	fstp QWORD PTR tmp
	movupd xmm0, QWORD PTR tmp
	ret
array_sum_fpu_unrolled ENDP


array_sum_fpu_dynamic_jump PROC uses rdx rdi data:PTR QWORD, data_size:QWORD;[+]
	local tmp:qword; ��������� ����������, ���������� � �����
	;rdx=������ �� ������� ������� �������� �������
	;rcx=����� �������� �������

	fldz; �������� ���� � ���� FPU - ��������� �������� ��� �����

	cmp rcx, 16
	jl @step2; ���������� ������ ����, ���� ����� ������� ������ 16

	mov rax, rcx
	shr rax, 4; ������� �� 16

	; ���� 1 - ������������ �� 16 ����� �� ����
	@loop1:;[
		fadd QWORD PTR [rdx]
		fadd QWORD PTR [rdx+8*1]
		fadd QWORD PTR [rdx+8*2]
		fadd QWORD PTR [rdx+8*3]
		fadd QWORD PTR [rdx+8*4]
		fadd QWORD PTR [rdx+8*5]
		fadd QWORD PTR [rdx+8*6]
		fadd QWORD PTR [rdx+8*7]
		fadd QWORD PTR [rdx+8*8]
		fadd QWORD PTR [rdx+8*9]
		fadd QWORD PTR [rdx+8*10]
		fadd QWORD PTR [rdx+8*11]
		fadd QWORD PTR [rdx+8*12]
		fadd QWORD PTR [rdx+8*13]
		fadd QWORD PTR [rdx+8*14]
		fadd QWORD PTR [rdx+8*15]
		add rdx, 16*8; ������� �� ��������� 16 ��������� �������
		dec rax
		jnz @loop1
		;]
	; ���� 2 - ������������ ��������
	@step2:
	and rcx, 15; ������� ����� �� ������� �� 16
	lea rdx, [rdx+rcx*8]; ���������� � rdx ����� ���������� �� ��������� ���������, ����� ��������������� �� ���� � �������� �������
	lea rcx, [rcx+rcx*2]; ��������� rcx �� 3, ��� 3 - ������ ���������� fadd � ������ (��� ������������� ��������� ��������)
	call @next
	@next: pop rax; ��������� ������ ������� ����������
	sub rax, rcx
	add rax, 15*3+10; 10 - ��� ����� � ������ ���������� pop/sub/add/jmp
	jmp rax; ������� �� ����������� ��������������� ������
	;
	fadd QWORD PTR [rdx-8*15]
	fadd QWORD PTR [rdx-8*14]
	fadd QWORD PTR [rdx-8*13]
	fadd QWORD PTR [rdx-8*12]
	fadd QWORD PTR [rdx-8*11]
	fadd QWORD PTR [rdx-8*10]
	fadd QWORD PTR [rdx-8*9]
	fadd QWORD PTR [rdx-8*8]
	fadd QWORD PTR [rdx-8*7]
	fadd QWORD PTR [rdx-8*6]
	fadd QWORD PTR [rdx-8*5]
	fadd QWORD PTR [rdx-8*4]
	fadd QWORD PTR [rdx-8*3]
	fadd QWORD PTR [rdx-8*2]
	fadd QWORD PTR [rdx-8*1]

@exit:
	fstp QWORD PTR tmp
	movupd xmm0, QWORD PTR tmp
	ret
array_sum_fpu_dynamic_jump ENDP


; ����� �������, ���������������� ��� sse2
array_sum_sse PROC;[+]

	;rdx=������� ������� � �������
	;rcx=����� �������� �������

	; ��������������� ��������� ���������
	vzeroupper
	xorpd xmm0, xmm0
	xorpd xmm1, xmm1

	cmp rcx, 16
	jl @step2

	; ���� 1 - ������������ �� 16 ����� �� ����
	mov rax, rcx
	shr rax, 4; ������� �� 16
	
	@loop:;[
		; �������� xmm0 � xmm1 ����������, ����� ���������� ����������� ����������
		addpd xmm0, [rdx]
		addpd xmm1, [rdx+2*8]
		addpd xmm0, [rdx+4*8]
		addpd xmm1, [rdx+6*8]
		addpd xmm0, [rdx+8*8]
		addpd xmm1, [rdx+10*8]
		addpd xmm0, [rdx+12*8]
		addpd xmm1, [rdx+14*8]
		add rdx, 16*8; ������� �� ��������� 16 ��������� �������
		dec rax
		jnz @loop
		;]	
	; ���� 2 - ������������ ��������
	@step2:
	and rcx, 15; ������� ����� �� ������� �� 16
	lea rdx, [rdx+rcx*8]; ���������� � rdx ����� ���������� �� ��������� ���������, ����� ��������������� �� ���� � �������� �������
	lea rcx, [rcx+rcx*4]; rcx*=5, ��� 5 - ������ ���������� addsd � ������
	call @next
	@next: pop rax; ��������� ������ ������� ����������
	sub rax, rcx
	add rax, 15*5+10
	jmp rax; ������� �� ����������� ��������������� ������
	;
	addsd xmm0, QWORD PTR [rdx-8*15]
	addsd xmm1, QWORD PTR [rdx-8*14]
	addsd xmm0, QWORD PTR [rdx-8*13]
	addsd xmm1, QWORD PTR [rdx-8*12]
	addsd xmm0, QWORD PTR [rdx-8*11]
	addsd xmm1, QWORD PTR [rdx-8*10]
	addsd xmm0, QWORD PTR [rdx-8*9]
	addsd xmm1, QWORD PTR [rdx-8*8]
	addsd xmm0, QWORD PTR [rdx-8*7]
	addsd xmm1, QWORD PTR [rdx-8*6]
	addsd xmm0, QWORD PTR [rdx-8*5]
	addsd xmm1, QWORD PTR [rdx-8*4]
	addsd xmm0, QWORD PTR [rdx-8*3]
	addsd xmm1, QWORD PTR [rdx-8*2]
	addsd xmm0, QWORD PTR [rdx-8*1]
	;
	addpd xmm0, xmm1
	; �������� ����� �� xmm0 
	movupd xmm1, xmm0
	shufpd xmm1,xmm1,1
	addpd xmm0,xmm1
	;
@exit:
	ret
array_sum_sse ENDP


; ����� �������, ���������������� ��� avx
array_sum_avx PROC;[+]

	;rdx=������� ������� � �������
	;rcx=����� �������� �������

	; ��������������� ��������� ���������
	vxorpd ymm0, ymm0, ymm0
	vxorpd ymm1, ymm1, ymm1

	cmp rcx, 64
	jl @step2; ������� �� ��������� ����, ���� � ������� ������ 64 �����

	; ���� 1 - ������������ �� 64 ����� �� ����
	sub rcx, 64
	@loop:;[
		vaddpd ymm0, ymm0, [rdx]
		vaddpd ymm1, ymm1, [rdx+1*4*8]
		vaddpd ymm0, ymm0, [rdx+2*4*8]
		vaddpd ymm1, ymm1, [rdx+3*4*8]
		
		vaddpd ymm0, ymm0, [rdx+4*4*8]
		vaddpd ymm1, ymm1, [rdx+5*4*8]
		vaddpd ymm0, ymm0, [rdx+6*4*8]
		vaddpd ymm1, ymm1, [rdx+7*4*8]
		
		vaddpd ymm0, ymm0, [rdx+8*4*8]
		vaddpd ymm1, ymm1, [rdx+9*4*8]
		vaddpd ymm0, ymm0, [rdx+10*4*8]
		vaddpd ymm1, ymm1, [rdx+11*4*8]
		
		vaddpd ymm0, ymm0, [rdx+12*4*8]
		vaddpd ymm1, ymm1, [rdx+13*4*8]
		vaddpd ymm0, ymm0, [rdx+14*4*8]
		vaddpd ymm1, ymm1, [rdx+15*4*8]
		
		add rdx, 64*8; 64 ����� * ������ ����� � ������
		;cmp rdx, rbx
		;jl @loop; �������, ���� �� �������� �������
		sub rcx, 64
		jnc @loop; �������, ���� �� �������� �������
		;]

	add rcx, 64
	jz @exit
	; ���� 2 - ������������ �������� �� 4 ����� �� ���
	; ������������� ���������� ����, �� ������� ����� ������� �����,
	; ����� ����������� �������� ���������� ���������� vaddpd,
	; ����� ������� ����� 8 (� ������� ��������)
	@step2:
	mov rax, rcx
	shr rax, 2
	shl rax, 5
	lea rdx, [rdx+rax+256]  ;=��������� ����� �������� ������� �� ��������� ����� �� 256 ����
							; �������� ����� ��� ��������� �������� �������� ���������� vaddpd
	shr rax, 2;

	call @next
	@next: 
	pop r8;=��������� ������ ������� ����������
	add r8, 15*8+15; ��������� ������ ��������
	sub r8, rax
	jmp r8; ������� �� ����������� ��������������� ������
	;
	vaddpd ymm1, ymm1, [rdx-4*8*15-256]
	vaddpd ymm0, ymm0, [rdx-4*8*14-256]
	vaddpd ymm1, ymm1, [rdx-4*8*13-256]

	vaddpd ymm0, ymm0, [rdx-4*8*12-256]
	vaddpd ymm1, ymm1, [rdx-4*8*11-256]
	vaddpd ymm0, ymm0, [rdx-4*8*10-256]
	vaddpd ymm1, ymm1, [rdx-4*8*9-256]

	vaddpd ymm0, ymm0, [rdx-4*8*8-256]
	vaddpd ymm1, ymm1, [rdx-4*8*7-256]
	vaddpd ymm0, ymm0, [rdx-4*8*6-256]
	vaddpd ymm1, ymm1, [rdx-4*8*5-256]

	vaddpd ymm0, ymm0, [rdx-4*8*4-256]
	vaddpd ymm1, ymm1, [rdx-4*8*3-256]
	vaddpd ymm0, ymm0, [rdx-4*8*2-256]
	vaddpd ymm1, ymm1, [rdx-4*8*1-256]
	;
	vaddpd ymm0,ymm0,ymm1

	; �������������� �������� �������� AVX
	; # Paul's version                      # Ryzen      # Skylake
    ;vhaddpd       ymm0, ymm0, ymm0;        # 8 uops     # 3 uops
    ;vperm2f128    ymm1, ymm0, ymm0, 49;    # 8 uops     # 1 uop
    ;vaddpd        ymm0, ymm0, ymm1;        # 2 uops     # 1 uop

	; # Peter's version                     # Ryzen      # Skylake
    vextractf128    xmm1, ymm0, 1;          # 1 uop      # 1 uop
    vaddpd          xmm0, xmm1, xmm0;       # 1 uop      # 1 uop
    vunpckhpd       xmm1, xmm0, xmm0;       # 1 uop      # 1 uop
    vaddsd          xmm0, xmm0, xmm1;       # 1 uop      # 1 uop 

	vzeroupper
	; ���� 3 - ������������ �������� �� 1 ����� �� ���
	and rcx, 3
	jz @exit
	addsd xmm0, QWORD PTR [rdx-256]
	sub rcx, 1
	jz @exit
	addsd xmm0,  QWORD PTR [rdx-256+8]
	sub rcx, 1
	jz @exit
	addsd xmm0,  QWORD PTR [rdx-256+16]
@exit:
	ret
array_sum_avx ENDP

; ��������� ������� �������� ������� �� �����
array_scale_avx PROC ;[+]

	;rdx=current pos at data array
	;rcx=size
	;xmm2=scale value

	lea r11, [rdx+rcx*8];=finish adress
	mov r10, r11
	and r10, -8*8;=aligned finish adress

	cmp rcx, 8
	jl @step2

	;[+ step 1 - vectorized scale
	vbroadcastsd ymm2, xmm2;=scale value

	@loop1:;[
	vmulpd ymm0, ymm2, [rdx+0]
	vmulpd ymm1, ymm2, [rdx+4*8]
	vmovapd [rdx+0], ymm0
	vmovapd [rdx+4*8], ymm1

	add rdx, 8*8; 8 elements of sizeof(double)
	cmp rdx, r10
	jl @loop1;]
	;]

	;[+ step 2 - process after aligned adress
	@step2:
	cmp rdx, r11; 
	je @exit
	@loop2:;[
		movsd xmm0, QWORD PTR [rdx]
		mulsd xmm0, xmm2
		movsd QWORD PTR [rdx], xmm0
		add rdx, 8;
		cmp rdx, r11
		jl @loop2;]
	;]

@exit:
	ret
array_scale_avx ENDP


END