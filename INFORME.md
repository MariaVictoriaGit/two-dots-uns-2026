# Informe — Proyecto Two Dots

## 1) Introducción:

El proyecto se basa en implementación web del juego **Two Dots**, un juego de tipo **puzzles** basado en una grilla de puntos de colores. Estos puntos deben ser conectados según sus respectivos colores para ser eliminados, generando distintas reacciones según la forma de la jugada realizada.

Para su desarrollo se utilizaron dos tecnologías principales:
- **Prolog**, para la lógica del juego,
- **React**, para la representación visual y la interacción con el usuario del juego.

Esta combinación que permite separar claramente responsabilidades:
- Prolog, como lenguaje representativo del paradigma lógico, se utiliza para modelar el estado del juego y sus comportamientos, por medio de hechos reglas y consultas sobre la grilla. Trabajando bajo estrategias basadas en unificación, recursión y backtracking.
- React, se utiliza para construir la interfaz mediante componentes reutilizables, encargándose de representar la grilla y la interacción con el usuario.

## 2) Arquitectura general:
La lógica principal del juego se implementa en el archivo [`proylcc.pl`](/pengines_server/apps/proylcc/proylcc.pl), mientras que la interfaz se desarrolla en React.

La comunicación entre las dos capas se realiza mediante el predicado `connect/4`, que recibe la información clave tal que funciona como el motor de cada jugada realizando un mapeo entre el exterior y el interior del juego.

Principalmente gestionando que se verifique un camino válido de un único color, para posteriormente reaccionar según corresponda(camino abierto cerrado o camino cerrado con puntos internos para bombas). Asì de forma ordenada, una vez reacciono como corresponde según el caso, se aplica la gravedad y en caso de poseer bombas, las mismas explotan.

## 3) Implementación en Prolog:

### 3.1) Representación de la grilla:

En principio, utilizamos la representación de la grilla completa como una lista plana unidimensional, donde cada posición representa una celda identificada mediante un índice. A partir de `NumOfColumns`, se reconstruyen las relaciones espaciales utilizando operaciones aritméticas sobre dichos índices, en lugar de acceder a posiciones por cercanía directa. De modo que, la proximidad se determinan lógicamente, determinando si son vecinos ortogonales (arriba, abajo, izquierda y derecha),asì optimizando el rendimiento la validación de caminos (`camino_valido`), la simulación de la gravedad y expansión geométrica del agua.

#### Aspecto destacado:

Las celdas no se modelan como objetos, sino como listas de propiedades. Esto permite representar múltiples estados simultáneamente (por ejemplo color, agua ([color, agua]) o bombas([color, bomba])) de forma flexible y extensible. Además de que React utiliza esos `Effects` para: actualizar el progreso del nivel, animar objetivos cumplidos y reacciones (en la grilla internamente como visualmente).

### 3.2) Conexión de puntos:

La conexión de puntos se basa en la construcción de un camino (`Path`) formado por índices numéricos consecutivos sobre la grilla plana. Para que una jugada sea válida, el sistema verifica que cada punto del camino sea obligatoriamente adyacente al siguiente y que todas las celdas involucradas compartan el mismo color. La adyacencia se calcula utilizando desplazamientos matemáticos sobre los índices, considerando movimientos ortogonales.

#### Aspecto destacado:

El predicado `celda_con_color/2` es el encargado de discriminar/investiga el contenido de cada celda ([Color | Modificadores]) (por ejemplo, aislando el color de modificadores ambientales (`agua` u `obstáculos`)), así garantizando sobre qué elemento se está operando antes de aprobar la validez de la conexión.

### 3.3) Eliminación de puntos:

La eliminación la definimos como una transformación de la grilla tal que nunca se modifica el estado original, sino que se construye una nueva versión de la misma, así recorriendo cada celda. Durante este proceso, el sistema discrimina si el contenido de una celda debe conservarse intacto, vaciarse por completo (sustituyéndolo por una lista vacía `[]`) o preservar sus propiedades físicas y ambientales estructurales, tales como la presencia de agua (`~`) o bloques infranqueables (`-`).

#### Aspecto destacado:

Para la manipulación de la grilla inicialmente se usó `nth0/3`, un predicado estándar de Prolog que permite indexar, verificar y extraer elementos basados en un índice con base cero. Fundamental para validar la correspondencia entre los índices del camino y las coordenadas reales. Más posteriormente se comparó `nth0/3` y `nth0/4`, de modo que optamos por `nth0/4` gracias a que el predicado anterior solamente servía para consultar o leer, mientras que el actual también transforma.

### 3.4) Gravedad:

