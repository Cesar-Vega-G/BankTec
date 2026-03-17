  ;COMENTARIOS CON AYUDA DE GEMINI
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
    
    BUF_SALDO  DB 11         ; parte entera  (0-65535) y decimal
               DB 0
               DB 11 DUP(0)

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
    MSG_NOM          DB 10,13, "Inserte su Nombre: $"
    MSG_ID           DB 10,13, "Inserte ID: $"
    MSG_SALDO_INI    DB 10,13, "Inserte saldo inicial: $"

    MSG_OK_CREAR     DB 10,13, "Cuenta creada exitosamente.$" 
    
    MSG_BANCO_LLENO DB 10,13, "Error: el banco ya tiene 10 cuentas.$"
    
    MSG_ID_DUP      DB 10,13, "Error: ese ID ya existe.$"  
    
    MSG_SAlDO_NEG   DB 10,13, "Error: el saldo inicial no puede ser negativo.$" 
    
    MSG_ERROR_NUM   DB 10,13, "Error: ingrese solo numeros enteros (0-65535).$" 
    
    MSG_NOM_VACIO   DB 10,13, "Error: el nombre no puede estar vacio.$"
    MSG_GOOD_ID     DB 10,13,  "ID REGISTRADO CON EXITO$"  
    
    ;mensajes para consultar saldo
    MSG_CONSULTAR   DB 10,13, "Inserte ID a consultar: $"  
    
    MSG_SALDO_LABEL DB 10,13, "Saldo: $"   
    
    MSG_PUNTO        DB ".$" 
    
    ;mensajes para depositar
    
    MSG_DEPOSITAR    DB 10,13, "Inserte ID para depositar: $" 
    
    MSG_MONTO        DB 10,13, "Inserte monto a depositar: $"  
    
    MSG_OK_DEP       DB 10,13, "Deposito exitoso.$"    
    
    MSG_INACTIVA     DB 10,13, "Error: la cuenta esta inactiva.$" 
    
    MSG_MONTO_INV    DB 10,13, "Error: el monto debe ser mayor a 0.$"
    
    ;Mensajes para retirar  
    
    MSG_RETIRAR    DB 10,13, "Inserte ID para retirar: $" 
    
    MSG_MONTO_RETIRAR        DB 10,13, "Inserte monto a retirar: $"  
    
    MSG_OK_RET       DB 10,13, "Retiro exitoso.$"    
        
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

    CMP AL, '3'
    JE  LLAMAR_RETIRAR
    
    CMP AL, '4'
    JE  LLAMAR_CONSULTAR
    
    CMP AL, '7'
    JE  SALIR
    
    JMP MENU_LOOP ;Necesario por si se toca otra tecla

LLAMAR_CREAR: 
    CALL CREAR_CUENTA
    JMP MENU_LOOP

LLAMAR_DEP:
    CALL DEPOSITAR
    JMP MENU_LOOP 

LLAMAR_RETIRAR:
    CALL RETIRAR
    JMP MENU_LOOP
    
LLAMAR_CONSULTAR:
    CALL CONSULTAR_SALDO
    JMP MENU_LOOP

SALIR:
    LEA DX, MSG_FIN
    MOV AH, 09h
    INT 21h
    MOV AH, 4Ch
    INT 21h
MAIN ENDP    

;Funcion para crear cuenta                                ;////////////// Crear cuenta
CREAR_CUENTA PROC        
  

    ; --- verificar que no este lleno ---
    CMP CONT_CUENTAS, 10    ; numero maximo de cuentas
    
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

    PUSH AX                 ; guardamos el ID nuevo antes de que BUSCAR_CUENTA lo use
    CALL BUSCAR_CUENTA      ; busca si ya existe ese ID
    POP AX                  ; recuperamos el ID nuevo
    JNC CC_ID_DUP           


    MOV [BP + OFF_ID], AX   ; guardar ID

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

                                                                                             ;///////////////////  Depositar
; --- OPCION 2: DEPOSITAR ---
DEPOSITAR PROC

