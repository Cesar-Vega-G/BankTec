
.MODEL SMALL
.STACK 100h

.DATA
                         ;reserva de espacios en memoria 
    TAM_REGISTRO        EQU 30  
    OFF_ID              EQU 0
    OFF_NOMBRE          EQU 2
    OFF_SALDO_ENTERO    EQU 22
    OFF_DECIMAL         EQU 26
    OFF_ESTADO          EQU 28
    OFF_PAD             EQU 29;no lo usamos, cuestiones de rendimiento.

    
    CUENTAS      DB 300 DUP(0) ; 10 cuentas * 30 bytes
    CONT_CUENTAS DB 0    ;contador de cuentas totales   
    
    ;buffers para validaciones y demas 
    
    BUF_NOMBRE DB 21 ; caracteres maximos
               DB 0  ; cuantos se leyeron para acceder a
               DB 21 DUP(0) los caracteres 
               
    ;buffer de id numeros entre 0-65535  
             
    BUF_ID     DB 6
               DB 0
               DB 6 DUP(0)
                
    ;buffer para el saldo
    
    BUF_SALDO  DB 6         ; parte entera  (0-65535)
               DB 0
               DB 6 DUP(0)

    BUF_DECIMAL DB 5         ; parte decimal (0-9999)
                DB 0
                DB 5 DUP(0)
    
    

    ;MENSAJES QUE VA A IMPRIMIR EL SISTEMA CUANDO SE LES LLAME CON "LEAD DX,MSG_MENU "
    MSG_MENU     DB 10,13, "--- BankTec Menu ---"
                 DB 10,13, "1. Crear cuenta"
                 DB 10,13, "2. Depositar"
                 DB 10,13, "3. Retirar"
                 DB 10,13, "4. Consultar Saldo"
                 DB 10,13, "5. Reporte General"
                 DB 10,13, "6. Desactivar"
                 DB 10,13, "7. Salir"
                 DB 10,13, "Seleccione: $"
    
    MSG_ERR_ID   DB 10,13, "Error: Cuenta no existe.$"
    MSG_FIN      DB 10,13, "Programa finalizado. Gracias. BAC CREDOMATIC S.A $"
    
    ; Mensajes para crear cuenta
    MSG_NOM         DB 10,13, "Inserte su Nombre: $"
    MSG_ID          DB 10,13, "Inserte ID: $"
    MSG_SALDO_INI   DB 10,13, "Inserte saldo inicial: $"

    MSG_OK_CREAR    DB 10,13, "Cuenta creada exitosamente.$" 
    
    MSG_BANCO_LLENO DB 10,13, "Error: el banco ya tiene 10 cuentas.$"
    
    MSG_ID_DUP      DB 10,13, "Error: ese ID ya existe.$"  
    
    MSG_SAlDO_NEG   DB 10,13, "Error: el saldo inicial no puede ser negativo.$" 
    
    MSG_ERROR_NUM   DB 10,13, "Error: ingrese solo numeros enteros (0-65535).$" 
    
    MSG_NOM_VACIO   DB 10,13, "Error: el nombre no puede estar vacio.$"
    MSG_GOOD_ID     DB 10,13,  "ID REGISTRADO CON EXITO$"  
    
    ;mensajes para
    
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
    ;llamar a funcion para crear cuenta 
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











;Funcion para crear cuenta 
CREAR_CUENTA PROC        
  

    ; --- verificar que no este lleno ---
    CMP CONT_CUENTAS, 10    ; numero maximo de cuentas, para pruebas cambie el 10
    
    JE  CC_BANCO_LLENO

    ; --- calcular posicion de la nueva cuenta ---
    XOR AH, AH
    MOV AL, CONT_CUENTAS
    MOV BL, TAM_REGISTRO
    MUL BL
    LEA BP, CUENTAS
    ADD BP, AX

CC_PEDIR_ID:
    LEA DI, BUF_ID  ;usamos el buffer para cargar el numero
    MOV CX, 8    ;LE DECIMOS AL LIMPIADOR CUANTO TIENE QUE LIMPIAR
    
    CALL LIMPIAR_BUFFER  ;importante por si no se cumple una validacion
    MOV BUF_ID, 6  ;RESTAURAMOS PORQUE EL LIMPIADOR SI LIMPIA TODO,
                   ;ENTONCES DEBEMOS DE VOLVER PONER LIMITE
    LEA DX, MSG_ID
    MOV AH, 09h
    INT 21h
    LEA DX, BUF_ID  ;restringimos a 6 caracteres
    MOV AH, 0Ah
    INT 21h

    CMP BUF_ID+1, 0
    JE  CC_ERROR_NUM

    LEA SI, BUF_ID+2
    MOV CL, BUF_ID+1
    CALL ASCII_A_BINARIO
    JC  CC_ERROR_NUM

    

    ;falta crear verificador id duplicados

    MOV [BP + OFF_ID], DX   ; guardar ID

CC_PEDIR_NOMBRE:
    LEA DI, BUF_NOMBRE  ; DI apunta al inicio de BUF_NOMBRE
    MOV CX, 23          ; IGUAl contador para limpiar el buffer
    CALL LIMPIAR_BUFFER
    MOV BUF_NOMBRE, 21

    LEA DX, MSG_NOM  ; LECTURA DEL MENSAJE 
    MOV AH, 09h
    INT 21h
    LEA DX, BUF_NOMBRE ;BUFFER GOOD
    MOV AH, 0Ah
    INT 21h

    CMP BUF_NOMBRE+1, 0   ;RESTRICCION DE NOMBRE VACIO,
    JE  CC_ERROR_NOMBRE

    LEA DI, [BP + OFF_NOMBRE]      ;DI = DESTINO,BP APUNTA A LA CUENTA NUEVA 
    LEA BX, BUF_NOMBRE+2    ;toma el primer char de ahi
           
    MOV CL, BUF_NOMBRE+1   ;tomamos la cantidad de letras      
    XOR CH, CH     ;limpiamos el CH por el loop

