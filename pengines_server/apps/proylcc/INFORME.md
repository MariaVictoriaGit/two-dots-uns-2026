# Informe — Proyecto Two Dots

## Introducción:
El proyecto se basa en implementar una versión web del juego Two Dots, un juego de tipo puzzles basado en una grilla de puntos de colores. Estos puntos deben ser conectados según sus respectivos colores para ser eliminados, generando distintas reacciones segun la forma de la jugada realizada. Para su desarrollo se utilizo Prolog, para la lógica del juego, y React, para la representación del juego. Combinacion que perimite seprar claramente repsonsabilidades:
- Prolog, como lenguaje representativo del paradigma lógico, se utiliza para modelar el estado del juego y sus comportamientos, por medio de hechos reglas y consultas sobre la grilla. Trabajando bajo estrategias basadas en unificación, recursión y backtracking.
- React se utiliza para construir la interfaz mediante componentes reutilizables, encargandose de representar la grilla y la interacción con el usuario.

## Arquitectura general:
La lógica principal del juego se implementa en el archivo [`proylcc.pl`](/pengines_server/apps/proylcc/proylcc.pl), mientras que la interfaz se desarrolla en React.
    Funcionamiento del `connect/4`: Para reaccionar segun lo deseado se solicita la grilla actual, la cantidad de columnas, el camino seleccionado y los efectos(consecuencias que se le aplicara). Su funcion recae en actuar respecto a la logica establecida como comportamiento de la grilla de puntos, asi valida, determina, adapta y reacciona segun el escenario presentado. Esto lo hace discriminando los tres posible escenarios: camino normal, camino cerrado y camino cerrado con bomba. Tal que el primer caso es contenido por el segundo, que a su vez es contenido por el tercero, asi acumulando requerimientos.
    |-------------------------------|------------------------------|
    | React                         | Prolog                       |
    |-------------------------------|------------------------------|
    | Interfaz gráfica              | Motor lógico                 |
    | Renderiza tablero             | Definimos reglas             |
    | Captura clicks del usuario    | Valida jugadas               |
    | Muestra animaciones           | Modela efectos               |
    |-------------------------------|------------------------------|

La interacción entre React y Prolog se realiza a través del predicado `connect/4`, que recibe la informacion clave tal que funciona como el motor de cada jugada realizando un mapeo entre el exterior y el interior del juego. 

## Implementación en Prolog:
///(decisiones de diseño)(de cada cosa, estrategia, positivo, desafío y casos de prueba)
- Representación de la Grilla:
    En principio, utilizamos la representación de la grilla completa como una lista plana, donde cada posición representa una celda identificada mediante un índice. A partir de `NumOfColumns`, se reconstruyen las relaciones espaciales utilizando operaciones aritméticas sobre dichos índices, en lugar de acceder a posiciones físicas explícitas o por cercanía directa. De modo que, las cercanías se determinan lógicamente, reconociéndose vecinos ortogonales (arriba, abajo, izquierda y derecha) de forma consistente con el paradigma declarativo basado en lógica utilizado en Prolog.
    
    Esta representación permite implementar de forma sencilla mecánicas como la gravedad, la expansión del agua y la validación de paths.

    Aspecto clave: Las celdas no se modelan como objetos, sino como listas de propiedades. Esto permite representar múltiples estados simultáneamente (por ejemplo color, agua o bombas) de forma flexible y extensible. Ademas de que React utiliza esos `Effects` para: actualizar el progreso del nivel, animar objetivos cumplidos y reacciones(en la grilla internamente como visualmente).

- Conexión de puntos:
    La conexión de puntos se basa en la construcción de un camino (Path) formado por índices consecutivos de la grilla. Para que una jugada sea válida, el sistema verifica que cada punto del camino sea adyacente al siguiente y que todas las celdas involucradas compartan el mismo color. La adyacencia se calcula utilizando desplazamientos matemáticos sobre los índices, considerando movimientos ortogonales (arriba, abajo, izquierda y derecha).

    Aspecto clave: `celda_con_color/2`, punto central que discrimina/investiga sobre que estamos trabajando.

- Eliminación:
    La eliminación la definimos como una transformación de la grilla tal que nunca se modifica el estado original, sino que se construye una nueva versión de la misma, asi recorriendo cada celda y decidiendo si debe conservarse, vaciarse o mantener propiedades especiales como agua u obstáculos. 

    Aspecto clave: `nth0/3`, predicado estándar de Prolog que nos facilito la verificacion de la presencia de un elemento en una lista por índice empezando en 0.

