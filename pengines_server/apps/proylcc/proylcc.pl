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

Celda = [Color , _]
*/
:- module(proylcc,
    [  
        connect/4
    ]).
:-use_module(library(lists)).
:- use_module(library(random)).
% connect(+Grid, +NumOfColumns, +Path, -Effects)
% donde Effects es una lista de effect(ResultingGrid, AuxiliaryInfo)
% donde AuxiliaryInfo es una lista de información adicional que se quiera devolver
% para la UI (por ejemplo, los objetivos cumplidos, o qué celdas se vieron afectadas, etc).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ENTRADA PRINCIPAL
connect(Grid, NumOfColumns, Path, Effects) :- %motor de todo el manejo de la jugada
    %verificamos que el camino sea valido
    camino_valido(Path, NumOfColumns, Grid),
    mismo_color(Grid, Path, Color, Cantidad),
    %To do: Bomba
    /*(es_bomba(Path) -> 
        eliminar_colores(Grid, Color, GridPreGravedad),
        expandir_agua_en_jugada(Grid, Path, NumOfColumns, IndicesAgua)
    ;   
        % CASO NORMAL: Solo el camino
        expandir_agua_en_jugada(Grid, Path, NumOfColumns, IndicesAgua),
        aplicar_agua_a_grilla(Grid, IndicesAgua, GridConAgua, _),
        eliminar_path(GridConAgua, Path, GridPreGravedad)
    ),
    aplicar_agua_a_grilla(Grid, IndicesAgua, _, NuevosAgua),
    length(NuevosAgua, CantidadAgua),

    % 4. Gravedad final
    gravedad(GridPreGravedad, NumOfColumns, GridFinal),
    Effects = [
        effect(GridPreGravedad, [achieved([[Color, Cantidad], [~, CantidadAgua]])]),
        effect(GridFinal, [cae])
    ].*/
    % --- EXPANSIÓN Agua ---
    expandir_agua_en_jugada(Grid, Path, NumOfColumns, Indices_con_agua),
    aplicar_agua_a_grilla(Grid, Indices_con_agua, GridConAgua, Nuevos),
    length(Nuevos, CantidadAgua),
    % --------------------------------------
    eliminar_path(GridConAgua, Path, Grid1),
    
    gravedad(Grid1, NumOfColumns, Grid2), %los comentados no borrarlos son para cuando ande la gravedad
    
    Effects=[
        effect(Grid1, [achieved([[Color, Cantidad], [~, CantidadAgua]])]), %logro de haber eliminado el camino
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

mismo_color(Grid, [X|Z], Color, Cantidad):-
    color_en(Grid, X, Color),
    forall(member(Y, Z), color_en(Grid, Y, Color)),
    length([X|Z], Cantidad).
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
remover_color(Celda, [~]) :- 
    member(~, Celda), !.
remover_color(_, []).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-----bomba-------------------
es_bomba(Path) :-
    Path = [Primero|Resto],
    last(Resto, Ultimo),
    Primero == Ultimo.
es_bomba([_|Resto]) :- 
    Resto = [X|XResto],
    last(Resto, Ultimo),
    (X == Ultimo -> 
        true ; 
        es_bomba(XResto)).

eliminar_colores([], _, []).
eliminar_colores([Celda|Resto], Color, [NuevaCelda|RestoNew]) :-
    (Celda = [Color|_] -> 
        remover_color(Celda, NuevaCelda)
    ;   
        NuevaCelda = Celda
    ),
    eliminar_colores(Resto, Color, RestoNew).


% ---------------Expancion Agua-------------------
expandir_agua_en_jugada(Grid, Path, NumOfColumns, Resultado) :-
    % CONDICIÓN: Buscamos si existe un punto P en el camino que...
    member(P, Path), 
    (   
        % ...ya tenga agua él mismo
        celda_tiene_agua(Grid, P) 
    ;   
        % ...o tenga un vecino V (usando tu adyacente) que tenga agua
        adyacente(P, V, NumOfColumns, Grid),
        celda_tiene_agua(Grid, V)
    ), 
    !,
    Resultado = Path, % Si encontramos al menos uno, el agua se expande a TODO el Path
    writeln('Contacto con agua detectado. Expandiendo al camino seleccionado.').

% Si no se cumple lo de arriba, devolvemos lista vacía (no se moja nada nuevo)
expandir_agua_en_jugada(_, _, _, []).

celda_tiene_agua(Grid, Idx) :- 
    nth0(Idx, Grid, Celda), %busca la selda Idx en la grilla
    member(~, Celda). %se fija si la celda en el índice dado tiene agua

% --------aplicamos el agua a la grilla-----------
aplicar_agua_a_grilla(Grid, IndicesADarAgua, NewGrid, Nuevos) :-
    aplicar_agua_rec(Grid, IndicesADarAgua, 0, NewGrid, Nuevos).

% Caso base: cuando terminamos de recorrer la grilla
aplicar_agua_rec([], _, _, [], []).
% Caso recursivo: procesamos cada celda una por una
aplicar_agua_rec([CeldaOriginal|RestoGrid], Indices, I, [NuevaCelda|RestoNew], Nuevos) :-
    (   member(I, Indices) -> %los indices son los que afecta el agua
        % SI el índice actual I está en la lista para mojar:
        (   member(~, CeldaOriginal) -> 
            % Si ya tenía agua (ej: [r, ~]), la dejamos igual
            NuevaCelda = CeldaOriginal, 
            Nuevos = RestoNuevos
        ;   
            % Si no tenía (ej: [r]), le agregamos el agua al final -> [r, ~]
            append(CeldaOriginal, [~], NuevaCelda),
            Nuevos = [I|RestoNuevos], %guardamos el indice de los nuevos que se mojaron para el logro,
            writeln('nuevos'), writeln(Nuevos)
        )
    ;   
        % SINO: la celda queda exactamente como estaba
        NuevaCelda = CeldaOriginal,
        Nuevos = RestoNuevos
    ),
    % Seguimos con el siguiente índice
    NextI is I + 1,
    aplicar_agua_rec(RestoGrid, Indices, NextI, RestoNew, RestoNuevos).

%----------GRAVEDAD-----------------

%------------ pasamos de la grilla plana a filas y columnas para facilitar la manipulacion de la gravedad -----------
grilla_filas([], _, []).
grilla_filas(GridFlat, NumCol, [Fila|Resto]) :-
    length(Fila, NumCol),
    append(Fila, RestoFlat, GridFlat),
    grilla_filas(RestoFlat, NumCol, Resto).

transponer([], []).
transponer([[]|_], []) :- !.
transponer(Matriz, [Columna|Resto]) :-
    primera_columna(Matriz, Columna, RestoFilas),
    transponer(RestoFilas, Resto).

primera_columna([], [], []).
primera_columna([[X|Xs]|Filas], [X|Col], [Xs|Resto]) :-
    primera_columna(Filas, Col, Resto).

grid_a_columnas(GridFlat, NumCol, Columnas) :-
    grilla_filas(GridFlat, NumCol, Filas),
    transponer(Filas, Columnas).

aplicar_gravedad_columnas([], []).
aplicar_gravedad_columnas([Col|Resto], [NuevaCol|RestoNuevo]) :-
    gravedad_columna_con_obstaculos(Col, NuevaCol),
    aplicar_gravedad_columnas(Resto, RestoNuevo).


gravedad(GridFlat, NumCols, NewGridFlat) :-
   
    grid_a_columnas(GridFlat, NumCols, Columnas),
    
    aplicar_gravedad_columnas(Columnas, ColumnasProcesadas),
    
    % 3. Volvemos a la estructura original
    % Transponemos las columnas procesadas para obtener filas
    transponer(ColumnasProcesadas, FilasProcesadas),
    
    % Aplanamos la lista de filas para volver a tener una lista simple
    append(FilasProcesadas, NewGridFlat), !.

%--------Gravedad Con Obstaculos --------
gravedad_columna_con_obstaculos(Col, NewCol) :-
    % Extraemos colores sobrevivientes
    findall([Color], (member(C, Col), tiene_color_real(C), C = [Color|_]), Sobrevivientes),
    % Calculamos espacio real (restando los [-])
    exclude(es_obstaculo, Col, SinParedes),
    length(SinParedes, Capacidad),
    length(Sobrevivientes, Vivos),
    % Generamos randoms
    Nuevos is Capacidad - Vivos,
    crear_vacios_random(Nuevos, Generados),
    append(Generados, Sobrevivientes, Fichas),
    % Acomodamos respetando los obstáculos del molde
    acomodar_con_obstaculos(Col, Fichas, NewCol), !.

% Esta es la nueva función "mapeadora"
acomodar_con_obstaculos([], [], []).
% Si hay obstáculo, se queda y NO consume ficha
acomodar_con_obstaculos([C|RestoM], Fichas, [C|RestoR]) :-
    es_obstaculo(C), !,
    acomodar_con_obstaculos(RestoM, Fichas, RestoR).
% Si hay agua, pone ficha + agua y consume una ficha
acomodar_con_obstaculos([C|RestoM], [[Color]|RestoF], [[Color, ~]|RestoR]) :-
    (C = [~] ;
        member(~, C)), !,
    acomodar_con_obstaculos(RestoM, RestoF, RestoR).
% Si es celda normal, pone ficha y consume una ficha
acomodar_con_obstaculos([_|RestoM], [F|RestoF], [F|RestoR]) :-
    acomodar_con_obstaculos(RestoM, RestoF, RestoR).


% --- AUXILIARES ---
crear_vacios_random(0, []) :- !.
crear_vacios_random(N, [[Color]|R]) :-
    N > 0,
    random_member(Color, [r,g,y,c,p]),
    N1 is N - 1,
    crear_vacios_random(N1, R).

tiene_color_real(Celda) :- 
    Celda = [Color|_], 
    es_color(Color).

es_agua([~]).
es_obstaculo([-]).
