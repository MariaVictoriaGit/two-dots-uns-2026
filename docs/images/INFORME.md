## Informe — Proyecto Two Dots

## 1) Introducción:

El proyecto consiste en la implementación web del juego **Two Dots**, un juego de tipo **puzzles** basado en una grilla de puntos de colores. Estos puntos deben ser conectados según sus respectivos colores para ser eliminados, generando distintas reacciones según la forma de la jugada realizada.

Para su desarrollo se utilizaron dos tecnologías principales:
- **Prolog**, para la lógica del juego,
- **React**, para la representación visual y la interacción con el usuario del juego.

Esta combinación permite separar claramente responsabilidades: 
- Prolog como lenguaje representativo del paradigma lógico, se utiliza para modelar el estado del juego y sus comportamientos por medio de hechos, reglas y consultas sobre la grilla. Trabaja bajo estrategias basadas en unificación, recursión y backtracking.
- React, se utiliza para construir la interfaz mediante componentes reutilizables, encargándose de representar la grilla, factores estéticos y la interacción con el usuario
## 2) Arquitectura general:
La lógica principal del juego se implementa en el archivo [`proylcc.pl`](/pengines_server/apps/proylcc/proylcc.pl), mientras que la interfaz se desarrolla en React.

La comunicación entre las dos capas se realiza mayormente en el archivo Game.tsx, el que se nos hizo muy extenso y decidimos dividir en más archivos, especificado en 6.5).

## 3) Implementación en Prolog:

### 3.1) Representación de la grilla:

En principio, utilizamos la representación de la grilla completa como una lista plana unidimensional, donde cada posición representa una celda identificada mediante un índice. A partir de `NumOfColumns`, se reconstruyen las relaciones espaciales utilizando operaciones aritméticas sobre dichos índices en lugar de acceder a posiciones por cercanía directa. La proximidad se determinan lógicamente, verificando si son vecinos ortogonales (arriba, abajo, izquierda y derecha), así optimizando el rendimiento la validación de caminos (`camino_valido`), la simulación de gravedad y expansión del agua.
Para las modificaciones, nunca se modifica el estado original, sino que se construye una nueva versión de la misma, así recorriendo cada celda.

#### Aspecto destacado:

Las celdas no se modelan como objetos, sino como listas de propiedades. Esto permite representar múltiples estados simultáneamente (por ejemplo color, agua ([color, agua]) o bombas([color, bomba])) de forma flexible y extensible. Además de que React utiliza esos `Effects` para: actualizar el progreso del nivel, animar objetivos cumplidos y reacciones (tanto en la grilla internamente como visualmente).

### 3.2) Conexión de puntos:

La conexión de puntos se basa en la construcción de un camino (`Path`) formado por índices numéricos consecutivos sobre la grilla plana. Para que una jugada sea válida, el sistema verifica que cada punto del camino sea obligatoriamente adyacente al siguiente y que todas las celdas involucradas compartan el mismo color. La adyacencia se calcula utilizando desplazamientos matemáticos sobre los índices, considerando movimientos ortogonales.

![connect1](docs/images/codigo/connect1.jpeg)   
![connect2](docs/images/codigo/connect2.jpeg)

![auxiliarConnect](docs/images/codigo/auxiliarConnect.jpeg)

#### Aspecto destacado:

El predicado `celda_con_color/2` es el encargado de discriminar/investigar el contenido de cada celda ([Color | Modificadores]) (por ejemplo, aislando el color de modificadores ambientales (`agua` u `obstáculos`)), así garantizando sobre qué elemento se está operando antes de aprobar la validez de la conexión.

### 3.3) Eliminación de puntos:

La eliminación la definimos como una transformación sobre la "nueva grilla" que generamos para proteger la identidad de la original. Durante este proceso, el sistema discrimina si el contenido de una celda debe conservarse intacto, vaciarse por completo (sustituyéndolo por una lista vacía `[]`) o preservar sus propiedades físicas y ambientales estructurales, tales como la presencia de agua (`~`) o bloques infranqueables (`-`).