CC_COPIAR_NOMBRE:
    MOV AL, [BX]
    MOV [DI], AL
    INC BX
    INC DI
    LOOP CC_COPIAR_NOMBRE

    ; --- saldo en 0 por defecto, no se le pregunta al cliente ---
    MOV WORD PTR [BP + OFF_SALDO_ENTERO], 0     ;PTR 
    MOV WORD PTR [BP + OFF_DECIMAL], 0

    ; --- activar cuenta ---
    MOV BYTE PTR [BP + OFF_ESTADO], 1

    ; --- incrementar contador ---
    INC CONT_CUENTAS

    LEA DX, MSG_OK_CREAR
    MOV AH, 09h
    INT 21h
    RET

CC_BANCO_LLENO:  ; funcion para poder parar si ya hay 10 cuentas
    LEA DX, MSG_BANCO_LLENO
    MOV AH, 09h
    INT 21h
    RET

;atrapar numeros que Incumplan requisitos
CC_ERROR_NUM:    
    LEA DX, MSG_ERROR_NUM
    MOV AH, 09h
    INT 21h
    JMP CC_PEDIR_ID

CC_ID_DUP:;EN PROCESO, FUNCION PARA ID DUPLICADOS
    LEA DX, MSG_ID_DUP
    MOV AH, 09h
    INT 21h
    JMP CC_PEDIR_ID

CC_ERROR_NOMBRE: ;FUNCION DE NOMBRE VACIO
    LEA DX, MSG_NOM_VACIO
    MOV AH, 09h
    INT 21h
    JMP CC_PEDIR_NOMBRE


    
    
    
    
    
    
CREAR_CUENTA ENDP









; --- OPCION 2: DEPOSITAR ---
DEPOSITAR PROC
    ; Logica: Pedir ID, llamar a BUSCAR_CUENTA, si existe sumar saldo
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






;FUNCION PARA LIMPIAR BUFFER

LIMPIAR_BUFFER PROC
    PUSH AX             ; guardar AX completo (16 bits)
    PUSH CX             ; guardar CX completo
    PUSH DI             ; guardar DI

    XOR AX, AX          ; AX = 0, mas rapido que MOV AX,0

LIMPIAR_LOOP:
    MOV [DI], AL        ; escribe byte 0 (AL = parte baja de AX)
    INC DI
    LOOP LIMPIAR_LOOP   ; decrementa CX, repite si CX != 0

    POP DI
    POP CX
    POP AX
    RET
LIMPIAR_BUFFER ENDP  



;FUNCIONES PARA VERIFICACIONES

ASCII_A_BINARIO PROC
    XOR AX, AX          ; AX = 0 (resultado acumulado)
    XOR CH, CH          ; CX = cantidad (limpiar CH)

CONV_LOOP:
    CMP CX, 0
    JE  CONV_OK         ; si ya no hay chars, terminamos

    MOV BL, [SI]        ; BL = char actual
    
    ; validar que sea digito '0' a '9'
    CMP BL, '0'
    JB  CONV_ERROR      ; menor que '0' ? no es digito
    CMP BL, '9'
    JA  CONV_ERROR      ; mayor que '9' ? no es digito

    SUB BL, '0'         ; BL = valor numerico (0-9)

    ; resultado = resultado * 10
    MOV DX, 10
    MUL DX              ; AX = AX * 10
    CMP DX, 0           ;chequeo de desbordamiento
    JNE CONV_ERROR
    ; sumar el digito actual
    XOR BH, BH          ; limpiar BH para usar BX completo
    ADD AX, BX          ; AX = AX + digito
    
    
    JC  CONV_ERROR     ;precaucion de desbordamiento    
    INC SI              ; siguiente char
    DEC CX              ; un digito menos
    JMP CONV_LOOP

CONV_OK:
    CLC                 ; CF = 0 ? éxito
    RET

CONV_ERROR:
    STC                 ; CF = 1 ? hubo error
    RET

ASCII_A_BINARIO ENDP  
 







;funcion para imprimir prueba
; Imprime el valor de AX en pantalla como digitos
; Entrada: AX = número a imprimir
;IMPRIMIR_AX PROC
 ;   MOV BX, 10          ; divisor
  ;  MOV CX, 0           ; contador de dígitos en stack

;DIVIDE_LOOP:
 ;   XOR DX, DX          ; limpiar DX antes de DIV
  ;  DIV BX              ; AX = AX/10, DX = residuo
   ; ADD DL, '0'         ; convertir a ASCII
    ;PUSH DX             ; guardar digito en stack
    ;INC CX              ; contar digito
    ;CMP AX, 0
    ;JNE DIVIDE_LOOP     ; si AX != 0 seguir dividiendo

;PRINT_LOOP:
 ;   POP DX              ; sacar digito (en orden correcto)
  ;  MOV AH, 02h         ; función imprimir char
   ; INT 21h
    ;LOOP PRINT_LOOP

    ;RET
;IMPRIMIR_AX ENDP










END MAIN