; ==========================================================
; ETAPA 1: IDENTIFICACION DEL USUARIO
; ==========================================================
DEP_PEDIR_ID:
    LEA DI, BUF_ID          ; Apuntamos al buffer de ID para limpiarlo
    MOV CX, 8                ; Tamano del buffer
    CALL LIMPIAR_BUFFER     ; Borramos basura de entradas previas
    MOV BUF_ID, 6            ; Definimos maximo de 6 caracteres para el ID

    LEA DX, MSG_DEPOSITAR   ; "Inserte ID de la cuenta:"
    MOV AH, 09h             ; Funcion para imprimir cadena
    INT 21h

    LEA DX, BUF_ID          ; DX apunta al buffer donde se guardara lo escrito
    MOV AH, 0Ah             ; Funcion para leer cadena del teclado
    INT 21h

    CMP BUF_ID+1, 0          ; ¿El usuario presiono Enter sin escribir nada?
    JE  DEP_ERROR_ID        ; Si esta vacio, saltamos al error

    ; --- Conversion de ID (Texto -> Binario) ---
    LEA SI, BUF_ID+2        ; SI apunta al inicio del texto (saltando los 2 bytes de control)
    MOV CL, BUF_ID+1        ; CL = cantidad de caracteres escritos
    CALL ASCII_A_BINARIO    ; Transforma "123" en el numero 123 (resultado en AX)
    JC  DEP_ERROR_ID        ; Si la conversion fallo, hubo un caracter no numerico

    ; --- Localizacion de la cuenta en Memoria ---
    CALL BUSCAR_CUENTA      ; Busca la cuenta. Si la halla, BP apunta a su bloque de datos
    JC  DEP_NO_EXISTE       ; Si el Carry Flag es 1, la cuenta no existe

    ; --- Validacion de Estado ---
    CMP BYTE PTR [BP + OFF_ESTADO], 1 ; ¿La cuenta esta activa (1)?
    JNE DEP_INACTIVA        ; Si no es 1, la cuenta esta inactiva o bloqueada

; ==========================================================
; ETAPA 2: LECTURA Y ESCANEO DEL MONTO
; ==========================================================
DEP_PEDIR_MONTO:
    LEA DI, BUF_SALDO       ; Preparamos el buffer para el monto
    MOV CX, 13              ; 13 bytes (1 limite + 1 contador + 11 caracteres)
    CALL LIMPIAR_BUFFER
    MOV BUF_SALDO, 11       ; Limite de 11 caracteres (ej: 000000.0000)

    LEA DX, MSG_MONTO       ; "Inserte monto a depositar:"
    MOV AH, 09h
    INT 21h
    LEA DX, BUF_SALDO
    MOV AH, 0Ah
    INT 21h

    CMP BUF_SALDO+1, 0      ; Validar si no escribio nada
    JE  DEP_ERROR_MONTO

    ; --- Buscando el Punto Decimal ---
    LEA SI, BUF_SALDO+2     ; SI apunta al inicio del monto (ej: "12.5")
    MOV CL, BUF_SALDO+1     ; CL = total de caracteres escritos
    XOR CH, CH
    XOR BX, BX              ; BX contara los digitos de la parte entera

DEP_BUSCAR_PUNTO:
    CMP CX, 0                ; ¿Llegamos al final del texto sin hallar el punto?
    JE  DEP_SOLO_ENTERO     ; Si termino, es un numero entero (ej: "100")

    MOV AL, [SI]            ; Cargamos el caracter actual en AL
    CMP AL, '.'             ; ¿Es un punto?
    JE  DEP_TIENE_PUNTO     ; Si lo es, saltamos a procesar decimales

    ; Validar que el caracter sea un numero '0'-'9'
    CMP AL, '0'
    JB  DEP_ERROR_MONTO
    CMP AL, '9'
    JA  DEP_ERROR_MONTO

    INC BX                  ; Sumamos 1 al contador de parte entera
    INC SI                  ; Movemos el "dedo" al siguiente caracter
    DEC CX                  ; Queda un caracter menos por revisar
    JMP DEP_BUSCAR_PUNTO