#### Aspecto destacado:

Para la manipulación de la grilla inicialmente se usó `nth0/3`, un predicado estándar de Prolog que permite indexar, verificar y extraer elementos basados en un índice con base cero. Fundamental para validar la correspondencia entre los índices del camino y las coordenadas reales. Mas, posteriormente, se comparó `nth0/3` y `nth0/4`, de modo que optamos por `nth0/4` gracias a que el predicado anterior solamente servía para consultar o leer, mientras que el actual también transforma.

### 3.4) Gravedad:

La gravedad se implementó por medio de aislamiento, reestructurando temporalmente la lista plana de la grulla. Por medio del predicado `grilla_filas/3` en combinación con un algoritmo de transposición de matrices (`transponer/2`) se obtienen las distintas columnas independientes que se visualizan en el juego. Esto permite simplificar el procesamiento para recorrerlas y gestionar la situación interna de las mismas, así desplazando los casilleros vacíos (`[]`) hacia el extremo superior, tal que se rellenen las posiciones por inyección aleatoria de nuevos puntos. Una vez llenas las columnas, vuelve a transponer y aplana reconstruyendo el formato original de la grilla.

#### Aspecto destacado:

La lógica de la gravedad funciona independiente de la interfaz gráfica, mas se mantienen en sincronía. Al caer en Prolog se le comunica a React el estado intermedio con la información `[cae]`, esto permite que la interfaz represente los cambios de posición y cuáles son las animaciones correspondientes a producirse.

![gravedad1](docs/images/codigo/gravedad1.jpeg)
![gravedad2](docs/images/codigo/gravedad2.jpeg)
![gravedad3](docs/images/codigo/gravedad3.jpeg)

### 3.5) Generación de nuevos puntos:

La generación de nuevos puntos ocurre dentro de la gestión de la gravedad. Ocurre una vez que se sedimentan todos los puntos no eliminados en el extremo inferior de las columnas, se calcula la cantidad de espacios vacantes por cada una. Usando la aleatoriedad provista por `library(random)` se obtendrán nuevos puntos de colores (respetando el conjunto de posibles valores para los colores). Garantiza que no queden celdas sin un color asignado, salvo que sean obstáculos.  

#### Aspecto destacado:
Al realizar la inyección sobre la estructura de columnas transpuestas se evitan errores de índices de grilla original cuando se recupera la forma de única lista inicial.

### 3.6) Gestión de obstáculos:

Los obstáculos se representan mediante `[-]`. Se diferencian del resto de celdas de la grilla ya que no se podrán utilizar sin modificar frente a ninguna circunstancia. Desde la validación del camino en `camino_valido/3` se gestiona un rechazo instantáneo ante el intento de interactuar con él. Funcionan como barreras. No deberían verse afectados por la explosión de bombas, gravedad o expansión de agua. 

### 3.7) Objetivos del nivel:

Los objetivos se gestionan desde el predicado `connect/4`, que coordina toda la lógica asociada a una jugada. Durante su ejecución, el sistema calcula los resultados relevantes de la conexión realizada y actualiza el progreso de los objetivos del nivel. Estos resultados se transforman en eventos `achieved(...)`, que son utilizados por React para actualizar los contadores y mostrar el avance del jugador. Cuando todos los objetivos son completados, el nivel puede darse por finalizado en condición de victoria.

#### Aspecto destacado:

Los objetivos se calculan directamente durante la resolución de la jugada en `connect/4`, antes de aplicar otros efectos como la gravedad o la generación de nuevas fichas.

### 3.8) Formas cerradas:

Las formas cerradas constituyen uno de los puntos claves para el funcionamiento del juego, tal que se busca detectar desde el `connect/4`. Esto se logra iniciando en el predicado `es_cerrado/1`, el cual evalúa recursivamente la lista de índices del camino (`Path`) para verificar si alguna coordenada se repite el recorrido con longitud mayor a 2, verificando la existencia de un bucle. En caso afirmativo, se procede a eliminar todos los puntos de el color correspondiente por medio de `eliminar_color/7`, se evalúa y realiza la expansión del agua correspondiente (en las zonas que sea necesario), antes de finalmente aplicarse los efectos de la eliminación y la gravedad.

