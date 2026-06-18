### Nota: 110

### ⚙️ Funcionalidad

#### 📌 Grilla de puntos de colores conectables
- ✅ OK. Al conectar puntos desaparecen.

#### 📌 Caída por gravedad y generación de nuevos puntos
- ✅ OK. Puntos por encima caen correctamente.
- ✅ OK. Se generan nuevos puntos correctamente.

#### 📌 Objetivos de la partida
- ✅ OK. Se reflejan los objetivos correctamente.

#### 📌 Formas cerradas (cuadrado o lazo cerrado)
- ✅ OK. Se eliminan correctamente todos los puntos de ese color en lazos cerrados.

#### 📌 Conversión a bombas al cerrar forma con contenido interno
- ✅ OK. Se convierten en bombas solo los puntos encerrados segun la forma del lazo.

#### 📌 Comportamiento de bombas
- ✅ OK. Bombas eliminan correctamente area 3x3.

#### 📌 Espacios / obstáculos
- ✅ OK. Obstaculos no caen por gravedad.
- ✅ OK. Obstaculos permiten paso de otros puntos por gravedad.

#### 📌 Mecánica de agua
- ✅ OK. El agua se extiende correctamente.

#### 📌 Finalización del juego
- ✅ OK. Al cumplir objetivos, finaliza el juego.
- ✅ OK. Al no quedar mas movimientos, finaliza el juego.
- ✅ OK. Al no quedar jugadas posibles, finaliza el juego.

#### 🚀 Extras
- ➖ La animacion de caida no es intuitiva, si cae un punto nuevo sobre uno viejo del mismo color no aplica la animacion y confunde.
- ➕➕ Animaciones, estetica, sonido mejorados.
- ➕➕ Cuatro power-ups `borrar_color`, `borrador`, `cruz` y `mezclar`.
- ➕➕ Generacion de niveles dinamicos a partir del 6.
- ➕ 13 o mas funcionan como lazo cerrado.
- ➕ Agua usa DFS.
- (Info) Recargar la pagina cambia los niveles autogenerados y se recarga los powerups.

### 📚 Documentación
- ✅ OK. Secciones cortas y concisas.
- ✅ OK. Muestra funcionalidades con imagenes.
- ✅ OK. Declara uso IA.
- ➖ Una seccion con casos de prueba hubiese sido mas util.
