;;===================================================================================
;; EJEMPLO
;;
;;    Cambiar colores de la paleta y el borde de pantalla
;;
;;
;; CÓDIGO MAQUINA
;;
;;  4000 - 3E 00 06 09 0E 09 CD 38 BC 18 FE
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
;; Resultado: El color del fondo de pantalla (0) cambia a verde
;;
;;
;;
;; ### EJERCICIO 2:
;; 
;;    1 - Repetir los pasos del ejercicio 1, pero modificar
;;        los bytes 4º y 6º (09) por (0F)
;;
;; Resultado: El color de fondo de pantalla (0) cambia a naranja
;;
;;
;;
;; ### EJERCICIO 3:
;; 
;;    1 - [Ctrl + F9] Reiniciar el CPC
;;    2 - Repetir los pasos del ejercicio 1, pero modificar
;;        el 2º byte (00) por (01)
;;
;; Resultado: El color del texto (1) cambia a verde
;;
;;
;;
;;
;; RETOS BASE
;;
;;    1. Consigue cambiar a fondo negro y letras blancas
;;    2. Consigue que las letras parpadeen entre azul y magenta
;;
;;
;; RETOS PLUS
;;
;;    3. Amplía el programa para que pinte los 12 primeros píxeles de pantalla,
;;       4 de cada color (1-amarillo, 2-cian, 3-rojo), justo antes de cambiar
;;       los colores así:
;;       3.1. Cambia el color 3 (rojo) por negro
;;       3.2. Cambia el color 2 (cian) por gris
;;       3.3. Cambia el color 1 (amarillo) por blanco
;;       3.4. Cambia el color de fondo (azul) por rojo-oscuro
;;    4. Cambia también el color del borde de pantalla a rojo-oscuro. 
;;       Utiliza la función BC32.
;;
;; RETOS CREATIVOS
;;
;;    5. Haz un programa que dibuje la bandera de Italia.
;;
;;
;; EXPLICACIONES EN ESTE VÍDEO
;;
;;    * Abrir WinAPE, introducir código y ejecutar
;;    * Depurar código paso a paso (instrucción por instrucción)
;;
;; EXPLICACIONES EN OTROS VÍDEOS
;;
;;    * La paleta: qué es
;;    * La paleta: funcionamiento
;;    * La instrucción Call (CD) y las llamadas
;;    * Funciones del Firmware
;;    * Las funciones SCR_SET_INK y SCR_SET_BORDER
;;
;;===================================================================================
