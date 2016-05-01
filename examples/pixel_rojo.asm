;;===================================================================================
;; EJEMPLO
;;
;;    Pintar un pixel de color rojo en la pantalla del Amstrad CPC
;; modificando directamente la memoria de vídeo.
;;
;; * Código para cargar y ejecutar en WinAPE
;; * Explicación del ejemplo y retos al final del código
;;===================================================================================

org &4000         ;; Direccion de memoria &4000 (16384)
                  ;; Todo el codigo se pondra a partir de ahi

ld a, %10001000   ;; Cargar %10001000 en el registro A
                  ;; %10001000 en binario, &88 en hexadecimal, 132 en decimal
                  ;; Los dos bits del primer pixel a 1, el resto a 0. Eso
                  ;; pone el valor binario %11 (3 en decimal) en el primer pixel.
                  ;; Por tanto, el primer pixel tendra el color 3 (Rojo)

ld (&C000), a     ;; Poner contenido del registro A en la direccion 
                  ;; &C000 de memoria (decimal 49152, binario %1100000000000000)


ret               ;; Devolver el control a quien nos haya llamado

;;===================================================================================
;;
;; DIRECTIVAS USADAS
;;
;;    - org :DIRECCIÓN:       >> Establece el ORiGen: posición de memoria donde
;;                            el código de este programa se empezará a escribir
;;
;; INSTRUCCIONES USADAS
;;
;;    - LD  A, :NÚMERO:       >> Introduce un número en el registro A (Acumulador)
;;                            del procesador.
;;
;;    - LD (:DIRECCIÓN:), A   >> Guarda el valor del registro A en la :DIRECCIÓN: de
;;                            memoria indicada.
;;
;;    - RET                   >> Devolver el control al código que nos llamó 
;;                            inicialmente
;;
;; RETOS
;;
;;    1. Pon el color del primer píxel de pantalla en amarillo y azul
;;    2. Pinta 2 píxeles, el primero y el cuarto, de distinto color
;;    3. Pinta los 4 primeros píxeles de pantalla, uno de cada color
;;
;; USO
;;    * Ejecuta el emulador WinAPE (http://www.winape.net)
;;    * Pulsa F3 para abrir el editor de código fuente
;;    * Crea un nuevo fichero con File/New y copia el código de este ejemplo
;;       - (Alternativamente, abre este fichero con File/Open)
;;    * Pulsa F9 para ensamblar el código en la dirección &4000 de memoria
;;    * Cierra el editor y teclea "CALL &4000" en el Amstrad CPC para ejecutar
;;
;; EXPLICACIÓN
;;
;;    Para pintar un píxel en un Amstrad CPC hay que modificar la zona de memoria 
;; donde se guarda el color que ese píxel tiene. En MODO 1 de pantalla (el modo 
;; por defecto del Amstrad CPC), la pantalla tiene 320x200 píxeles y cada píxel 
;; se almacena en memoria como 2 bits. 
;;
;;    La zona de memoria donde se almacenan los píxeles es la que va de la 
;; dirección &C000 en hexadecimal (48000 en decimal) hasta &FFFF (65535). Cada 
;; posición de memoria tiene 8 bits (1 byte) y almacena los colores para 4 píxeles.
;; Los 8 bits tienen este aspecto:
;;
;;    8 bits, 1 Byte: [ A B C D a b c d ]   Píxel 0: %Aa   Pixel 1: %Bb
;;                                          Píxel 2: %Cc   Píxel 3: %Dd
;;
;;    Un ejemplo para entender el diagrama de arriba:
;;
;;       La posición &C000 de memoria contiene el byte [01011011]. Así pues,
;;       los valores de los 4 primeros píxeles son
;;          * Píxel 0 = [0___1___] = %01 en binario, 1 en decimal (Color 1)
;;          * Píxel 1 = [_1___0__] = %10 en binario, 2 en decimal (Color 2)
;;          * Píxel 2 = [__0___1_] = %01 en binario, 1 en decimal (Color 1)
;;          * Píxel 3 = [___1___1] = %11 en binario, 3 en decimal (Color 3)
;;       Por tanto, los primeros 4 píxeles de pantalla tienen colores 1, 2, 1 y 3
;;       
;;===================================================================================
