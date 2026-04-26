/*
[r]        % solo un punto rojo
[-]        % celda vacía / no utilizable
[]         % celda vacía tras eliminación
[c, ~]     % punto celeste con agua
ESTRUCTURA////////////////////////////////////////////////////////////////////////////////////////////
( Condicion ->    COMO EL IF-THEN         ME GUSTARIA HACERLO EN PROCESAR_CELDA PARA QUE NO QUEDE EL BACKTRAKING
    Entonces
;
    Sino
)

Celda = [Color | _]
*/
:- module(proylcc,
    [  
        connect/4
    ]).
:-use_module(library(lists)).
% connect(+Grid, +NumOfColumns, +Path, -Effects)
% donde Effects es una lista de effect(ResultingGrid, AuxiliaryInfo)
% donde AuxiliaryInfo es una lista de información adicional que se quiera devolver
% para la UI (por ejemplo, los objetivos cumplidos, o qué celdas se vieron afectadas, etc).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ENTRADA PRINCIPAL
connect(Grid, NumOfColumns, Path, Effects) :- %motor de todo el manejo de la jugada
        writeln(Path),
    camino_valido(Path, NumOfColumns, Grid),
        writeln('camino ok'),
    mismo_color(Grid, Path, _Color),
        writeln('color ok'),
    eliminar_path(Grid, Path, Grid1),
        writeln('path eliminado'),
        writeln('antes gravedad'),
    gravedad(Grid1, NumOfColumns, Grid2), %los comentados no borrarlos son para cuando ande la gravedad
        
        writeln('despues gravedad'),
        writeln(Grid2),
    Effects=[
        effect(Grid1, [eliminados(Path)]),
        effect(Grid2, [cae])%        
    ]. %unificamos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%VALIDAMOS LA JUGADA
/* Logica
Grilla de puntos de colores conectables.
El usuario debe poder seleccionar y conectar puntos adyacentes del mismo color
para formar una jugada válida. Al completar la jugada, esos puntos desaparecen.*/
camino_valido([_], _, _).
camino_valido([X, Y|Resto], NumOfColumns, Grid):-
    celda_con_color(Grid, X),
    celda_con_color(Grid, Y),
    X \= Y,
    adyacente(X, Y, NumOfColumns, Grid),
    camino_valido([Y|Resto], NumOfColumns, Grid).

adyacente(X, Y, NumOfColumns, Grid):-
    length(Grid, Len),
    (% derecha
        Y is X + 1,
        X//NumOfColumns =:= Y//NumOfColumns
    ;% izquierda
        Y is X - 1,
        X//NumOfColumns =:= Y//NumOfColumns
    ;% abajo
        Y is X +NumOfColumns,
        Y < Len
    ;% arriba
        Y is X - NumOfColumns,
        Y >= 0
    ).

celda_con_color(Grid, Indice):-
    esta_elemento(Indice, Grid, Celda),
    Celda \= [],
    Celda \= [-],
    Celda = [Color | _],
    es_color(Color).

color_en(Grid, Indice, Color):-
    esta_elemento(Indice, Grid, Celda),
    Celda = [Color | _],
    es_color(Color).

es_color(X):-
    member(X, [r, g, b, y, c, p]).%cuida no borrar el efecto, si el color

mismo_color(Grid, [X|Z], Color):-
    color_en(Grid, X, Color),
    forall(member(Y, Z), color_en(Grid, Y, Color)).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ACCESOS
/*ver si buscamos en un lugar valido e instanciamos el elemento
var(N)       no tiene valor
nonvar(N)    tiene valor*/
esta_elemento(E, Lista, X) :-
    E >= 0,
    nth0(E, Lista, X).
/*nth0/3 es un predicado estándar de Prolog para acceder a elementos de una lista por índice empezando en 0.*/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ELIMINACION
eliminar_path(Grid, Path, NewGrid):-
    eliminar_path_rec(Grid, Path, 0, NewGrid).

eliminar_path_rec([], _, _, []).
eliminar_path_rec([Celda|Resto], Path, Indice, [NewCelda|NewResto]):-
    procesar_celda(Indice, Path, Celda, NewCelda),
    NextIndice is Indice + 1,
    eliminar_path_rec(Resto, Path, NextIndice, NewResto).
/*procesar_celda(Indice, Path, Celda, NewCelda):-
    (
        member(Indice, Path),
        remover_color(Celda, NewCelda)
    );
    (
        \+member(Indice, Path),
        NewCelda = Celda
    ).*/
procesar_celda(Indice, Path, Celda, NewCelda) :-
    member(Indice, Path), !,
    remover_color(Celda, NewCelda).
procesar_celda(_, _, Celda, Celda).
remover_color(Celda, NewCelda):-
    exclude(es_color, Celda, NewCelda).%saca si es algun color pero agua sin color es vacio q tmb debe llenarse y mantener el agua

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GRAVEDAD
/*iterar columnas*/
gravedad(Grid, NumCols, NewGrid) :-
    gravedad_cols(0, NumCols, Grid, Grid, NewGrid).

