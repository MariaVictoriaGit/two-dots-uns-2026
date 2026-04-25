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
    %Celda \= [],
    %Celda \= [-],
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
