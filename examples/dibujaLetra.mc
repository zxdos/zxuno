;;===================================================================================
;; EJEMPLO
;;
;;    Escribir una letra en pantalla usando código máquina
;;
;; PASOS
;;
;;    1 - Abrir Winape
;;    2 - [F7] Abrir el depurador, analizador de memoria
;;    3 - Ampliar la zona de volcado de memoria
;;    4 - Buscar la dirección &4000 
;;    5 - Escribir código máquina en la dirección 4000
;;    6 - Cerrar el depurador
;;    7 - Ejecutar el código introducido con CALL &4000
;;
;; CÓDIGO MAQUINA
;;
;;    3E 42 CD 5A BB C9
;;
;; RETOS
;;    1. Consigue que el código pinte la letra C en lugar de la B.
;;    2. Búsca el código ASCII en el manual de Amstrad CPC y modifica el
;;       código para dibujar un carácter con el dibujo de un muñequito.
;;    3. Añade más órdenes para que el código escriba "HOLA MUNDO!"
;;
;; EXPLICACIÓN
;;
;;    1 - Tras ejecutar "CALL &4000", el procesador se prepara para ejecutar las
;;        órdenes que se encuentren a partir de la posición &4000 (16384 en decimal).
;;
;;    2 - El procesador lee el primer byte (&3E en hexadecimal, 62 en decimal, 
;;        %00111110 en binario)
;;
;;        - &3E es una órden para el procesador que significa "Mete en el registro A, 
;;          el valor que hay en la siguiente posición de memoria". Abreviadamente, 
;;          se indica como "LD A, :VALOR:" (Load :VALOR: in A, Cargar :VALOR: en A).
;;          :VALOR: se refiere al valor que hay en el siguiente byte de la memoria.
;;
;;    3 - El procesador lee el segundo byte (&42 = 66 = %01000010) y lo guarda en el
;;        registro A (Acumulador).
;;
;;    4 - Terminada la primera órden, el procesador lee el tercer byte, que tiene la
;;        siguiente órden (&CD = 205 = %11001101)
;;
;;        - &CD significa continuar ejecutando órdenes a partir de la posición de 
;;          memoria indicada en los 2 siguientes bytes. Además, cuando esa ejecución
;;          encuentre la órden &C9, volverá aquí para seguir ejecutando las órdenes 
;;          a partir de la posición siguiente (el primer byte después de la dirección
;;          de memoria, después de los 2 siguientes). Esta órden se indica abreviadamente
;;          como "CALL :DIRECCIÓN:" (Invocar :DIRECCIÓN:).
;;
;;    5 - El procesador obtiene los 2 siguientes bytes de la memoria, &5A y &BB, y 
;;        los junta para formar la dirección de memoria* (&BB5A = 47962 = %1011101101011010)
;;        A continuación, "salta" a esa dirección: es decir, continúa ejecutando 
;;        órdenes a partir de la dirección &BB5A. 
;;
;;        - Las órdenes a partir de la dirección &BB5A lo que hacen es dibujar en 
;;          pantalla el carácter cuyo número identificador sea el que indica el 
;;          registro A. En este caso, como A contiene el valor 66, y el 66 es el 
;;          identificador de la letra "B" en el código ASCII, las órdenes terminan 
;;          pintando una B en pantalla, después llega la órden &C9 y la ejecución 
;;          vuelve a este paso, para continuar justo después de los valores &5A &BB,
;;          es decir, en la siguiente órden de esta línea de ejecución.
;;
;;    6 - Tras terminar de dibujar la letra B en pantalla y volver de ejecutar 
;;        código en la dirección &BB5A, el procesador lee el siguiente byte de
;;        memoria, que tiene la órden (&C9 = 201 = %11001001)
;;
;;        - &C9, como ya hemos dicho antes es la órden para volver al código que
;;          nos invocó en primer lugar. Del mismo modo que nosotros hemos invocado
;;          el código en &BB5A, otro código habrá invocado el nuestro. Así pues,
;;          cuando ya hemos terminado, ponemos esta órden para que la ejecución
;;          continúe por donde iba antes de invocarnos.
;; 
;; (*) Cuando el procesador Z80 junta valores de varios bytes en memoria para hacer 
;; con ellos un único número más grande, siempre lo hace "de derecha a izquierda". 
;; A esto se le llama "formato Little Endian" y quiere decir que los valores se 
;; guardan en memoria de menor a mayor importancia. En el número &BB5A, el valor &5A 
;; tiene menos importancia (vale menos cantidad), que el valor &BB, ya que &BB en 
;; realidad vale &BB00 de modo que &BB00 + &5A = &BB5A. Los procesadores Intel usan 
;; el mismo formato, pero otros procesadores usan el formato "Big Endian", que tiene 
;; el órden contrario.
;;===================================================================================