#### Aspecto destacado:
El procesamiento de una forma cerrada constituye la única condición del juego para crear bombas. Durante la transformación masiva de la grilla, el motor de Prolog calcula una coordenada de anclaje dentro del perímetro del bucle para inyectar el modificador estructurado `[Color, bomba]`.

### 3.9) Bombas:

Las bombas constituyen un mecanismo central dentro de la lógica de formas cerradas del juego. Una vez se verifica la condición de ser cerrado, se procede a revisar cuáles puntos quedaron adentro del área cerrada para convertirlos en bomba. Esto ocurre en el método **`encontrar_posiciones_bombas/4`**.
Primero, **`extraer_loop/2`** recorta el camino original para quedarse estrictamente con el anillo cerrado, ya que tuvimos problemas con Paths que contenían una forma cerrada que, aunque no contenía una bomba adentro, generaba falsas bombas. IMÁGEN FALSA BOMBA.
Una vez comprobamos eso, **`bordes_grilla/3`** identifica absolutamente todas las celdas que están en el perímetro de todo el tablero (fila 0, última fila, columna 0, última columna). Y, desde ahí, mediante un algoritmo de *Flood Fill* (`inundar/6`), se "inunda" todo lo que es el exterior. Finalmente, si la celda no forma parte de Path ni de la inundación, se deduce que es bomba y genera los `IndicesBombas`.
Con los índices ya establecidos, se invoca `colocar_bombas_en_grid/3`.
Una vez creadas las bombas, el sistema aplica la gravedad sobre la grilla. Posteriormente, las bombas explotan y, tras la detonación, se ejecuta nuevamente la gravedad para rellenar los espacios vacíos generados por la explosión.
La explosión de las bombas se encuentra concentrada en el predicado `explosionar_bomba/5`, el cual integra simultáneamente la eliminación de puntos, la propagación de agua, la actualización de objetivos y la aplicación de una gravedad secundaria.
Al gatillar la detonación, por medio del predicado `adyacente_bomba/4`, se determinan las celdas que son vecinas a la bomba. El sistema determina de forma exacta el conjunto de índices alcanzados por la onda expansiva, correspondiente a un área de impacto de 3×3, tal que al explotar se aplica por segunda vez la gravedad. 

![bomba1](docs/images/codigo/bomba1.jpeg)
![bomba2](docs/images/codigo/bomba2.jpeg)
![bomba3](docs/images/codigo/bomba3.jpeg)
![bomba4](docs/images/codigo/bomba4.jpeg)
![bomba5](docs/images/codigo/bomba5.jpeg)

![BombaNormal1](docs/images/casosDePrueba/Prolog/BombaNormal1.png)
![BombaNormal2](docs/images/casosDePrueba/Prolog/BombaNormal2.png)
![BombaNormal3](docs/images/casosDePrueba/Prolog/BombaNormal3.png)
![BombaNormal4](docs/images/casosDePrueba/Prolog/BombaNormal4.png)

![FalsaBomba1](docs/images/casosDePrueba/Prolog/FalsaBomba1.png)
![FalsaBomba2](docs/images/casosDePrueba/Prolog/FalsaBomba2.png)
![FalsaBomba3](docs/images/casosDePrueba/Prolog/FalsaBomba3.png)

### 3.10) Agua:

El agua se modela como una propiedad especial que complementa las celdas con puntos. La eliminación de el punto en la celda sin agua que sea vecina ortogonal a una celda con agua, ya sea por un camino válido, bomba o power up, ocasionará un cambio permanente en esa celda. Además, la expansión del agua computa de forma inmediata nuevos logros hacia los objetivos de la partida.

#### Aspecto destacado:

Se incorporaron los predicados: `tiene_agua/1` y `es_obstaculo/1` como capa de abstracción sobre la representación interna de la grilla. Gracias a esta decisión, si en el futuro se modifica la forma de representar agua u obstáculos, únicamente será necesario actualizar dichos predicados sin afectar el resto de la lógica del sistema.