; ==========================================================
; ETAPA 3: CASO DE NUMERO ENTERO (Sin punto decimal)
; ==========================================================
DEP_SOLO_ENTERO:
    LEA SI, BUF_SALDO+2     ; Volvemos al inicio del texto
    MOV CX, BX              ; CX = numero de digitos enteros
    CALL ASCII_A_BINARIO    ; Convertimos a binario
    JC  DEP_ERROR_MONTO

    CMP AX, 0                ; ¿Intento depositar $0?
    JE  DEP_ERROR_MONTO

    ADD [BP + OFF_SALDO_ENTERO], AX ; Sumamos directamente al saldo de la cuenta
    JMP DEP_EXITO           ; Finalizamos

; ==========================================================
; ETAPA 4: CASO CON PUNTO DECIMAL
; ==========================================================
DEP_TIENE_PUNTO:
    PUSH SI                 ; Guardamos la posicion exacta del punto en la pila
    PUSH CX                 ; Guardamos cuantos caracteres quedan despues del punto

    ; --- Procesar Parte Entera Primero ---
    LEA SI, BUF_SALDO+2     ; Volvemos al inicio del buffer
    MOV CX, BX              ; BX tenia cuantos digitos habia antes del punto
    CMP CX, 0                ; ¿Escribio algo como ".50"?
    JE  DEP_ENTERO_CERO     ; Si es asi, la parte entera es 0
    CALL ASCII_A_BINARIO    ; Convierte la parte entera
    JC  DEP_ERROR_MONTO_POP
    JMP DEP_GUARDAR_ENTERO

DEP_ENTERO_CERO:
    XOR AX, AX              ; Parte entera = 0

DEP_GUARDAR_ENTERO:
    MOV DI, AX              ; Guardamos temporalmente la parte entera en DI

    ; --- Procesar Parte Decimal ---
    POP CX                  ; Recuperamos cuantos caracteres hay tras el punto
    POP SI                  ; Recuperamos la posicion del punto
    INC SI                  ; Movemos SI al primer digito despues del punto
    DEC CX                  ; Descontamos el punto del conteo

    CMP CX, 0                ; ¿Puso un punto al final sin nada? "10."
    JE  DEP_ERROR_MONTO
    CMP CX, 4                ; ¿Puso mas de 4 decimales? Error de precision
    JA  DEP_ERROR_MONTO

    PUSH DI                 ; Guardamos la parte entera en la pila
    PUSH CX                 ; Guardamos cuantos decimales hay para normalizar
    CALL ASCII_A_BINARIO    ; Convertimos decimales a binario (ej: ".5" -> 5)
    JC  DEP_ERROR_MONTO_POP3

    POP CX                  ; Recuperamos el numero de decimales escritos
    ; --- Normalizacion (Ajustar a 4 digitos: .5 -> .5000) ---
    MOV BX, 4
    SUB BX, CX              ; BX = cuantos ceros faltan (4 - escritos)

DEP_NORMALIZAR:
    CMP BX, 0                ; ¿Ya agregamos todos los ceros?
    JE  DEP_NORMALIZADO
    PUSH CX
    XOR DX, DX              ; Limpiamos DX para la multiplicacion
    MOV CX, 10              ; Multiplicamos por 10 para agregar un cero
    MUL CX                  ; AX = AX * 10
    POP CX
    DEC BX
    JMP DEP_NORMALIZAR

; ==========================================================
; ETAPA 5: ARITMETICA FINAL (SUMA CON ACARREO)
; ==========================================================
DEP_NORMALIZADO:
    MOV BX, AX              ; BX = Decimal ya normalizado (ej: 5000)
    POP DI                  ; DI = Parte entera guardada

    ; --- Sumar Decimales al Saldo ---
    MOV AX, [BP + OFF_DECIMAL] ; Trae los decimales actuales de la cuenta
    ADD AX, BX                   ; Suma los decimales nuevos

    CMP AX, 10000              ; ¿La suma paso de 9999 (se convirtio en 1 peso)?
    JB  DEP_SIN_ACARREO        ; Si es menor a 10000, no hay acarreo

    SUB AX, 10000              ; Le quitamos el exceso de 10000
    INC DI                       ; Sumamos 1 a la parte entera (Acarreo)

DEP_SIN_ACARREO:
    MOV [BP + OFF_DECIMAL], AX       ; Guardamos decimales finales
    ADD [BP + OFF_SALDO_ENTERO], DI  ; Sumamos la parte entera al saldo
    JMP DEP_EXITO