- Gravedad:
    La gravedad se implementa mediante una transformación temporal de la representación de la grilla con `grilla_filas/3`, reorganizando la lista plana original en filas que se transponen para representar columnas(`transponer/2`), y asì facilitar el desplazamiento vertical de los puntos. 

- Generación de nuevos puntos(y gestión  de obstaculós):
    La generación de nuevos puntos ocurre dentro del sistema de gravedad, específicamente en `gravedad_columna_con_obstaculos/2`, donde cada columna se reconstruye después de eliminar fichas. La lógica primero extrae las fichas sobrevivientes (Sobrevivientes), ignorando vacíos pero preservando obstáculos [-]. Los espacios vacíos generados son completados con nuevas puntos aleatorias, permitiendo mantener constante el tamaño de la grilla y garantizando la continuidad dinámica del juego tras cada transformación.

    Aspecto clave: `:- use_module(library(random)).`, gran aporte para la gestion de la aleatoriedad, sin tener que definir un patro de apariciones y que `random_member/2` determine que sea una de las opciones que gestionamos.

- Completar los objetivos:
    Los objetivos se gestionan desde el predicado `connect/4`, es decir, desde el coordinador de toda la lógica de cada jugada. Así, a medida que la jugada se va procesando,  va calculando los resultados relevantes (tal que se reduzcan los objetivos faltantes para finalmente finalizar el nivel). Los resualtados relevantes los transforma en eventos `achieved(...)`, que son utilizados por React para actualizar el progreso del nivel, y así sea posible ganar.

    Aspecto clave: Los objetivos se calculan directamente durante la resolución de la jugada en `connect/4`.

- Formas cerradas:

- Bombas:

- Agua:

- Fin del juego: 

## Casos de prueba:



## Aspectos destacados en React
- 

## Funcionalidades adicionales implementadas:
- Vertices del agua

## Desafíos:
- Trabajo sobre las celdas y la distincion de la logica de trabajo tanto si trabajamos sobre la celda, como dentro de la misma. Esta fue una dificultadal incio del trabajo, ya que fue determinante a la hora de afrontar el resto de la logica de trabajo sobre la grilla. 
- Además de la gestión de indices
- Partición en columnas/segmentos
- La expancion del agua con la bomba









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Al probar los casos revisar de cero:(asi desp los metemos en los ejemplos con las capturas)
* encerrar agua
* encerrar obstaculos
* encerrar espacios vacios
* la bomba cae una posicion
* la bomba cae varias posiciones
* la bomba atraviesa huecos
* la bomba es eliminada directamente
* la bomba explota por otra explosion
* bomba en borde superior
* bomba en borde inferior
* bomba en borde izquierdo
* bomba en borde derecho
* bomba en esquina superior izquierda
* bomba en esquina superior derecha
* bomba en esquina inferior izquierda
* bomba en esquina inferior derecha
* los elementos especiales no pueden convertirse en bombas
* espacio aislado
* espacios consecutivos
* espacios en bordes
* expansion de agua cerca de obstaculos

/*
init inicial

init([
	% Fila 0 (índices 0-7)
	[-], [r], [c], [p], [-], [-], [-], [-],
	% Fila 1 (índices 8-15)
	[c], [y], [g], [p], [r], [-], [-], [-],
	% Fila 2 (índices 16-23)
	[r], [r], [g], [y], [r], [g], [-], [-],
	% Fila 3 (índices 24-31)
	[y], [c], [-], [y], [c], [g], [g], [-],
	% Fila 4 (índices 32-39)
	[y, ~], [c, ~], [-], [g], [c, ~], [y, ~], [c, ~], [c],
	% Fila 5 (índices 40-47)
	[c, ~], [c, ~], [-], [g, ~], [c, ~], [y, ~], [c, ~], [-],
	% Fila 6 (índices 48-55)
	[c, ~], [y, ~], [g, ~], [g, ~], [c, ~], [c, ~], [-], [-],
	% Fila 7 (índices 56-63)
	[c, ~], [y, ~], [y, ~], [y, ~], [y, ~], [-], [-], [-],
	% Fila 8 (índices 64-71)
	[-], [y, ~], [y, ~], [y], [-], [-], [-], [-]
], 8, [[r, 10], [g, 10], [p, 15], [~, 21]], 35).
*/