![agua1](docs/images/codigo/agua1.jpeg)
![agua2](docs/images/codigo/agua2.jpeg)

### 3.11) Fin del juego:

El estado de la partida se controla mediante la interacción entre Prolog y React.

#### 3.11.1) **Flujo de Victoria:**

Se produce una vez todos los objetivos del nivel fueron satisfechos y se finaliza la partida.

![Victoria](docs/images/casosDePrueba/React/Victoria.png)

#### 3.11.2) **Flujos de Derrota:**

Ocurre en dos situaciones:

#### 3.11.2.1) **Sin movimientos restantes:**

El contador de movimientos llegó a cero.

![Derrota](docs/images/casosDePrueba/React/Derrota.png)

#### 3.11.2.2) **Sin jugadas posible (deadlock):**

Esta es una situación clave, ya que tanto por la generación aleatoria de puntos como los posibles formatos de niveles se debía plantear un caso en el que ya no se pudiera actuar. Cuando ya no existen combinaciones válidas en la grilla `hay_movimientos/2`, tal que envía la marca `[deadlock]` dentro de los efectos generados, y React finaliza la partida automáticamente mostrando la pantalla de derrota.

Además es importante aclarar el intento de recuperación automática: 

Antes de declarar una derrota definitiva, el sistema intenta recuperar la partida mediante una mezcla automática del tablero. Para ello se utilizan los predicados `mezclar_grilla_segura/3` y `intentar_mezclar/4`

La mezcla reorganiza aleatoriamente las fichas manteniendo intactos obstáculos y celdas con agua. Posteriormente se verifica nuevamente la existencia de movimientos posibles.

Entonces, si después de varios intentos continúa sin existir ninguna jugada válida, se genera el evento `[deadlock]` que React interpreta como una condición inmediata de derrota.

![verificacion combinacional1](<docs/images/codigo/verificacion combinacional1.jpeg>)
![verificacion combinacional2](<docs/images/codigo/verificacion combinacional2.jpeg>)

![SinComb1](docs/images/casosDePrueba/Prolog/SinComb1.png)
![SinComb2](docs/images/casosDePrueba/Prolog/SinComb2.png)

#### Aspecto destacado:

La lógica de detección y recuperación se enfoca en `juntar_efectos_con_mezcla/4` permitiendo realizar un comportamiento donde se intenta salvar automáticamente una partida bloqueada antes de darla por perdida.

## 5) Aspectos modificados(Nuevas funcionalidades en Prolog):

### 5.1) Generación de nuevos niveles:

Alteración del archivo init: no se ha modificado el esquema de representación de la grilla en el archivo `init.pl`. Lo que se modifica es la generación de niveles, tal que se pre-definieron unos niveles iniciales y un generador de niveles dinámicos para los niveles superiores. Para los niveles generados automáticamente, se incorpora lógica de aleatorización para crear puntos, obstáculos y casillas con agua según distribuciones de probabilidad predefinidas.

### 5.2) Eliminación de todo un color sin necesidad de un camino cerrado:

Imitación del comportamiento de **Two dots** tal que si se unen 13 puntos del mismo color, elimina todos los puntos del mismo color. Esto fue agregado en la definición del `connect/4` para eliminar todos los puntos del color seleccionado, asegurando poder eliminar todas las presencias de un mismo color sin un camino cerrado, ni bombas.

![13Puntos1](docs/images/casosDePrueba/Prolog/13Puntos1.png)
![13Puntos2](docs/images/casosDePrueba/Prolog/13Puntos2.png)
![13Puntos3](docs/images/casosDePrueba/Prolog/13Puntos3.png)
![13Puntos4](docs/images/casosDePrueba/Prolog/13Puntos4.png)
![13Puntos5](docs/images/casosDePrueba/Prolog/13Puntos5.png)

### 5.3) Definición de Power Ups:
Con el fin de ser los más fieles posibles al juego original definimos 4 power ups:

INSERTE CAP USO POWERAP