; ==========================================================
; SECCION DE MANEJO DE ERRORES DEPOSITAR
; ==========================================================
DEP_EXITO:
    LEA DX, MSG_OK_DEP      ; "Deposito realizado con exito"
    MOV AH, 09h
    INT 21h
    RET

DEP_ERROR_ID:
    LEA DX, MSG_ERROR_NUM   ; "ID invalido"
    MOV AH, 09h
    INT 21h
    JMP DEP_PEDIR_ID        ; Reintentar

DEP_NO_EXISTE:
    LEA DX, MSG_ERR_ID      ; "Cuenta no encontrada"
    MOV AH, 09h
    INT 21h
    RET

DEP_INACTIVA:
    LEA DX, MSG_INACTIVA    ; "Cuenta inactiva"
    MOV AH, 09h
    INT 21h
    RET

DEP_ERROR_MONTO:
    LEA DX, MSG_MONTO_INV   ; "Monto no valido"
    MOV AH, 09h
    INT 21h
    JMP DEP_PEDIR_MONTO     ; Reintentar

; --- Limpiadores de Pila (Stack) ---
DEP_ERROR_MONTO_POP3:
    POP CX
    POP DI
    JMP DEP_ERROR_MONTO

DEP_ERROR_MONTO_POP:
    POP CX
    POP SI
    JMP DEP_ERROR_MONTO

DEPOSITAR ENDP        

                                                                    ;/////////////////// Retirar
RETIRAR PROC
; ==========================================================
; ETAPA 1: IDENTIFICACION DEL USUARIO
; ==========================================================
RET_PEDIR_ID:
    LEA DI, BUF_ID          ; Apuntamos al buffer de ID para limpiarlo
    MOV CX, 8                ; Tamano del buffer
    CALL LIMPIAR_BUFFER     ; Borramos basura de entradas previas
    MOV BUF_ID, 6            ; Definimos maximo de 6 caracteres para el ID

    LEA DX, MSG_RETIRAR     ; "Inserte ID para retiar:"
    MOV AH, 09h             ; Funcion para imprimir cadena
    INT 21h

    LEA DX, BUF_ID          ; DX apunta al buffer donde se guardara lo escrito
    MOV AH, 0Ah             ; Funcion para leer cadena del teclado
    INT 21h

    CMP BUF_ID+1, 0          ; ¿El usuario presiono Enter sin escribir nada?
    JE  RET_ERROR_ID        ; Si esta vacio, saltamos al error

    ; --- Conversion de ID (Texto -> Binario) ---
    LEA SI, BUF_ID+2        ; SI apunta al inicio del texto (saltando los 2 bytes de control)
    MOV CL, BUF_ID+1        ; CL = cantidad de caracteres escritos
    CALL ASCII_A_BINARIO    ; Transforma "123" en el numero 123 (resultado en AX)
    JC  RET_ERROR_ID        ; Si la conversion fallo, hubo un caracter no numerico

    ; --- Localizacion de la cuenta en Memoria ---
    CALL BUSCAR_CUENTA      ; Busca la cuenta. Si la halla, BP apunta a su bloque de datos
    JC  RET_NO_EXISTE       ; Si el Carry Flag es 1, la cuenta no existe

    ; --- Validacion de Estado ---
    CMP BYTE PTR [BP + OFF_ESTADO], 1 ; ¿La cuenta esta activa (1)?
    JNE RET_INACTIVA        ; Si no es 1, la cuenta esta inactiva o bloqueada
    
; ==========================================================
; ETAPA 2: LECTURA Y ESCANEO DEL MONTO
; ==========================================================
RET_PEDIR_MONTO:
    LEA DI, BUF_SALDO       ; Preparamos el buffer para el monto
    MOV CX, 13              ; 13 bytes (1 limite + 1 contador + 11 caracteres)
    CALL LIMPIAR_BUFFER
    MOV BUF_SALDO, 11       ; Limite de 11 caracteres (ej: 000000.0000)

    LEA DX, MSG_MONTO_RETIRAR ; "Inserte monto a retiar:"
    MOV AH, 09h
    INT 21h
    LEA DX, BUF_SALDO
    MOV AH, 0Ah
    INT 21h

    CMP BUF_SALDO+1, 0      ; Validar si no escribio nada
    JE  RET_ERROR_MONTO

    ; --- Buscando el Punto Decimal ---
    LEA SI, BUF_SALDO+2     ; SI apunta al inicio del monto (ej: "12.5")
    MOV CL, BUF_SALDO+1     ; CL = total de caracteres escritos
    XOR CH, CH
    XOR BX, BX              ; BX contara los digitos de la parte entera

