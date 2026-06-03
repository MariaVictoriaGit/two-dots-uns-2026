:- module(init, [ init/4 ]).

/**
 * init(-Grid, -NumOfColumns, -Goals, -Moves).
 * 
 * Predicado especificando la grilla inicial, que será mostrada al comienzo del juego, donde:
 * - Grid es una lista plana con las celdas que conforman la grilla
 * - NumOfColumns es la cantidad de columnas (determina las dimensiones)
 * - Goals es una lista con los objetivos del juego, por ejemplo, [[r, 10], [g, 7], [p, 15], [~, 21]] (recolectar 10 rojos, 7 verdes, etc).
 * - Moves es la cantidad de movimientos disponibles para el jugador.
 * 
 * Representación de contenido de una celda:
 * r = red
 * c = cyber grape (color morado azulado)
 * p = pink
 * y = yellow
 * g = green
 * - = obstáculo (celda no jugable)
 * ~ = agua
 */
init([
    [g], [g], [g], [g], [g], [g], [g], [g],
    [g], [y], [y], [y], [c], [g], [~], [g],
    [g], [y], [p], [y], [c], [g], [g], [g],
    [g], [y], [y], [y], [c], [r], [r], [g],
    [g], [p], [p], [p], [p], [r], [~], [g],
    [g], [-], [-], [-], [p], [r], [r], [g],
    [g], [-], [c,~], [-], [p], [c], [c], [g],
    [g], [-], [-], [-], [p], [c], [g], [g],
    [g], [g], [g], [g], [g], [g], [g], [g]
], 8, [[g,20],[r,10],[p,15],[~,5]], 30).