![pw1](docs/images/codigo/pw1.jpeg)
![pw2](docs/images/codigo/pw2.jpeg)

#### 5.3.1) Borrador:

Este permite eliminar el punto de una celda específica individualmente. Su lógica se determina por medio de la selección de la celda a eliminar `color_en(Grid, TargetIdx, Color)` para proceder a realizar la eliminación específica con `eliminacion_simple/6`, para finalmente estabilizar/chequear el tablero como cualquier otra jugada realizada.

![PowerUpBorrar1](docs/images/casosDePrueba/React/PowerUps/PowerUpBorrar1.png)
![PowerUpBorrar2](docs/images/casosDePrueba/React/PowerUps/PowerUpBorrar2.png)
 
#### 5.3.2) Borrar_color:

Este power up permite eliminar toda presencia del color seleccionado, tal que una vez hecho se delega la eliminación al predicado `eliminar_color/7`. Este predicado realiza un recorrido que barre la grilla para eliminar cada coincidencia presente.
Lo más relevante de su lógica es cómo empaqueta sus consecuencias: calcula cuántos puntos se destruyeron `CantidadRealColor` y qué cantidad de agua se expandió `CantidadAgua`, unificando ambos datos dentro del término secuencial `achieved/1`. Tras aplicar la física de `gravedad/3`, el estado final es sometido a `juntar_efectos_con_mezcla/4`, evaluando de forma predictiva si la eliminación masiva dejó la grilla sin movimientos posibles (deadlock).

![PowerUpBorrarUnColor1](docs/images/casosDePrueba/React/PowerUps/PowerUpBorrarUnColor1.png)
![PowerUpBorrarUnColor2](docs/images/casosDePrueba/React/PowerUps/PowerUpBorrarUnColor2.png)

#### 5.3.3) Cruz:

Este power up es un potenciador permite seleccionar una celda específica tal que de la misma se eliminen todos los puntos de sus respectivas columna y fila, así formando la cruz. Su lógica se divide en dos fases: el cálculo espacial y la resolución de efectos.Primero, mediante operaciones de división entera y módulo aplicadas en combinación con `findall/3` y `nth0/3`, el predicado `indices_en_cruz/4` recolecta un `PathCruz` con todos los índices que compartan su misma fila o columna. En segundo lugarm se caluclan los elementos eliminados `contar_colores_destruios`, se actualiza el agua y se actualizan los logros combinados en una estructura condicional `append/3`.

![PowerUpCruz1](docs/images/casosDePrueba/React/PowerUps/PowerUpCruz1.png)
![PowerUpCruz2](docs/images/casosDePrueba/React/PowerUps/PowerUpCruz2.png)

#### 5.3.4) Mezclar:

Su función a diferencia de los anteriores depende de reorganizar todos los puntos presentes en la grilla, sin destruirlos. Su lógica se invoca a `mezclar_grilla_segura/3` para realizar la mezcla, sin alterar la presencia de agua en las celdas que ya poseen agua. Tras reordenar la matriz, evalúa inmediatamente si la nueva configuración posee combinaciones válidas mediante `hay_movimientos/2`. Si la mezcla aleatoria abre caminos transitables, devuelve la nueva grilla con efectos limpios; si el algoritmo falla y constata que ni siquiera la redistribución salvó el juego, inyecta de forma fulminante la bandera analítica `[deadlock]`, notificando a React que debe finalizar la partida.

![PowerUpMezclar1](docs/images/casosDePrueba/React/PowerUps/PowerUpMezclar1.png)
![PowerUpMezclar2](docs/images/casosDePrueba/React/PowerUps/PowerUpMezclar2.png)

## 6) Aspectos modificados en React:

### 6.1) Navegación e interfaz de usuario:

Se incorporó un sistema de navegación compuesto por distintas pantallas para mayor fidelidad al juego original, extendiendo la interacción de juego a más que solamente completar una partida preestablecida. La gestión de múltiples pantallas se administra mediante el estado `currentScreen`, permitiendo alternar de manera fluida entre las diferentes secciones sin abandonar el contexto general de la aplicación.