RET_BUSCAR_PUNTO:
    CMP CX, 0                ; ¿Llegamos al final del texto sin hallar el punto?
    JE  RET_SOLO_ENTERO     ; Si termino, es un numero entero (ej: "100")

    MOV AL, [SI]            ; Cargamos el caracter actual en AL
    CMP AL, '.'             ; ¿Es un punto?
    JE  RET_TIENE_PUNTO     ; Si lo es, saltamos a procesar decimales

    ; Validar que el caracter sea un numero '0'-'9'
    CMP AL, '0'
    JB  RET_ERROR_MONTO
    CMP AL, '9'
    JA  RET_ERROR_MONTO

    INC BX                  ; Sumamos 1 al contador de parte entera
    INC SI                  ; Movemos el "dedo" al siguiente caracter
    DEC CX                  ; Queda un caracter menos por revisar
    JMP RET_BUSCAR_PUNTO

; ==========================================================
; ETAPA 3: CASO DE NUMERO ENTERO (Sin punto decimal)
; ==========================================================
RET_SOLO_ENTERO:
    LEA SI, BUF_SALDO+2     ; Volvemos al inicio del texto
    MOV CX, BX              ; CX = numero de digitos enteros
    CALL ASCII_A_BINARIO    ; Convertimos a binario
    JC  RET_ERROR_MONTO

    CMP AX, 0                ; ¿Intento retirar $0?
    JE  RET_ERROR_MONTO

    ; --- VALIDACION DE FONDOS ---
    CMP [BP + OFF_SALDO_ENTERO], AX ; Comparamos: ¿Saldo actual < lo que quiere retirar?
    JB  RET_ERROR_MONTO             ; Si es menor, salta al error

    ; --- OPERACION DE RETIRO ---
    SUB [BP + OFF_SALDO_ENTERO], AX ; Restamos el monto
    JMP RET_EXITO                   ; Finalizamos con exito

; ==========================================================
; ETAPA 4: CASO CON PUNTO DECIMAL
; ==========================================================
RET_TIENE_PUNTO:
    PUSH SI                 
    PUSH CX                 

    ; --- Procesar Parte Entera Primero ---
    LEA SI, BUF_SALDO+2     
    MOV CX, BX              
    CMP CX, 0                
    JE  RET_ENTERO_CERO     
    CALL ASCII_A_BINARIO    
    JC  RET_ERROR_MONTO_POP 
    JMP RET_GUARDAR_ENTERO     

RET_ENTERO_CERO:
    XOR AX, AX              

RET_GUARDAR_ENTERO:
    MOV DI, AX              

    ; --- Procesar Parte Decimal ---
    POP CX                  
    POP SI                  
    INC SI                  
    DEC CX                  

    CMP CX, 0                
    JE  RET_ERROR_MONTO
    CMP CX, 4                
    JA  RET_ERROR_MONTO

    PUSH DI                 
    PUSH CX                 
    CALL ASCII_A_BINARIO    
    JC  RET_ERROR_MONTO_POP3

    POP CX                  
    ; --- Normalizacion ---
    MOV BX, 4
    SUB BX, CX              

RET_NORMALIZAR:
    CMP BX, 0                
    JE  RET_NORMALIZADO
    PUSH CX
    XOR DX, DX              
    MOV CX, 10              
    MUL CX                  
    POP CX
    DEC BX
    JMP RET_NORMALIZAR

