;;===================================================================================
;; EJEMPLO
;;
;;    Hacer dibujos pintando píxeles en una matriz de 8x4
;;
;;
;; CÓDIGO MAQUINA
;;
;;  4000 - 21 F0 F0 22 00 C0 21 0F 0F 22 00 C8 21 00 00 22 
;;  4010 - 00 D0 21 FF FF 22 00 D8 18 FE 
;;
;;
;;
;; ### EJERCICIO 1:
;;
;;    1 - Abrir Winape
;;    2 - [F7] Abrir el depurador, analizador de memoria
;;    3 - Ampliar la zona de volcado de memoria
;;    4 - Buscar la dirección &4000 
;;    5 - Escribir código máquina en la dirección 4000
;;    6 - Modificar el registro PC=4000
;;    7 - Cerrar depurador y observar ejecución
;;
;; Resultado: Se pinta un mini sprite de colores amarillo, 
;; cian, azul y rojo, en vertical, 8x4 píxeles.
;;
;;
;;
;; ### EJERCICIO 2:
;;
;;    Trazar paso a paso el ejercicio 1
;;
;;    1 - Repetir pasos 1 al 6 del ejercicio 1
;;    2 - Buscar la dirección &C000 en la zona de volcado de memoria
;;    3 - Buscar la dirección &4000 en la zona de desensamblado
;;    4 - [F8] Ejecutar la primera instrucción (21 F0 F0  LD HL, F0F0)
;;    5 - Observar que el registro HL vale ahora &F0F0
;;    6 - [F8] Ejecutar la segunda instrucción (22 00 0C  LD (C000),HL)
;;    7 - Observar que los 2 bytes en C000 y C001 ahora valen F0 F0
;;    8 - Buscar la dirección &C800 en la zona de volcado de memoria
;;    9 - Repetir pasos 4 a 6 y observar los valores
;;   10 - Buscar la dirección &D000 en la zona de volcado de memoria
;;   11 - Repetir pasos 4 a 6 y observar los valores
;;   12 - Buscar la dirección &D800 en la zona de volcado de memoria
;;   13 - Repetir pasos 4 a 6 y observar los valores
;;   14 - Observar que la ejecución de 18 FE deja la máquina parada
;;
;;
;;
;; ### EJERCICIO 3:
;; 
;;    1 - Cambiar los 3 primeros bytes (21 F0 F0) por (21 FF FF)
;;    2 - Modificar el registro PC=4000
;;    3 - Cerrar el depurador y observar el cambio
;;
;;    * Observar que F0 F0 es 11110000 11110000 en binario
;;    * Observar que FF FF es 11111111 11111111 en binario
;;    * Recordar el funcionamiento de los colores 
;;
;; Resultado: La primera fila del sprite pasa de amarilla a roja
;;
;;
;;
;; ### EJERCICIO 4:
;; 
;;    1 - Modificar las 4 parejas de bytes que hay tras las 
;;        instrucciones 21 (F0 F0, 0F 0F, 00 00, FF FF) por
;;        (FF F0, F0 FF, FF F0, F0 FF)
;;    2 - Modificar el registro PC=4000
;;    3 - Cerrar el depurador y observar el resultado
;;
;; Resultado: Aparece un patrón rojo y amarillo parecido a un mantel
;;    
;;
;;
;; RETOS
;;
;;    1. Dibuja un símbolo de = de color amarillo
;;    2. Dibuja 2 franjas verticales de colores amarillo y cian
;;    3. Dibuja una reja vertical de color rojo
;;
;;
;; RETOS CREATIVOS
;;
;;    1. Dibuja una cara y compártela
;;    2. Haz un dibujo original y compártelo
;;
;;
;; RETOS AVANZADOS
;;   
;;    1. Amplía el programa para que el dibujo sea de 16x16 píxeles 
;;       y aparezca en el centro de la pantalla. 
;;
;;
;; EXPLICACIONES EN ESTE VÍDEO
;;
;;    * Abrir WinAPE, introducir código y ejecutar
;;    * Depurar código paso a paso (instrucción por instrucción)
;;    * Registro HL e instruccion LD
;;
;; EXPLICACIONES EN OTROS VÍDEOS
;;
;;    * La memoria de vídeo: Disposición
;;    * Sprites en videojuegos
;;
;;===================================================================================