
.MODEL SMALL
.STACK 100h

.DATA
    
    TAM_REGISTRO EQU 30
    OFF_NOMBRE   EQU 0
    OFF_ID       EQU 20
    OFF_SALDO    EQU 22
    OFF_ESTADO   EQU 26

    
    CUENTAS      DB 300 DUP(0) ; 10 cuentas * 30 bytes
    CONT_CUENTAS DB 0

    ;MENSAJES QUE VA A IMPRIMIR EL SISTEMA CUANDO SE LES LLAME CON "LEAD DX,MSG_MENU "
    MSG_MENU     DB 10,13, "--- BankTec Menu ---"
                 DB 10,13, "1. Crear cuenta"
                 DB 10,13, "2. Depositar"
                 DB 10,13, "3. Retirar"
                 DB 10,13, "4. Consultar Saldo"
                 DB 10,13, "5. Reporte General"
                 DB 10,13, "6. Desactivar"
                 DB 10,13, "7. Salir"
                 DB 10,13, "Seleccione: "
                 DB 10,13, "wawawaw$"
    
    MSG_ERR_ID   DB 10,13, "Error: Cuenta no existe.$"
    MSG_FIN      DB 10,13, "Programa finalizado. Gracias.$"

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

MENU_LOOP:

    LEA DX, MSG_MENU ;Prepara el mensaje
    MOV AH, 09h ;Prepara la funcion
    INT 21h ;La ejecuta

    MOV AH, 01h ;Escuchando teclado
    INT 21h ;ejecuta y sigue y lo guarda en Al
    
      
    ;ejemplo de botones
    CMP AL, '1'
    JE  LLAMAR_CREAR 
    
    CMP AL, '2'
    JE  LLAMAR_DEP 
    
    CMP AL, '7'
    JE  SALIR
    
           
    
    JMP MENU_LOOP ;Necesario por si se toca otra tecla

LLAMAR_CREAR:
    CALL CREAR_CUENTA
    JMP MENU_LOOP

LLAMAR_DEP:
    CALL DEPOSITAR
    JMP MENU_LOOP 
    




   
;Operacion de salir
SALIR:
    LEA DX, MSG_FIN
    MOV AH, 09h
    INT 21h
    MOV AH, 4Ch
    INT 21h
MAIN ENDP    












CREAR_CUENTA PROC
    ; Lógica: Validar espacio, pedir nombre, pedir ID, validar ID único
    RET
CREAR_CUENTA ENDP






; --- OPCIÓN 2: DEPOSITAR ---
DEPOSITAR PROC
    ; Lógica: Pedir ID, llamar a BUSCAR_CUENTA, si existe sumar saldo
    RET
DEPOSITAR ENDP










; --- OPCIÓN 3: RETIRAR ---
RETIRAR PROC
    ; Lógica: Similar a depositar pero restando y validando sobregiro
    RET
RETIRAR ENDP










; --- OPCIÓN 5: REPORTE GENERAL ---
MOSTRAR_REPORTE PROC
    ; Lógica: Ciclo LOOP de 1 a 10 para sumar saldos y buscar Max/Min
    RET
MOSTRAR_REPORTE ENDP











; --- UTILITARIO: BÚSQUEDA LINEAL (Obligatorio) ---
; Entrada: AX = ID buscado
; Salida: SI = Offset de la cuenta o FFFFh
BUSCAR_CUENTA PROC
    ; Recorre el arreglo comparando el ID en [SI + OFF_ID]
    RET
BUSCAR_CUENTA ENDP










; --- UTILITARIO: CONVERSIÓN ASCII A BINARIO ---
ASCII_A_BINARIO PROC
    ; Convierte la cadena del teclado a un número para cálculos
    RET
ASCII_A_BINARIO ENDP












END MAIN