La gravedad se implementó por medio de aislamiento, así reestructurando temporalmente la lista plana de la grulla. Por medio del predicado `grilla_filas/3` en combinación con un algoritmo de transposición de matrices (`transponer/2`) se obtienen las distintas columnas independientes que se visualizan en el juego. Esto permite simplificar el procesamiento para recorrerlas y gestionar la situación interna de las mismas, así desplazando los casilleros vacíos (`[]`) hacia el extremo superior, tal que se rellenen las posiciones por inyección aleatoria de nuevos puntos. Una vez llenas las columnas, vuelve a transponer y aplana reconstruyendo el formato original de la grilla.

#### Aspecto destacado:

La lógica de la gravedad funciona independiente de la interfaz gráfica, más se mantienen en sincronía. Al caer en Prolog se le comunica a React el estado intermedio con la información `[cae]`, esto permite que la interfaz represente los cambios de posición y cuáles son las animaciones correspondientes a producirse.

### 3.5) Generación de nuevos puntos:

La generación de nuevos puntos ocurre dentro de la gestión de la gravedad. Ocurre una vez que se sedimentan todos los puntos no eliminados en el extremo inferior de las columnas, se calcula la cantidad de espacios vacantes por cada columna. Usando la aleatoriedad provista por `library(random)` se obtendrán nuevos puntos de colores (respetando el conjunto de posibles valores para los colores). Garantiza que no queden celdas sin un color asignado, salvo que sean obstáculos.  

#### Aspecto destacado:
Al realizar la inyección sobre la estructura de columnas transpuestas se evitan errores de índices respecto a la grilla original cuando se recupera la forma de única lista de la grilla.

### 3.6) Gestión de obstáculos:

Los obstáculos se representan mediante `[-]`. Se diferencian del resto de celdas de la grilla ya que no se podrán utilizar sin modificar frente a ninguna circunstancia. Desde la validación del camino en `camino_valido/3` se gestiona un rechazo instantáneo ante el intento de interactuar con él. Funcionan como barreras.

### 3.7) Objetivos del nivel:

Los objetivos se gestionan desde el predicado `connect/4`, que coordina toda la lógica asociada a una jugada. Durante su ejecución, el sistema calcula los resultados relevantes de la conexión realizada y actualiza el progreso de los objetivos del nivel. Estos resultados se transforman en eventos `achieved(...)`, que son utilizados por React para actualizar los contadores y mostrar el avance del jugador. Cuando todos los objetivos son completados, el nivel puede darse por finalizado.

#### Aspecto destacado:

Los objetivos se calculan directamente durante la resolución de la jugada en `connect/4`, antes de aplicar otros efectos como la gravedad o la generación de nuevas fichas.

### 3.8) Formas cerradas:

Las formas cerradas constituyen uno de los puntos claves para el funcionamiento del juego, tal que se busca detectar desde el `connect/4`. A estas se las detecta inicialmente en el predicado `es_cerrado/1`, el cual evalúa recursivamente la lista de índices del camino (`Path`) para verificar si alguna coordenada se repite en el recorrido, verificando la existencia de un bucle. Entonces, en caso afirmativo se procede a eliminar todos los puntos de el color correspondiente por medio de `eliminar_color/7`, se evalúa y realiza la expansión del agua correspondiente (en las zonas que sea necesario expandirse), antes de finalmente aplicarse los efectos de la eliminación ejecutando la gravedad.

#### Aspecto destacado:

El procesamiento de una forma cerrada constituye la única condición del juego para crear bombas. Durante la transformación masiva de la grilla, el motor de Prolog calcula una coordenada de anclaje dentro del perímetro del bucle para inyectar el modificador estructurado `[Color, bomba]`.

### 3.9) Bombas:

Las bombas constituyen un mecanismo central dentro de la lógica de formas cerradas del juego. Cuando un camino resulta ser cerrado, el sistema detecta automáticamente todas las posiciones encerradas mediante un algoritmo de *Flood Fill*. Toda forma cerrada de dimensiones iguales o mayores a 3×3 genera bombas en las celdas atrapadas, transformando dichas posiciones mediante el predicado `colocar_bombas_en_grid/3`.

Una vez creadas las bombas, el sistema aplica la gravedad sobre la grilla. Posteriormente, las bombas explotan automáticamente y, tras la detonación, se ejecuta nuevamente la gravedad para rellenar los espacios vacíos generados por la explosión.

La lógica principal de este proceso se encuentra concentrada en el predicado `explosionar_bomba/5`, el cual integra simultáneamente la eliminación de puntos, la propagación de agua, la actualización de objetivos y la aplicación de una gravedad secundaria.

