;******************************************************************************************
; Ishar: Legend of the Fortress (GOG version) loader
; Removes both copy protection and requirement to pay gold to save
; Compile the source code with MASM, JWASM or UASM (http://www.terraspace.co.uk/uasm.html)
;
; Dedicated to the memory of Dr. Detergent / UNT
;******************************************************************************************

OPTION LJMP

.8086
.MODEL TINY
.CODE

        ORG     100h                              ; Code starts at offset 100h

start:

; Adjust memory size

        mov     sp, program_length
        mov     ah, 4Ah
        mov     bx, (program_length/16)+1         ; BX = size of this loader in 16-byte paragraphs
        int     21h

; Prepare Environmental Parent Block (EPB)

        mov     ax, cs
        mov     [cmdLineSeg], ax
        mov     [fcb1Seg], ax
        mov     [fcb2Seg], ax

; Hook interrupt vectors

        mov     ax, 3521h
        int     21h
        mov     [origInt21Ofs], bx                ; Store the original Int 21h offset
        mov     [origInt21Seg], es                ; Store the original Int 21h segment
        mov     ax, 2521h
        mov     dx, NewInt21
        int     21h

; Load and execute the target

        mov     [storedSP], sp                    ; Store SP
        mov     ax, cs
        mov     es, ax
        mov     ax, 4B00h
        mov     bx, offset EPB
        mov     dx, offset pgmName
        int     21h

        mov     ax, cs
        mov     ds, ax                            ; Restore DS
        cli
        mov     ss, ax                            ; Restore SS
        mov     sp, [storedSP]                    ; Restore SP
        sti

        jnc     @f
        mov     ah, 9                             ; Display error message
        mov     dx, offset errMsg
        int     21h

; Restore interrupt vectors

@@:     
        lds     dx, dword ptr [origInt21Addr]
        mov     ax, 2521h
        int     21h

; Exit to DOS

        int     20h

;******************************************************************************************
;
;                                      Int 21h handler
;
;******************************************************************************************

NewInt21:

    CALLER_FLAGS = 6
    CALLER_CS = 4
    CALLER_IP = 2
    SAVED_BP =  0
    SAVED_DI = -2
    SAVED_SI = -4
    SAVED_BX = -6
    SAVED_DX = -8
    SAVED_CX = -0Ah
    SAVED_ES = -0Ch
    SAVED_DS = -0Eh
    SAVED_AX = -10h

        push    bp
        mov     bp, sp
        push    di 
        push    si
        push    bx
        push    dx
        push    cx
        push    es
        push    ds
        push    ax

        mov     cx, [bp+CALLER_CS]
        mov     es, cx

; Check for mov di, [ss:0B1Ah] (36 8B 3E 1A 0B) / retn (C3) sequence at CALLER_CS:7CB1
; These are the last two instructions in the function handling unpacking of the game scripts
; We're going to replace the first instruction, i.e. mov di, [ss:0B1Ah] (36 8B 3E 1A 0B) 
; with Int 21h (CD 21)

        mov     di, 7CB1h
        cmp     word ptr es:[di], 8B36h
        jnz     check_caller_csip
        cmp     word ptr es:[di+2], 1A3Eh
        jnz     check_caller_csip
        cmp     word ptr es:[di+4], 0C30Bh
        jnz     check_caller_csip
        cld
        mov     ax, 21CDh
        stosw                                     ; Replace mov di, [ss:0B1Ah] with Int 21h and
        mov     ax, 9090h
        stosw                                     ; three
        stosb                                     ; NOPs.
        mov     cs:[gameCS], cx

check_caller_csip:
        cmp     cs:[gameCS], cx
        jnz     popregs_jump_original_int21
        cmp     word ptr [bp+CALLER_IP], 7CB1h+2
        jnz     check_file_open
        mov     ax, ss:[0B1Ah]                    ; Simulate the instruction replaced by our Int 21h
        mov     [bp+SAVED_DI], ax                 ; and store the result
        mov     bx, cs:[action]
        add     bx, bx
        js      exit_handler
        
; The script is unpacked and ready for patching

        mov     ax, ss:[0BCAh]
        mov     ds, ax
        mov     di, cs:[addrTbl+bx]
        call    word ptr cs:[jumpTbl+bx]          ; Call the patching function
        mov     cs:[action], -1
        
exit_handler:
        pop     ax 
        pop     ds 
        pop     es 
        pop     cx 
        pop     dx 
        pop     bx 
        pop     si 
        pop     di 
        pop     bp
        iret        

check_file_open:
        cmp     ah, 3Dh                           ; Open file?
        jnz     popregs_jump_original_int21
        and     al, 00000111b
        cmp     al, 1                             ; Open for write only?
        jz      match_not_found
        
        mov     ax, cs
        mov     es, ax                            ; ES = the loader's segment
        xor     cx, cx

next_fname:
        mov     bx, cx
        shl     bx, 1
        shl     bx, 1
        shl     bx, 1
        shl     bx, 1
        lea     di, cs:[fnameTbl+bx]
        mov     si, dx
        call    StringCompare
        or      ax, ax
        jnz     match_found
        inc     cx
        cmp     cx, NUM_OF_ENTRIES
        jb      next_fname
        
match_not_found:        
        mov     cx, -1

match_found:
        mov     cs:[action], cx

popregs_jump_original_int21:
        pop     ax 
        pop     ds 
        pop     es 
        pop     cx 
        pop     dx 
        pop     bx 
        pop     si 
        pop     di 
        pop     bp

jump_original_int21:
        db      0EAh                              ; Opcode for jmp segment:offset instruction
origInt21Addr  equ $
origInt21Ofs    dw ?
origInt21Seg    dw ?

;******************************************************************************************

patch_sos_io:
patch_sosd_io:
patch_sose_io:
patch_sosi_io:
        cmp     word ptr [di], 0100h
        jnz     @f
        cmp     word ptr [di-2], 1E3Fh
        jnz     @f
        cmp     word ptr [di-4], 1020h
        jnz     @f
        mov     byte ptr [di+1], 0
@@:     retn

patch_monstre_io:
patch_telep_io:
        cmp     byte ptr [di], 3Ah
        jnz     @f
        cmp     word ptr [di+1], 1814h
        jnz     @f
        cmp     word ptr [di+3], 0
        jnz     @f
        mov     byte ptr [di+1], 0Ah
@@:     retn

;******************************************************************************************
; Function
;       StringCompare
; Description
;       Compares two zero-terminated stings str1 and str2
; Input
;       DS:SI points to str1
;       ES:DI points to str2 (must be lowercase)
; Modifies
;       SI, DI
; Returns
;       AX = 1 if the strings are equal
;       AX = 0 if the strings are not equal
;******************************************************************************************

StringCompare PROC NEAR
        dec     di

next_char:
        inc     di
        lodsb
        cmp     al, 'A'
        jb      compare_chars
        cmp     al, 'Z'
        ja      compare_chars
        or      al, 20h

compare_chars:
        cmp     es:[di], al
        jnz     not_equal
        or      al, al
        jnz     next_char
        
; The strings are equal
        mov     ax, 1
        ret

not_equal:
        xor     ax, ax
        ret
StringCompare ENDP

align 2
action  dw      -1

fname16 MACRO str:REQ
LOCAL start
start = $
        db      str
        db      16-($-start) dup (0)
ENDM

fnameTbl:
        fname16  'sos.io'
        fname16  'sosd.io'
        fname16  'sose.io'
        fname16  'sosi.io'
        fname16  'monstre.io'
        fname16  'telep.io'

jumpTbl:
        dw patch_sos_io
        dw patch_sosd_io
        dw patch_sose_io
        dw patch_sosi_io
        dw patch_monstre_io
        dw patch_telep_io
NUM_OF_ENTRIES = ($-jumpTbl) / 2

addrTbl:
        dw 0B65h
        dw 0B0Bh
        dw 0AB1h
        dw 0B0Ah
        dw 03FEh
        dw 0400h
        
; Environmental parent block

EPB:
           dw    0     ; Environment block, segment pointer
           dw    80h   ; Offset of command-line tail
cmdLineSeg dw    ?     ; Segment of command-line tail
           dw    5Ch   ; Offset of first file control block to be copied into new PSP + 5Ch
fcb1Seg    dw    ?     ; Segment of first file control block
           dw    6Ch   ; Offset of second file control block to be copied into new PSP + 6Ch
fcb2Seg    dw    ?     ; Segment of second file control block

storedSP   dw    ?
gameCS     dw    0

errMsg  db 'Failed to load '
pgmName db 'start.exe', 0
        db 0dh, 0ah, '$'

align 2
STACK_LENGTH = 400h

program_length = $ - start + STACK_LENGTH

END start
