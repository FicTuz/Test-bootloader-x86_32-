bits 16
org 0x7C00

start:
    mov ax, 0x0003
    int 0x10
    cli
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0x7C00
    mov si, kmsg
    call print
    
    mov bx, 0x7E00        ; где ядро
    mov ah, 0x02          ; чтение секторов
    mov al, 64            ; Читаем сектора
    mov ch, 0             ; Цилиндр 0
    mov cl, 2             ; Сектор 2
    mov dh, 0             ; Головка 0
    mov dl, 0x00          ; Первая дискета
    int 0x13
    jc .error

    call enable_a20
    lgdt [gdt_desc]

    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:protected_mode_32

.error:
    mov si, err
    call print
    cli
    hlt

enable_a20:
    mov ax, 0x2401        ; Функция BIOS: включить A20
    int 0x15
    jnc .a20_ok           ; Если CF=0, всё ок
    
    ; Если BIOS не работает — пробуем порт 0x92
    in al, 0x92
    test al, 2
    jnz .a20_ok           ; Уже включён
    or al, 2
    out 0x92, al
.a20_ok:
    ret

[bits 32]
protected_mode_32:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    jmp 0x08:0x7E00

[bits 16]
print:
    lodsb               ; Загружаем байт из [SI]
    or al, al           ; Проверяем на ноль
    jz .done            ; Если ноль — выходим
    mov ah, 0x0e        ; Телетайп-режим
    int 0x10            ; Вывод символа
    jmp print
.done:
    ret
gdt_start:
    dq 0x0000000000000000          ; NULL
    dw 0xFFFF                      ; LIMIT 0-15
    dw 0x0000                      ; BASE 0-15
    db 0x00                        ; BASE 16-23
    db 0x9A                        ; ACCESS (код)
    db 0xCF                        ; GRANULARITY
    db 0x00                        ; BASE 24-31
    dw 0xFFFF                      ; LIMIT 0-15
    dw 0x0000                      ; BASE 0-15
    db 0x00                        ; BASE 16-23
    db 0x92                        ; ACCESS (данные)
    db 0xCF                        ; GRANULARITY
    db 0x00                        ; BASE 24-31
gdt_end:

gdt_desc:
    dw gdt_end - gdt_start - 1
    dd gdt_start
err db "Err.", 0x0D, 0x0A, 0x00
kmsg db "loading kernel...", 0x0D, 0x0A, 0x00
times 510 - ($ - $$) db 0
dw 0xAA55