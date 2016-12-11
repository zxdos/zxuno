;;===================================================================================
;; EJEMPLO
;;
;;    Dibujar 8 píxeles en una posición seleccionable de la memoria
;;
;;
;; CÓDIGO MAQUINA
;;
;;  4000 - 2A 20 40 3A 22 40 77 23 77 18 FE
;;  4020 - 20 C0 CA
;;
;; ### EJERCICIO 1:
;;
;;    1 - Abrir Winape
;;    2 - [F7] Abrir el depurador, analizador de memoria
;;    3 - Ampliar la zona de volcado de memoria
;;    4 - Buscar la dirección &4000 
;;    5 - Escribir código máquina en 4000 y 4020
;;    6 - Modificar el registro PC=4000
;;    7 - Cerrar depurador y observar ejecución
;;
;; Resultado: Pinta 8 píxeles de colores rojo, amarillo, azul y fondo
;;            en la mitad de la primera línea de la pantalla
;;
;;    * Observar que CA 11001010 en binario
;;    * Recordar el funcionamiento de los colores 
;;
;;
;; ### EJERCICIO 2:
;;
;;    Trazar paso a paso el ejercicio 1
;;
;;    1 - Repetir pasos 1 al 6 del ejercicio 1
;;    2 - Buscar la dirección &4000 en la zona de desensamblado
;;    3 - [F8] Ejecutar la primera instrucción (2A 00 40  LD HL, (4020))
;;    4 - Observar que el registro HL vale ahora &C020
;;    5 - [F8] Ejecutar la segunda instrucción (3A 02 40  LD  A, (4022))
;;    6 - Observar que el registro A vale ahora &CA
;;    7 - Buscar la dirección &C020 en la zona de volcado de memoria
;;    8 - [F8] Ejecutar la tercera instrucción (77  LD (HL), A)
;;    9 - Observar que la dirección de memoria &C020 (HL) 
;;        ahora contine &CA (A)
;;   10 - [F8] Ejecutar la cuarta instrucción (23  INC HL)
;;   11 - Observar que HL ahora contiene &C021 (siguiente posición)
;;   12 - [F8] Ejecutar la cuarta instrucción (77  LD (HL), A)
;;   13 - Observar que la dirección de memoria &C021 (HL) 
;;        ahora contine &CA (A)
;;
;; ### EJERCICIO 3:
;; 
;;    1 - Cambiar los bytes en &4020 (20 C0 CA) por (20 C8 F0)
;;    2 - Modificar el registro PC=4000
;;    3 - Cerrar el depurador y observar el cambio
;;
;;    * Observar que F0 11110000 en binario
;;    * Observar que CA 11001010 en binario
;;    * Recordar el funcionamiento de los colores 
;;
;; Resultado: Se pintan de amarillo los 4 píxeles que están justo 
;;            debajo de los píxeles dibujados antes
;;
;;
;; ### EJERCICIO 4:
;; 
;;    1 - Repetir el ejercicio 3 pero cambiando los bytes por:
;;        * 20 D0 0F
;;        * 20 D8 CC
;;        * 20 E0 FF
;;        * 20 E8 AA
;;
;; Resultado: Aparece un dibujo de 6x4 píxeles con distintos colores
;;    
;;
;;
;; RETOS
;;
;;    1. Consigue que los 8 píxeles se dibujen al final de la primera 
;;       fila de la pantalla
;;    2. Amplía el programa para que en lugar de 8 píxeles dibuje 16
;;    3. Consigue que los 16 píxeles se dibujen al principio de la 
;;       última fila de la pantalla
;;
;;
;; RETOS CREATIVOS
;;
;;    1. Siguiendo las instrucciones del ejercicio 4, consigue
;;       dibujar la inicial de tu nombre en pantalla en &C370
;;    
;;
;; RETOS AVANZADOS
;;
;;    1. Amplía el programa para que dibuje la inicial de tu nombre
;;       en una sola ejecución, en la posición &C370
;;
;;
;; EXPLICACIONES EN ESTE VÍDEO
;;
;;    * Abrir WinAPE, introducir código y ejecutar
;;    * Depurar código paso a paso (instrucción por instrucción)
;;    * Registro HL e instruccion LD
;;    * Instrucciones de incremento INC
;;    * Acceso a memoria por posición (punteros básicos)
;;
;; EXPLICACIONES EN OTROS VÍDEOS
;;
;;    * La memoria de vídeo: Disposición
;;    * Separación entre código y datos
;;    * Sprites en videojuegos
;;
;;===================================================================================