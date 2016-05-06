;;===================================================================================
;; EJEMPLO
;;
;;    Pintar un pixel de color rojo en la pantalla del Amstrad CPC
;; modificando directamente la memoria de vídeo.
;;
;; * Código para cargar y ejecutar en WinAPE
;; * Explicación del ejemplo, uso, ejercicios y retos después del código.
;;===================================================================================

org &4000         ;; Direccion de memoria &4000 (16384)
                  ;; Todo el codigo se guardará a partir de ahi

ld a, %10001000   ;; Poner el valor %10001000 en el registro A (A = %10001000)
                  ;; %10001000 es un número binario equivalente al número 132 decimal

ld (&C000), a     ;; Guardar el valor del registro A en la direccion &C000 de memoria
                  ;; Después de esta instrucción, la posición &C000 tendrá almacenado
                  ;; el valor %10001000, que es lo que hay ahora almacenado en A.

ret               ;; Devolver el control a quien nos haya invocado

;;===================================================================================
;;
;;;;;;INSTRUCCIONES DE USO
;;
;;    * Ejecuta el emulador WinAPE (http://www.winape.net)
;;    * Pulsa F3 para abrir el editor de código fuente
;;    * Crea un nuevo fichero con File/New y copia el código de este ejemplo
;;       - (Alternativamente, abre este fichero con File/Open)
;;    * Pulsa F9 para ensamblar el código en la dirección &4000 de memoria
;;    * Cierra el editor y teclea CALL &4000 en el Amstrad CPC para ejecutar
;;
;;    NOTAS IMPORTANTES: 
;;
;;       1. Cada vez que modifiques el código en el editor, deberás pulsar F9 
;;       para ensamblar. Si no lo haces, tus cambios no se introducirán en 
;;       la memoria del Amstrad CPC. Presta atención cuando lo hagas porque
;;       si has cometido algún error, aparecerá indicado.
;;
;;       2. Cuando llenes la pantalla poniendo CALL &4000 varias veces, las
;;       letras se desplazarán hacia arriba. En ese momento, escribe MODE 1
;;       para limpiar la pantalla. De lo contrario, la posición de memoria 
;;       &C000 ya no se referirá a los 4 primeros píxeles de pantalla.
;;
;;;;;;EJERCICIOS
;;
;;    1. Cambia la instrucción "ld a, %10001000" por las siguientes variantes
;; y comprueba lo que sucede con el píxel 0 de pantalla en cada caso.
;;
;;       * ld a, %00000000
;;       * ld a, %00001000
;;       * ld a, %10000000
;;       * ld a, %10001000
;;
;;       - Presta atención a los 2 únicos bits que se han modificado en el 
;;       ejercicio anterior. Esos dos bits (el bit 7 y el bit 3) son los que 
;;       almacenan el color del píxel 0. Sólo hay 4 combinaciones para estos
;;       2 bits: 00, 01, 10, 11. Por tanto, sólo hay 4 colores distintos.
;;
;;    2. Siguiendo la lógica del ejercicio 1, los bits 6 y 2 almacenan el 
;; color del píxel 1. Modifica 4 veces el código para conseguir pintar el 
;; píxel 1 de los 4 colores posibles, uno cada vez.
;;
;;    3. Haz pruebas y descubre qué 2 bits guardan el color del píxel 2,
;; y qué otros dos guardan el color del píxel 3.
;;
;;;;;;RETOS INICIALES
;;
;;    1. Pinta 2 píxeles, el 0 y el 3, de distinto color. Los píxeles
;;       1 y 2 deben quedar del color del fondo.
;;    2. Pinta una línea de color amarillo con los 4 primeros píxeles
;;       de pantalla.
;;    3. Pinta los 4 primeros píxeles de pantalla, uno de cada color.
;;
;;;;;;DIRECTIVAS USADAS
;;
;;    - org :DIRECCIÓN:       >> Establece el ORiGen: posición de memoria donde
;;                            el código de este programa se empezará a escribir
;;
;;;;;;INSTRUCCIONES USADAS
;;
;;    - LD  A, :NÚMERO:       >> Introduce un número en el registro A (Acumulador)
;;                            del procesador.
;;
;;    - LD (:DIRECCIÓN:), A   >> Guarda el valor del registro A en la :DIRECCIÓN:
;;                            de memoria indicada.
;;
;;    - RET                   >> Devolver el control al código que nos llamó 
;;                            inicialmente
;;
;;;;;;EXPLICACIÓN
;;
;;    Los monitores de Amstrad CPC se refrescan (cambian su contenido)
;; 50 veces por segundo. Cada vez que lo hacen, leen de la memoria del
;; ordenador qué colores deben ser pintados en cada píxel. 
;;
;;    Pintar un píxel es tan sencillo como modificar la zona de memoria
;; donde se guarda el color que debe tener ese píxel. Esta zona depende
;; del MODO de vídeo en que se encuentre el Amstrad CPC. En MODO 1 (el 
;; modo por defecto) hay 320x200 píxeles y cada píxel utiliza 2 bits
;; de memoria para almacenarse.
;;
;;    La zona de memoria donde se almacenan todos esos colores empieza
;; en la dirección &C000 (49152), y termina en la dirección &FFFF (66535). 
;; Cada posición de memoria tiene 8 bits (1 byte) por lo que guarda 
;; 4 píxeles (2 bits para cada uno). 
;;
;;    Por ejemplo, como hemos visto en el ejercicio, el byte de la 
;; dirección &C000 guarda los 4 primeros píxeles de pantalla. El byte
;; siguiente (dirección &C001) guardará los 4 siguientes, etcétera.
;;
;;    Los bits que corresponden a cada píxel tienen un órden particular,
;; como puede verse en el siguiente diagrama:
;;
;;    1 Byte, 8 bits, 4 píxeles: [########], cada # puede ser un 0 o un 1.
;;                                76543210  <- número de bit
;;
;;       * Píxel 0, bits 3 y 7: [_###_###]
;;       * Píxel 1, bits 2 y 6: [#_###_##]
;;       * Píxel 2, bits 1 y 5: [##_###_#]
;;       * Píxel 3, bits 0 y 4: [###_###_]
;;
;;    Supongamos que guardamos el valor %01011011 en la posición &C000. 
;; ¿Qué color tendrá cada píxel?
;;
;;       * Píxel 0, bits 3 y 7: [0###1###] = %10 = Color 2
;;       * Píxel 1, bits 2 y 6: [#1###0##] = %01 = Color 1
;;       * Píxel 2, bits 1 y 5: [##0###1#] = %10 = Color 2
;;       * Píxel 3, bits 0 y 4: [###1###1] = %11 = Color 3
;;
;;    Es importante indicar que los bits se leen de derecha a izquierda, 
;; y por eso [0###1###] corresponde al valor %10 en binario (2 en decimal).
;;       
;;;;;;RETOS CREATIVOS
;;
;;    1. Prueba a colorear a tu gusto la primera línea de la pantalla.
;;       Necesitarás añadir más código para ir pintando los 160 píxeles
;;       que tiene.
;;
;;    2. Prueba a colorear los píxeles siguientes a la primera línea
;;       de pantalla y observa en qué línea aparecen. 
;;
;;    3. Rellena toda la pantalla de un mismo color (o de varios, a tu
;;       gusto). Recuerda que debes rellenar desde &C000 hasta &FFFF.
;;       Observa cómo se rellena la memoria cuando ejecutes.
;;
;;    4. Ve rellenando las líneas de pantalla una por una y fíjate
;;       en qué posición ocupan. Intenta hacerte un mapa o una tabla
;;       para saber qué direcciones usar cuando quieras pintar en una
;;       línea concreta de la pantalla.
;;
;;    5. Intenta hacer un pequeño dibujo (de 4x4 píxeles o de 8x8, por
;;       ejemplo). Con esto puedes poner a prueba el mapa o tabla que 
;;       has elaborado en el anterior reto.
;;
;;===================================================================================