RET_NORMALIZADO:
    MOV BX, AX              ; BX = Decimal normalizado
    POP DI                  ; DI = Parte entera a retirar

    ; Revisar fondos combinados
    ; Primero chequear enteros
    CMP [BP + OFF_SALDO_ENTERO], DI
    JB  RET_ERROR_MONTO
    
    ; Chequear decimales para ver si ocupamos préstamo
    MOV AX, [BP + OFF_DECIMAL]
    CMP AX, BX
    JAE RET_SIN_PRESTAMO
    
    ; Ocupamos préstamo del entero
    CMP WORD PTR [BP + OFF_SALDO_ENTERO], 0
    JE  RET_ERROR_MONTO ; No hay enteros para prestar
    
    ; Validar que quitando el prestamo y la parte entera no quede negativo
    MOV AX, [BP + OFF_SALDO_ENTERO]
    SUB AX, DI
    CMP AX, 0
    JE  RET_VALIDAR_DECIMAL ; Si queda 0, hay que ver si los decimales alcanzan
    JMP RET_HACER_PRESTAMO

RET_VALIDAR_DECIMAL:
    ; Si los enteros quedan en 0 tras retirar DI, solo podemos retirar si decimales >= BX
    MOV AX, [BP + OFF_DECIMAL]
    CMP AX, BX
    JB  RET_ERROR_MONTO
    JMP RET_SIN_PRESTAMO

RET_HACER_PRESTAMO:
    DEC WORD PTR [BP + OFF_SALDO_ENTERO] 
    MOV AX, [BP + OFF_DECIMAL]           
    ADD AX, 10000                        
    SUB AX, BX                           
    MOV [BP + OFF_DECIMAL], AX           
    JMP RET_RESTAR_ENTERO

RET_SIN_PRESTAMO:
    MOV AX, [BP + OFF_DECIMAL]
    SUB AX, BX
    MOV [BP + OFF_DECIMAL], AX

RET_RESTAR_ENTERO:
    SUB [BP + OFF_SALDO_ENTERO], DI      
    JMP RET_EXITO

; --- MANEJO DE ERRORES RETIRO ---
RET_ERROR_ID:
    LEA DX, MSG_ERROR_NUM
    MOV AH, 09h
    INT 21h
    JMP RET_PEDIR_ID

RET_NO_EXISTE:
    LEA DX, MSG_ERR_ID
    MOV AH, 09h
    INT 21h
    RET

RET_INACTIVA:
    LEA DX, MSG_INACTIVA
    MOV AH, 09h
    INT 21h
    RET

RET_EXITO:
    LEA DX, MSG_OK_RET
    MOV AH, 09h
    INT 21h
    RET

RET_ERROR_MONTO:
    LEA DX, MSG_MONTO_INV
    MOV AH, 09h
    INT 21h
    JMP RET_PEDIR_MONTO

RET_ERROR_MONTO_POP3:
    POP CX
    POP DI
    JMP RET_ERROR_MONTO

RET_ERROR_MONTO_POP:
    POP CX
    POP SI
    JMP RET_ERROR_MONTO

RETIRAR ENDP   

; opcion 4 consultar saldo (pide el id)
CONSULTAR_SALDO PROC                                               ;/////////////////// Consular saldo
 

CS_PEDIR_ID:
    LEA DI, BUF_ID              ; limpiamos el buffer
    MOV CX, 8
    CALL LIMPIAR_BUFFER
    MOV BUF_ID, 6
 
    LEA DX, MSG_CONSULTAR       ; "Inserte ID a consultar:"
    MOV AH, 09h
    INT 21h
 
    LEA DX, BUF_ID              ; leemos el ID
    MOV AH, 0Ah
    INT 21h
 
    CMP BUF_ID+1, 0              ; 
    JE  CS_ERROR_NUM
 
    LEA SI, BUF_ID+2            ; convertimos ASCII a numero
    MOV CL, BUF_ID+1
    CALL ASCII_A_BINARIO
    JC  CS_ERROR_NUM            ; si fallo la conversion, error
 

    ; AX tiene el ID convertido
    CALL BUSCAR_CUENTA          ; busca la cuenta, BP apuntara a ella
    JC  CS_NO_EXISTE            ; CF=1 significa que no se encontro
 

    LEA DX, MSG_SALDO_LABEL     ; "Saldo: "
    MOV AH, 09h
    INT 21h
 
    MOV AX, [BP + OFF_SALDO_ENTERO]  ; AX = parte entera del saldo
    CALL IMPRIMIR_AX                  ; imprimimos la parte entera
 
    LEA DX, MSG_PUNTO           ; imprimimos el punto decimal
    MOV AH, 09h
    INT 21h
 
    MOV AX, [BP + OFF_DECIMAL]  ; AX = parte decimal
    CALL IMPRIMIR_DECIMAL            ; imprimimos los decimales
 
    RET
 