Se cuenta con un menú principal `MainMenu`, un selector de niveles `LevelSelector` y la pantalla original de juego `Game`. De este modo la interacción de juego se extiende a más que solamente completar una partida preestablecida. La interfaz también incluye ventanas modales para representar los distintos estados del juego, como pausa, victoria o derrota, mediante el componente `GameOverModal`.

![`MainMenu`](docs/images/casosDePrueba/React/MainMenu.png)
![`LevelSelector`](docs/images/casosDePrueba/React/LevelSelector.png)
![`Game`](docs/images/casosDePrueba/React/Game.png)
![`GameOverModal`](docs/images/casosDePrueba/React/GameOverModal.png)

### 6.2) Barra de power ups:

`PowerUpBar`: Implementa la barra de habilidades especiales del juego, mostrando los recursos disponibles. El componente mantiene este inventario mediante el estado `powerUps` y un identificador de poder activo.  (`activePowerUp`). 

![PowerUps](docs/images/casosDePrueba/PowerUps.png)

### 6.3) Aspectos visuales:

Se realizaron ajustes visuales tales como la tonalidad de los puntos mediante la inserción de imágenes propias, la animación del agua y su renderización al expandirse. Intentamos mantener una paleta de colores coherente en los fondos, botones y elementos de interfaz. Agregamos una animación de expansión que acompaña la expansión de las bombas, otra a la hora de renderizar la gravedad, íconos personalizados para los power ups e interfaz de usuario y decidimos irnos por una estética "3D" falsa.

### 6.4) Gestión de audio: 

[useAudio.ts](\src\components\useAudio.ts)
Se incorporó un sistema de reproducción musical basado en el hook personalizado `useAudio`. Este componente administra la creación y destrucción de los objetos de audio, reproduce música únicamente durante las partidas activas y permite al usuario activar o silenciar el sonido desde la interfaz.

### 6.5) Modularización de `game.tsx`: 

Con el fin de no poseer un módulo `game.tsx` con una cantidad excesiva de líneas de código tales realizarán funcionalidades no fundamentalmente relacionadas más que por utilizarse en el juego como accesorios. Decidimos crear nuevos componentes.

#### 6.5.1) LevelSelector:

Componente encargado de la pantalla de selección de niveles. Permite al jugador visualizar su progreso y elegir los escenarios disponibles de manera sencilla e intuitiva. La interfaz muestra únicamente los niveles desbloqueados según el avance alcanzado y cuenta con un sistema de desplazamiento automático que centra la vista en el nivel actualmente seleccionado. Además, se diseñó una presentación visual inspirada en los mapas de progreso de juegos comerciales, utilizando un recorrido en zig-zag que conecta los distintos niveles y facilita la comprensión del avance dentro del juego. Todo el estilo de esta pantalla se encuentra encapsulado en módulos CSS independientes, favoreciendo la organización y el mantenimiento del código.

#### 6.5.2) MainMenu:

Componente que funciona como la pantalla principal y punto de entrada del juego. Desde aquí el usuario puede iniciar una nueva partida o acceder al selector de niveles, centralizando las acciones iniciales de navegación de la aplicación. Su diseño busca ofrecer una bienvenida clara y atractiva al jugador, organizando de forma ordenada los títulos, botones y elementos visuales principales. Además, cuenta con estilos modularizados que incorporan animaciones y efectos interactivos sobre los botones para mejorar la experiencia de usuario y dar mayor dinamismo a la interfaz.

#### 6.7) Gestión de audición:

Se implementó un sistema de audio mediante el hook personalizado `useAudio.ts`, encargado de centralizar la reproducción de sonidos y evitar código duplicado. Este módulo controla automáticamente la música de fondo según el estado de la partida, permite activarla o silenciarla desde la interfaz y libera los recursos al salir del juego para optimizar el rendimiento del navegador.
 
## 7) Dificultades:

### 7.1) Propagación recursiva del agua:

