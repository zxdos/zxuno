;;===================================================================================
;; EJEMPLO
;;
;;    Pintar de colores los 4 primeros píxeles de la pantalla
;;
;;
;; CÓDIGO MAQUINA
;;
;;    3E 88 32 00 C0 18 FE
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
;; Resultado: Se pinta de rojo el primer píxel de la pantalla
;;
;;
;;
;; ### EJERCICIO 2:
;; 
;;    1 - [Ctrl + F9] Reiniciar el CPC
;;    2 - Repetir los pasos del ejercicio 1, pero modificar
;; el 2º byte (88) por (11)
;;    3 - Repetir pasos 1 y 2 para los valores (44) y (22)
;;
;;    * Observar que 88 es 10001000 en binario
;;    * Observar que 44 es 01000100 en binario
;;    * Observar que 22 es 00100010 en binario
;;    * Observar que 11 es 00010001 en binario
;;
;; Resultado: Se pintan de rojo los pixeles del 2º al 4º
;;
;;
;;
;; ### EJERCICIO 3:
;; 
;;    1 - Repetir los pasos del ejercicio 2 8 veces, para 
;; probar las 8 combinaciones de 1 bit a 1 y los otros 7 a cero.
;; (10000000, 01000000, 00100000, 00010000,....).
;;
;;    * Observar los valores binarios y hexadecimales
;;
;; Resultado: Los 4 primeros píxeles se pintan primero de color
;; cian, y luego de color amarillo.
;;
;;
;;
;; RETOS
;;
;;    1. Pinta los 4 primeros píxeles de rojo a la vez
;;    2. Ahora los 4 píxeles de color amarillo y cian
;;    3. Pinta los 4 primeros píxeles uno de cada color 
;;       (fondo, amarillo, cian y rojo)
;;
;;
;;
;; EXPLICACIONES EN ESTE VÍDEO
;;
;;    * Abrir WinAPE, introducir código y ejecutar
;;    * Depurar código paso a paso (instrucción por instrucción)
;;
;; EXPLICACIONES EN OTROS VÍDEOS
;;
;;    * Entendiendo binario y hexadecimal
;;    * Ciclo de ejecución del procesador
;;    * Instrucciones LOAD (LD), registros y memoria
;;    * La instrucción de salto relativo JR
;;    * Números negativos: complemento a 2
;;    * La memoria de vídeo: Funcionamiento
;;    * La memoria de vídeo: Codificación de los píxeles
;;    * Direcciones de memoria: Little endian y Big Endian
;;
;;===================================================================================