Al gatillar la detonación, por medio del predicado `indices_en_cruz/4` se determinan las celdas que son vecinas a la bomba, y utilizando la constante `NumOfColumns`, el sistema determina de forma exacta el conjunto de índices alcanzados por la onda expansiva, correspondiente a un área de impacto de 3×3. Tal que finalmente explota y se aplica por segunda vez la gravedad. Finalizando el ciclo de vida de la bomba.

### 3.10) Agua:

El agua se modela como una propiedad especial que complementa las celdas con puntos. La eliminación de el punto en la celda sin agua que sea vecina ortogonal a una celda con agua, ya sea por un camino válido, bomba o power up, la eliminación ocasionará un cambio permanente en esa celda. Además, la expansión del agua computa de forma inmediata nuevos logros hacia los objetivos de la partida.

#### Aspecto destacado:

Se incorporaron los predicados: `tiene_agua/1` y `es_obstaculo/1` como capa de abstracción sobre la representación interna de la grilla. Gracias a esta decisión, si en el futuro se modifica la forma de representar agua u obstáculos, únicamente será necesario actualizar dichos predicados sin afectar el resto de la lógica del sistema.

### 3.11) Fin del juego:

El estado de la partida se controla mediante la interacción entre Prolog y React.

#### 3.11.1) **Flujo de Victoria:**

Se produce una vez todos los objetivos del nivel fueron satisfechos, entonces se finaliza la partida.

#### 3.11.2)**Flujos de Derrota:**

Ocurre en dos situaciones:
   
#### 3.11.2.1)**Sin movimientos restantes:**

El contador de movimientos llegó a cero.

#### 3.11.2.2)**Sin jugadas posible(deadlock):**

Esta es una situación clave, ya que tanto por la generación aleatoria de puntos como los posibles formatos de niveles se debía plantear un caso en el que ya no se pudiera actual. Cuando ya no existen combinaciones válidas en la grilla `hay_movimientos/2`, tal que envía la marca `[deadlock]` dentro de los efectos generados, y React finaliza la partida automáticamente mostrando la pantalla de derrota.

Además es importante aclarar el intento de recuperación automática: 

Antes de declarar una derrota definitiva, el sistema intenta recuperar la partida mediante una mezcla automática del tablero. Para ello se utilizan los predicados `mezclar_grilla_segura/3` y `intentar_mezclar/4`

La mezcla reorganiza aleatoriamente las fichas manteniendo intactos obstáculos y celdas con agua. Posteriormente se verifica nuevamente la existencia de movimientos posibles.

Entonces, si después de varios intentos continúa sin existir ninguna jugada válida, se genera el evento `[deadlock]` que React interpreta como una condición inmediata de derrota.

#### Aspecto destacado:

La lógica de detección y recuperación se enfoca en `juntar_efectos_con_mezcla/4` permitiendo realizar un comportamiento donde se intenta salvar automáticamente una partida bloqueada antes de darla por perdida.

## 4) Casos de Prueba generales:

### 4.1) :

### 4.2) :

### 4.3) :

### 4.4) :

### 4.5) :

### 4.6) :

### 4.7) :

### 4.8) :

### 4.9) :

### 4.10) :

## 5) Aspectos modificados(Nuevas funcionalidades en Prolog):

### 5.1) Generación de nuevos niveles:

Alteración del archivo init: no se ha modificado el esquema de representación de la grilla en el archivo `init.pl`. Lo que se modifica es el generación de niveles, tal que se pre definieron unos niveles iniciales y un generador de niveles dinámicos para los niveles superiores. Para los niveles generados automáticamente, se incorpora lógica de aleatorización para crear puntos, obstáculos y casillas con agua según distribuciones de probabilidad predefinidas.

### 5.2) Eliminación de todo un color sin necesidad de un camino cerrado:

Imitación del comportamiento de **Two dots** tal que si se unen 13 puntos del mismo color, elimina todos los puntos del mismo color. Esto fue agregado en la definición del `conect/4` para eliminar todos los puntos del color seleccionado, asegurando poder eliminar todas las presencias de un mismo color sin un camino cerrado, ni bombas.
(imágenes)


### 5.3) Definición de Power Ups:
Con el fin de ser los más fieles posibles al juego original definimos 5 power ups:

#### 5.3.1) Borrador:

Este permite eliminar el punto de una celda específica arbitrariamente. Su lógica se determina por medio de la selección de la celda a eliminar `color en(Grid, TargetIdx, Color)` para proceder a realizar la eliminación específica con `eliminacion_simple/6`, para finalmente estabilizar/chequear el tablero como cualquier otra jugada realizada.
 
#### 5.3.2) Borrar_color:

Este power up permite eliminar toda presencia de el color seleccionado, tal que una vez seleccionado se delega la eliminación al predicado `eliminar_color/7`. Este predicado realiza un recorrido tal que barre la grilla para eliminar cada coincidencia presente.
Lo más relevante de su lógica es cómo empaqueta sus consecuencias: calcula cuántos puntos se destruyeron `CantidadRealColor` y qué cantidad de agua se expandió `CantidadAgua`, unificando ambos datos dentro del término secuencial `achieved/1`. Tras aplicar la física de `gravedad/3`, el estado final es sometido a `juntar_efectos_con_mezcla/4`, evaluando de forma predictiva si la eliminación masiva dejó la grilla sin movimientos posibles (deadlock).

#### 5.3.3) Cruz:

Este power up es un potenciador permite seleccionar una celda específica tal que de la misma se eliminen todos los puntos de sus respectivas columna y fila, así formando la cruz. Su lógica se divide en dos fases: el cálculo espacial y la resolución de efectos.Primero, mediante operaciones de división entera y módulo aplicadas en combinación con `findall/3` y `nth0/3`, el predicado `indices_en_cruz/4` recolecta un `PathCruz` con todos los índices que compartan su misma fila o columna. En segundo lugarm se caluclan los elementos eliminados `contar_colores_destruios`, se actualiza el agua y se actualizan los logros combinados en una estructura condicional `append/3`.

#### 5.3.4) Mezclar:

Su función a diferencia de los anteriores depende de reorganizar todos los puntos presentes en la grilla, sin destruirlos. Su lógica se invoca a `mezclar_grilla_segura/3` para realizar la mezcla, sin alterar la presencia de agua en las celdas que ya poseen agua. Tras reordenar la matriz, evalúa inmediatamente si la nueva configuración posee combinaciones válidas mediante `hay_movimientos/2`. Si la mezcla aleatoria abre caminos transitables, devuelve la nueva grilla con efectos limpios; si el algoritmo falla y constata que ni siquiera la redistribución salvó el juego, inyecta de forma fulminante la bandera analítica `[deadlock]`, notificando a React que debe finalizar la partida.

### 5.4)

## 6) Aspectos modificados en React:

### 6.1) Navegación e interfaz de usuario:

Se incorporó un sistema de navegación compuesto por distintas pantallas para mayor fidelidad al juego original. Se cuenta con un menú principal `MainMenu`, un selector de niveles `LevelSelector` y la pantalla original de juego `Game`. De este modo la interacción de juego se extiende a más que solamente completar una partida preestablecida. La interfaz también incluye ventanas modales para representar los distintos estados del juego, como pausa, victoria o derrota, mediante el componente `GameOverModal`.

### 6.2) Mecánicas de juego incorporadas:

Se implementaron las respectivas representaciones en React para los Power ups.

### 6.3) Aspectos visuales:

Se realizaron ajustes visuales tales como la tonalidad de los puntos, la animación del agua y su renderización.

## 6.6) Gestión de audio:

Se incorporó un sistema de reproducción musical basado en el hook personalizado `useAudio`. Este componente administra la creación y destrucción de los objetos de audio, reproduce música únicamente durante las partidas activas y permite al usuario activar o silenciar el sonido desde la interfaz.

## 7) Desafíos encontrados:

Durante el desarrollo surgieron diversos desafíos técnicos, tales como:

### 7.1) Modelado de las celdas:

Al inicio del proyecto uno de los principales desafíos fue aprender a trabajar con la representación interna de las celdas, detalle primordial para todo el manejo de la grilla. Así permitiendo más sencillez en la discriminacion de los componentes internos de la celda, con tal de que no se arrastran errores en la expansión del agua y explosiones(especialmente en relación a obstáculos).

### 7.2) Partición en segmentos:

La implementación de la gravedad obligó a transformar constantemente la representación de la grilla entre distintos formatos. Aspecto que en inicio se complejizan en relación a la partición de la única lista que gestiona la grilla de modo que segmento, transponga y actualicen las columnas según las reacciones correspondientes por jugada.

### 7.3) Expansión del agua mediante bombas:

La interacción entre las mecánicas de agua y explosiones presentó uno de los mayores desafíos de integración lógica, debido a la necesidad de coordinar múltiples transformaciones simultáneas sobre la grilla......

### 7.4)

## 8) Conclusiones:....................

En conclusión, el presente proyecto nos permite comprender la comunicación entre distintas tecnologías mediante capas, manejandose con diversos niveles de expresividad con un enfoque a una arquitectura clara. Así pudiendo trabajar desacopladas de la representación visual, favoreciendo la extensibilidad y el mantenimiento del juego.

////////////////////////////////////////////////////////////////////////////////////
Al probar los casos revisar de cero:(asi desp los metemos en los ejemplos con las capturas)
* encerrar agua
* encerrar obstáculos
* encerrar espacios vacíos
* la bomba cae una posición
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
* expansión de agua cerca de obstáculos