CS_ERROR_NUM:
    LEA DX, MSG_ERROR_NUM       ; "Error: ingrese solo numeros"
    MOV AH, 09h
    INT 21h
    JMP CS_PEDIR_ID             ; reintenta
 
CS_NO_EXISTE:
    LEA DX, MSG_ERR_ID          ; "Error: Cuenta no existe"
    MOV AH, 09h
    INT 21h
    RET
 
CONSULTAR_SALDO ENDP

;busqueda lineal de cuentas
                                                                 ;///////////////////  Buscar cuenta
BUSCAR_CUENTA PROC
    PUSH CX
    PUSH SI

    MOV DI, AX                  ; ? GUARDAMOS el ID a buscar en DI

    XOR SI, SI
    MOV CL, CONT_CUENTAS
    XOR CH, CH

    CMP CX, 0
    JE  BC_NO_ENCONTRADO

BC_LOOP:
    LEA BP, CUENTAS
    ADD BP, SI

    MOV AX, [BP + OFF_ID]       ; ? leemos el ID de la cuenta actual en AX
    CMP AX, DI                  ; ? comparamos con DI (el ID que buscamos)
    JE  BC_ENCONTRADO

    ADD SI, TAM_REGISTRO
    LOOP BC_LOOP

BC_NO_ENCONTRADO:
    STC
    POP SI
    POP CX
    RET

BC_ENCONTRADO:
    CLC
    POP SI
    POP CX
    RET

BUSCAR_CUENTA ENDP

;FUNCION PARA LIMPIAR BUFFER                                 ;///////////////////  Limpiar buffer

LIMPIAR_BUFFER PROC
    PUSH AX             ; guardar AX completo (16 bits)
    PUSH CX             ; guardar CX completo
    PUSH DI             ; guardar DI

    XOR AX, AX          ; AX = 0

LIMPIAR_LOOP:
    MOV [DI], AL        ; escribe byte 0
    INC DI
    LOOP LIMPIAR_LOOP   ; decrementa CX

    POP DI
    POP CX
    POP AX
    RET
LIMPIAR_BUFFER ENDP  

;FUNCIONES PARA VERIFICACIONES
                                                                     ;///////////////////  Verificaciones
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
 
;Imprimir numeros en pantalla (parte entera)
                                                                    ;///////////////////  Imprimir enteros
IMPRIMIR_AX PROC
    MOV BX, 10                   ; divisor para separar digitos
    MOV CX, 0                    ; contador de digitos en stack
 
DIVIDE_LOOP:
    XOR DX, DX                   ; limpiar DX antes de dividir
    DIV BX                       ; AX = AX/10,  DX = residuo (el digito)
    ADD DL, '0'                  ; convertir digito a ASCII
    PUSH DX                      ; guardar digito en stack (al reves)
    INC CX                       ; contar digito
    CMP AX, 0
    JNE DIVIDE_LOOP              ; si AX != 0 seguir dividiendo
 
PRINT_LOOP:
    POP DX                       ; sacar digitos en orden correcto
    MOV AH, 02h                  ; funcion imprimir un caracter
    INT 21h
    LOOP PRINT_LOOP
 
    RET
IMPRIMIR_AX ENDP   

;imprimir parte fraccionaria
                                                              ;///////////////////  Imprimir decimal
IMPRIMIR_DECIMAL PROC
    MOV BX, 10
    MOV CX, 4               ; siempre imprimimos exactamente 4 digitos

IMDEC_DIVIDE:
    XOR DX, DX
    DIV BX                  ; AX = AX/10, DX = residuo
    ADD DL, '0'
    PUSH DX                 ; guardamos digito (al reves)
    DEC CX
    CMP CX, 0
    JNE IMDEC_DIVIDE        ; repetimos exactamente 4 veces

    MOV CX, 4               ; ahora imprimimos los 4 digitos

IMDEC_PRINT:
    POP DX
    MOV AH, 02h
    INT 21h
    LOOP IMDEC_PRINT

    RET
IMPRIMIR_DECIMAL ENDP

END MAIN