Uno de los desafíos fue implementar la expansión del agua en cadena, donde la eliminación de un punto mojado debe propagarse a sus adyacentes, y estos a los suyos sucesivamente. Implementamos esto mediante Búsqueda en Profundidad (DFS) recursiva. Para evitar ciclos infinitos en grillas con muchos elementos de agua conectados; mantenemos una lista de visitados, garantizando que cada celda sea procesada una sola vez por jugada.

### 7.2) Gestión de obstáculos y delimitación: 

Inicialmente, el agua se expandía erróneamente sobre celdas con obstáculos. Para corregirlo, implementamos una lógica de validación preventiva basada en una Búsqueda en Amplitud (BFS) para el control de fronteras. Antes de realizar cualquier expansión, el predicado `es_obstaculo/1` actúa como una barrera lógica, asegurando que el flujo de agua se detenga al detectar celdas delimitadoras ([-]).

### 7.3) Formación de bombas:

Tuvimos que experimentar con varios algoritmos para lograr una generación de bombas efectiva y completa.
Fue complicado encontrar un balance que garantice la detección de bombas que no deje casos afuera ni meta casos de más. Al tener varios casos particulares (como la "falsa bomba" mencionada), tuvimos que poner más controles de los que pensamos. Si poníamos controles de más, por otra parte, había casos válidos que no nos consideraba, como por ejemplo un polígono cerrado con una "punta" fuera del cuadrado. 

## 8) Nuestra experiencia con la IA:

Los asistentes de IA sirvieron de apoyo a lo largo del desarrollo, aunque no sin sus contratiempos. 

### Puntos destacados:

- Nos ayudó a detectar código repetido que no veíamos, facilitando la reutilización y refactorización de predicados de Prolog, manteniendo el código modular y aplicando el principio DRY (Don't Repeat Yourself).
- Nos facilitó entender cómo conectar la lógica del juego con los aspectos gráficos en React y así mapear datos del desde Prolog hacia la interfaz.
- El completamiento y generación de código sencillo es de gran ayuda cuando se trabaja en un marco temporal y se sabe lo que se está haciendo. 
- Poder pedir explicaciones de funciones y predicados era bastante útil cuando teníamos que tocar código en el que había trabajado otra integrante del grupo de forma asincrónica. 

### Consideraciones:

- Así como la IA puede generar mucho código, también puede generar muchos errores. Cuando estábamos experimentando con los agentes tuvimos que calibrar la "confianza que les teníamos." A veces, sin querer, le dábamos permisos para modificar archivos o completar texto que en realidad no queríamos.
- Tuvimos una ocasión donde al querer insertar un ícono, por copiar y pegar ciegamente, la IA decidió que el mejor curso de acción era hard-codear el ícono y dibujarlo de forma vectorial en lugar de simplemente importarlo.
- Al final, decidimos que antes de aceptar una sugerencia de la IA o hacer un cambio grande, debíamos consultarlo entre nosotras para no cometer una imprudencia. Muchas veces pasaba, que algo que parecía coherente y correcto, después de un poco de análisis estaba atado con alambre. 

## 9) Conclusiones:

El desarrollo de este proyecto nos permitió comprender en profundidad cómo integrar y coordinar tecnologías basadas en paradigmas muy diferentes. Por un lado, se trabajó con Prolog para modelar la lógica del juego mediante programación declarativa, mientras que React se encargó de la representación visual y la interacción con el usuario. Esta combinación puso en evidencia la importancia de diseñar una arquitectura clara, donde cada tecnología pueda aprovechar sus fortalezas específicas.

La organización por capas implementada permitió desacoplar completamente la lógica de negocio de la interfaz gráfica. Gracias a ello, mecánicas complejas como la conexión de puntos, la gravedad, la expansión del agua, la generación y explosión de bombas o la validación de objetivos pudieron desarrollarse de manera independiente, pudiendo trabajar con la definición de los comportamientos de manera independiente de su representación visual. 

En conjunto, el proyecto demuestra que es posible integrar de manera efectiva distintas tecnologías y niveles de abstracción dentro de una misma aplicación, logrando una solución flexible, extensible y fácil de mantener.
