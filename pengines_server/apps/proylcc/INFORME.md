# Informe — Proyecto Two Dots

## Introducción:
El proyecto se basa en implementar una versión web del juego Two Dots, un juego de tipo puzzles basado en una grilla de puntos de colores. Estos puntos deben ser conectados según sus respectivos colores para ser eliminados, generando distintas reacciones segun la forma de la jugada realizada. Para su desarrollo se utilizo Prolog, para la lógica del juego, y React, para la representación del juego. Combinacion que perimite seprar claramente repsonsabilidades:
- Prolog, como lenguaje representativo del paradigma lógico, se utiliza para modelar el estado del juego y sus comportamientos, por medio de hechos reglas y consultas sobre la grilla. Trabajando bajo estrategias basadas en unificación, recursión y backtracking.
- React se utiliza para construir la interfaz mediante componentes reutilizables, encargandose de representar la grilla y la interacción con el usuario.

## Arquitectura general:
La lógica principal del juego se implementa en el archivo [`proylcc.pl`](/pengines_server/apps/proylcc/proylcc.pl), mientras que la interfaz se desarrolla en React.

- La interacción entre React y Prolog se realiza a través del predicado `connect/4`, que recibe


- La comunicación entre Prolog y React se establece mediante `connect/4`:


### Implementación en Prolog:(decisiones de diseño)(de cada cosa, estrategia, positivo, desafío y casos de prueba)
- Representación de la Grilla:


- Conexión de puntos:


- Eliminación:


- Gravedad:


- Generación de nuevos puntos:


- Completar los objetivos:


- Formas cerradas:


- Bombas:


- Obstáculos:


- Agua:


- Fin del juego: 


## Aspectos destacados en React


## Funcionalidades adicionales implementadas:
- 

## Desafíos