gravedad_cols(ColIndice, NumCols, _, Acc, Acc) :-
    ColIndice >= NumCols, !. 
    /*provoca el descarte de todas las (ramas) alternativas que quedaron pendientes de ser exploradas desde 
el instante en que se utilizó para resolver la regla conteniendo dicho ‘!’(diapos 7 Prolog)*/
gravedad_cols(ColIndice, NumCols, Grid, Acc, NewGrid) :-
    columna(Grid, NumCols, ColIndice, Col),
    gravedad_columna_con_obstaculos(Col, NewCol),
    reemplazar_columna(Acc, Grid, NumCols, ColIndice, NewCol, 0, Acc1),
    NextCol is ColIndice + 1,
    gravedad_cols(NextCol, NumCols, Grid, Acc1, NewGrid).

/*extraer y reinsertar*/
columna(Grid, NumCols, ColIndice, Col) :-
    columna_rec(Grid, NumCols, ColIndice, 0, Col).

columna_rec([], _, _, _, []) :- !.
columna_rec([X|Xs], NumCols, ColIndice, I, [X|Ys]) :-
    I mod NumCols =:= ColIndice, !,
    I1 is I + 1,
    columna_rec(Xs, NumCols, ColIndice, I1, Ys).
columna_rec([_|Xs], NumCols, ColIndice, I, Ys) :-
    I1 is I + 1,
    columna_rec(Xs, NumCols, ColIndice, I1, Ys).

reemplazar_columna([], _, _, _, _, _, []).
%//si el indice de la celda es igual al indice de la columna a reemplazar, entonces reemplazamos por el nuevo valor
reemplazar_columna([X|XCola], Grid, NumOfColumns, ColIndice, NewCol, I, [Y|YCola]) :-
    /*aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaah*/
    I mod NumOfColumns =:= ColIndice, !,        %si nop falla sigue
    Indice is I // NumOfColumns,
    esta_elemento(Indice, NewCol, Y),
    I1 is I + 1,
    reemplazar_columna(XCola, Grid, NumOfColumns, ColIndice, NewCol, I1, YCola).
reemplazar_columna([X|XCola], Grid, NumOfColumns, ColIndice, NewCol, I, [X|YCola]) :-
    I mod NumOfColumns =\= ColIndice,
    I1 is I + 1,
    reemplazar_columna(XCola, Grid, NumOfColumns, ColIndice, NewCol, I1, YCola).

/*particionar([], _, []).
particionar(ListaPlana, NumCols, [Fila | RestoFilas]) :-
    length(Fila, NumCols),                  % Crea una lista del tamaño de las columnas (8)
    append(Fila, Resto, ListaPlana),        % Corta la lista plana original
    particionar(Resto, NumCols, RestoFilas). % Repite con lo que sobra
*/


tiene_color([Color|Resto]) :- 
    es_color(Color);
    es_agua(Resto).
/*puto**/
%es_agua([_,~]).
es_agua([~]).

es_obstaculo([-]).





/*logica de la gravedad*/
    /*segmentamos por los obstaculos*/
separar_por_obstaculos([], []).
separar_por_obstaculos([[-]|R], [[[-]]|Segs]) :-
    separar_por_obstaculos(R, Segs).
separar_por_obstaculos([X|R], [[X|Seg]|Segs]) :-
    X \= [-],
    tomar_segmento(R, Seg, Resto),
    separar_por_obstaculos(Resto, Segs).

tomar_segmento([], [], []).
tomar_segmento([[-]|R], [], [[-]|R]) :- !.
tomar_segmento([X|R], [X|Seg], Resto) :-
    tomar_segmento(R, Seg, Resto).
    
/*logica de la gravedad*/
    /*gravedad en segmento*/
gravedad_segmento([[-]], [[-]]) :- !.
gravedad_segmento(Seg, NewSeg) :-
    include(cae, Seg, NoVacios),
    length(Seg, L),
    length(NoVacios, LNV),
    Vacios is L - LNV,
    crear_vacios(Vacios, VaciosLista),
    append(VaciosLista, NoVacios, NewSeg).
/*TODO*/
cae(Celda) :-
    tiene_color(Celda),
    \+ es_agua(Celda).


no_vacio(Celda) :-
    Celda \= [],    
    Celda \= [-].

crear_vacios(0, []).
crear_vacios(N, [[]|R]) :-
    N > 0,
    N1 is N - 1,
    crear_vacios(N1, R).
/*logica de la gravedad*/
    /*aplicar a toda la columna*/
procesar_segmento([[-]], [[-]]) :- !.
procesar_segmento(Seg, NewSeg) :-
    gravedad_segmento(Seg, NewSeg).
gravedad_columna_con_obstaculos(Col, NewCol) :-
        writeln('COL ORIGINAL'), writeln(Col),
    separar_por_obstaculos(Col, Segs),
        writeln('SEGS'), writeln(Segs),
    maplist(procesar_segmento, Segs, NewSegs),
        writeln('NEW SEGS'), writeln(NewSegs),
    append(NewSegs, NewCol),
    %append/2 en SWI-Prolog sí concatena lista de listas.
        writeln('NEW COL'), writeln(NewCol).