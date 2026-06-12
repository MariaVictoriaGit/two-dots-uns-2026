:- module(init, [ init/4, init_level/5 ]).

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


init_level(1, Grid, Cols, Goals, Moves) :- 
    init(Grid, Cols, Goals, Moves).

init_level(2, [
	% Fila 0 (índices 0-7)
	[-], [r], [c], [p], [-], [-], [-], [-],
	% Fila 1 (índices 8-15)
	[c], [y], [g], [p], [r], [-], [-], [-],
	% Fila 2 (índices 16-23)
	[r], [r], [g], [y], [r], [g], [-], [-],
	% Fila 3 (índices 24-31)
	[y], [c], [-], [y], [p], [p], [p], [-],
	% Fila 4 (índices 32-39)
	[y, ~], [c, ~], [-], [p], [p, ~], [y, ~], [p, ~], [p],
	% Fila 5 (índices 40-47)
	[c, ~], [c, ~], [-], [p, ~], [p, ~], [p, ~], [p, ~], [-],
	% Fila 6 (índices 48-55)
	[c, ~], [y, ~], [g, ~], [p, ~], [p, ~], [p, ~], [-], [-],
	% Fila 7 (índices 56-63)
	[c, ~], [y, ~], [y, ~], [y, ~], [y, ~], [-], [-], [-],
	% Fila 8 (índices 64-71)
	[-], [y, ~], [y, ~], [y], [-], [-], [-], [-]
], 8, [[r, 10], [g, 10], [p, 15], [~, 21]], 35).


init_level(3, [
    [g], [g], [g], [g], [g], [g], [g], [g],
    [g], [y], [y], [y], [c], [g], [y,~], [g],
    [g], [y], [p], [y], [c], [g], [g], [g],
    [g], [y], [y], [y], [c], [r], [r], [g],
    [g], [p], [p], [p], [p], [r], [p,~], [g],
    [g], [-], [-], [-], [p], [r], [r], [g],
    [g], [-], [c,~], [-], [p], [c], [c], [g],
    [g], [-], [-], [-], [p], [c], [g], [g],
    [g], [g], [g], [g], [g], [g], [g], [g]
], 8, [[g,20],[r,10],[p,15],[~,5]], 30).


init_level(4, [
    [y], [p], [r], [g], [y], [p],
    [g], [y], [y], [r], [p], [g],
    [g], [g], [y], [p], [r], [y],
    [p], [p], [g], [y], [y], [p],
    [y, ~], [p, ~], [r, ~], [g, ~], [y, ~], [p, ~],
    [y, ~], [y, ~], [r, ~], [r, ~], [p, ~], [g, ~]
], 6, [[~, 10], [r, 12], [y, 12]], 18).


init_level(5, [
    [c], [c], [c], [y], [p], [r],
    [c], [r], [c], [g], [y], [p],
    [c], [c], [c], [r], [g], [y],
    [y], [p], [r], [g], [y], [c],
    [g], [y], [p], [g], [g], [p],
    [r], [g], [p], [p], [r], [y]
], 6, [[g, 15], [c, 15], [p, 10]], 20).


init_level(N, Grid, Cols, Goals, Moves) :-
    N > 5,

    Cols is min(10, 4 + N ),
    Rows is min(10, 5 + N ),

    TotalCells is Cols * Rows,

    % 2. Movimientos escalables según el nivel
    Moves is 25 + (N * 2),

    colores_jugables(ColoresDelNivel),
    

    generar_celdas(TotalCells, ColoresDelNivel, Grid),

    contar_elementos(Grid, CantObs, CantAgua),
    CeldasJugables is TotalCells - CantObs,
    
    ObjetivoColor is min(CeldasJugables - 10 , 15 + N),
    
    MaxAgua is floor(CeldasJugables * 0.85) - CantAgua,
    random(ObjetivoColor, MaxAgua , AguaRandom),
    ObjetivoAgua is AguaRandom,
    
    nth0(0, ColoresDelNivel, C1),
    nth0(1, ColoresDelNivel, C2),
    nth0(2, ColoresDelNivel, C3),

    ( CantAgua > 0 ->
        Goals = [[C1, ObjetivoColor], [C2, ObjetivoColor],[C3, ObjetivoColor], [~, ObjetivoAgua]]
    ;
        Goals = [[C1, ObjetivoColor], [C2, ObjetivoColor],[C3, ObjetivoColor]]
    ).

% ====================================================================

% contar_elementos(+Grid, -CantObs, -CantAgua)
contar_elementos([], 0, 0).
contar_elementos([[-]|Resto], Obs, Agua) :- 
    !, 
    contar_elementos(Resto, Obs1, Agua), 
    Obs is Obs1 + 1.

contar_elementos([[_, ~]|Resto], Obs, Agua) :- 
    !, 
    contar_elementos(Resto, Obs, Agua1), 
    Agua is Agua1 + 1.

contar_elementos([_|Resto], Obs, Agua) :- 
    contar_elementos(Resto, Obs, Agua).

% --- Lógica de Selección de Paleta ---
% colores_jugables(-Seleccionados)
colores_jugables(Mezclados) :-
    random_permutation([r, c, g, p, y], Mezclados).
  

% --- Bucle generador de celdas ---
% generar_celdas(+Cantidad, +ColoresDelNivel, -Grilla)
generar_celdas(0, _, []) :- !.
generar_celdas(Cantidad, ColoresDelNivel, [Celda|Resto]) :-
    Cantidad > 0,
    % Tiramos un dado del 0 al 100 para aplicar distribución de probabilidad
    random(0, 100, Dado),
    asignar_tipo_celda(Dado, ColoresDelNivel, Celda),
    CantNueva is Cantidad - 1,
    generar_celdas(CantNueva, ColoresDelNivel, Resto).

% --- Probabilidades de generación de celdas ---
% asignar_tipo_celda(+Dado, +ColoresDelNivel, -Celda)
% OBSTÁCULOS (10% de chance: Dado cae entre 0 y 9)
asignar_tipo_celda(Dado, _, [-]) :- 
    Dado < 10, !.

% AGUA (15% de chance: Dado cae entre 10 y 24)
asignar_tipo_celda(Dado, ColoresDelNivel, [Color, ~]) :- 
    Dado >= 10, Dado < 25, !,
    random_member(Color, ColoresDelNivel).

% CELDA NORMAL (75% de chance: Dado cae entre 25 y 99)
asignar_tipo_celda(Dado, ColoresDelNivel, [Color]) :- 
    Dado >= 25, Dado < 100,
    random_member(Color, ColoresDelNivel).


/*
init([
    [r], [g],
    [y], [c]
], 2, [[r, 5]], 15).*/

/* Caso para probar el deadlock (sin movimientos posibles) 
init([
    [p], [p], [r], [g],
    [y], [c], [y], [c],
    [r], [g], [r], [g],
    [y], [c], [y], [c]
], 4, [[p, 2], [r, 10]], 15).*/ 