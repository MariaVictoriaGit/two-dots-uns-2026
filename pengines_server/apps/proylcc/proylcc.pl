/*
[r]        % solo un punto rojo
[-]        % celda vacía / no utilizable
[]         % celda vacía tras eliminación
[c, ~]     % punto celeste con agua
ESTRUCTURA ///
(Condicion ->  COMO EL IF-THEN  
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
% ENTRADA PRINCIPAL
connect(Grid, NumOfColumns, Path, Effects) :- % motor de todo el manejo de la jugada
    % verificamos que el camino sea valido
    camino_valido(Path, NumOfColumns, Grid),
    mismo_color(Grid, Path, Color, Cantidad),
    length(Grid, TotalCells),

    % Verificar si es bomba
    (es_cerrado(Path) ->
        encontrar_indices_color(Grid, Color, IndicesColorTotal),
        length(IndicesColorTotal, CantidadRealColor),
        encontrar_posiciones_bombas(Path, NumOfColumns, TotalCells, IndicesBombas),
        (IndicesBombas \= [] ->
            % CASO BOMBA: Coloca bombas negras donde corresponde
            expandir_agua_en_jugada(Grid, Path, NumOfColumns, IndicesAgua1),
            aplicar_agua_a_grilla(Grid, IndicesAgua1, GridConAgua1, _),
            expandir_agua_desde_colores_eliminados(GridConAgua1, Color, NumOfColumns, IndicesAgua2),
            append(IndicesAgua1, IndicesAgua2, IndicesAgua),
            aplicar_agua_a_grilla(Grid, IndicesAgua, GridConAgua, _),
            eliminar_colores(GridConAgua, Color, GridSinColores),
            colocar_bombas_en_grid(GridSinColores, IndicesBombas, 0, GridPreGravedad)
        ;
            % CASO CERRADO NORMAL: Expande agua desde el path y desde adyacentes al color
            expandir_agua_en_jugada(Grid, Path, NumOfColumns, IndicesAgua1),
            aplicar_agua_a_grilla(Grid, IndicesAgua1, GridConAgua1, _),
            expandir_agua_desde_colores_eliminados(GridConAgua1, Color, NumOfColumns, IndicesAgua2),
            append(IndicesAgua1, IndicesAgua2, IndicesAgua),
            aplicar_agua_a_grilla(Grid, IndicesAgua, GridConAgua, _),
            eliminar_colores(GridConAgua, Color, GridPreGravedad)
        )
    ;   
        % CASO NORMAL: Solo el camino
        CantidadRealColor = Cantidad,
        expandir_agua_en_jugada(Grid, Path, NumOfColumns, IndicesAgua),
        aplicar_agua_a_grilla(Grid, IndicesAgua, GridConAgua, _),
        eliminar_path(GridConAgua, Path, GridPreGravedad)
    ),
    aplicar_agua_a_grilla(Grid, IndicesAgua, _, NuevosAgua),
    length(NuevosAgua, CantidadAgua),

   % 3. Gravedad Inicial (caen las fichas y se acomodan las bombas negras)
    gravedad(GridPreGravedad, NumOfColumns, GridPostGravedad1),

    % 4. Explosión y Gravedad Final
    % (Si hay bombas en la grilla, explotan y vuelve a actuar la gravedad)
    explosionar_bombas(GridPostGravedad1, NumOfColumns, GridPostExplosion, HuboExplosion, AchievedBombas),
    (HuboExplosion == true ->
        gravedad(GridPostExplosion, NumOfColumns, GridFinal),
        Effects = [
            effect(GridPreGravedad, [achieved([[Color, CantidadRealColor], [~, CantidadAgua]])]),
            effect(GridPostGravedad1, [cae]),
            effect(GridPostExplosion, [explosion, achieved(AchievedBombas)]),
            effect(GridFinal, [cae])
        ]
    ;
        GridFinal = GridPostGravedad1,
        Effects = [
            effect(GridPreGravedad, [achieved([[Color, CantidadRealColor], [~, CantidadAgua]])]),
            effect(GridFinal, [cae])
        ]
    ).

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
    member(X, [r, g, y, c, p, b]). % cuida no borrar el efecto, si el color

mismo_color(Grid, [X|Z], Color, Cantidad):-
    color_en(Grid, X, Color),
    forall(member(Y, Z), color_en(Grid, Y, Color)),
    length([X|Z], Cantidad).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%ACCESOS
/* ver si buscamos en un lugar valido e instanciamos el elemento
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

remover_color([-], [-]) :- !.
remover_color(Celda, [~]) :- 
    member(~, Celda), !.
remover_color(_, []).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-----bomba-------------------
es_cerrado(Path) :-
    length(Path, Len),
    Len > 2,
    Path = [Primero|Resto],
    last(Resto, Ultimo),
    Primero == Ultimo.
es_cerrado([_|Resto]) :- 
    length(Resto, Len),
    Len > 2,
    Resto = [X|XResto],
    last(Resto, Ultimo),
    (X == Ultimo -> 
        true ; 
        es_cerrado(XResto)).

% Encontrar posiciones de bombas iterando por toda la grilla y buscando celdas encerradas
encontrar_posiciones_bombas(Path, NumOfColumns, TotalCells, IndicesBombas) :-
    MaxI is TotalCells - 1,
    findall(I, (
        between(0, MaxI, I),
        \+ member(I, Path),
        es_interior(I, Path, NumOfColumns)
    ), IndicesBombas).

% Un punto es interior si está rodeado por el path en las 4 direcciones
es_interior(I, Path, Cols) :-
    Row is I // Cols,
    Col is I mod Cols,
    member(L, Path), L // Cols =:= Row, L < I, !,   % Límite Izquierdo
    member(R, Path), R // Cols =:= Row, R > I, !,   % Límite Derecho
    member(T, Path), T mod Cols =:= Col, T < I, !,  % Límite Superior
    member(B, Path), B mod Cols =:= Col, B > I, !.  % Límite Inferior

% Coloca las bombas respetando el agua si la hubiera
colocar_bombas_en_grid([], _, _, []).
colocar_bombas_en_grid([Celda|Resto], IndicesBombas, I, [NuevaCelda|RestoNew]) :-
    (   member(I, IndicesBombas) ->
        (member(~, Celda) -> NuevaCelda = [b, ~] ; NuevaCelda = [b])
    ;   
        NuevaCelda = Celda
    ),
    NextI is I + 1,
    colocar_bombas_en_grid(Resto, IndicesBombas, NextI, RestoNew).

adyacente_bomba(X, Y, NumOfColumns, Grid) :-
    length(Grid, Len),
    RowX is X // NumOfColumns,
    ColX is X mod NumOfColumns,
    between(-1, 1, DRow),
    between(-1, 1, DCol),
    (DRow \= 0 ; DCol \= 0),
    RowY is RowX + DRow,
    ColY is ColX + DCol,
    RowY >= 0,
    ColY >= 0,
    ColY < NumOfColumns,
    Y is RowY * NumOfColumns + ColY,
    Y < Len.

% Detecta dónde cayeron las bombas, busca vecinos y limpia
explosionar_bombas(Grid, NumOfColumns, GridFinal, HuboExplosion, AchievedBombas) :-
    % Buscamos el color 'b' dentro de las celdas
    findall(I, (nth0(I, Grid, Celda), member(b, Celda)), IndicesBombas),
    (   IndicesBombas \= [] ->
        HuboExplosion = true,
        % Encontrar adyacentes a las bombas
        findall(Adj, (
            member(B, IndicesBombas),
            adyacente_bomba(B, Adj, NumOfColumns, Grid)
        ), IndicesAdyacentes),
        % Juntamos bombas y adyacentes, y eliminamos duplicados con sort/2
        append(IndicesBombas, IndicesAdyacentes, IndicesBrutos),
        sort(IndicesBrutos, IndicesAEliminar),
        
        contar_colores_destruidos(Grid, IndicesAEliminar, AchievedBombas),
        
        eliminar_indices(Grid, IndicesAEliminar, 0, GridFinal)
    ;   
        HuboExplosion = false,
        GridFinal = Grid,
        AchievedBombas = []
    ).

contar_colores_destruidos(Grid, Indices, Achieved) :-
    findall(Color, (
        member(I, Indices),
        nth0(I, Grid, Celda),
        Celda = [Color|_],
        es_color(Color)
    ), ColoresDestruidos),
    contar_ocurrencias(ColoresDestruidos, Achieved).

contar_ocurrencias([], []).
contar_ocurrencias([H|T], Frecuencias) :-
    contar_ocurrencias(T, RestoFrecuencias),
    actualizar_frecuencia(H, RestoFrecuencias, Frecuencias).

actualizar_frecuencia(C, [], [[C, 1]]).
actualizar_frecuencia(C, [[C, N]|T], [[C, N1]|T]) :- N1 is N + 1, !.
actualizar_frecuencia(C, [[C1, N1]|T], [[C1, N1]|T2]) :-
    C \= C1,
    actualizar_frecuencia(C, T, T2).

% Elimina las celdas usando remover_color/2 para no romper la lógica de agua/obstáculos
eliminar_indices([], _, _, []).
eliminar_indices([Celda|Resto], Indices, I, [NuevaCelda|RestoNew]) :-
    (   member(I, Indices) ->
        remover_color(Celda, NuevaCelda)
    ;   
        NuevaCelda = Celda
    ),
    NextI is I + 1,
    eliminar_indices(Resto, Indices, NextI, RestoNew).

eliminar_colores([], _, []).
eliminar_colores([Celda|Resto], Color, [NuevaCelda|RestoNew]) :-
    (Celda = [Color|_] -> 
        remover_color(Celda, NuevaCelda)
    ;   
        NuevaCelda = Celda
    ),
    eliminar_colores(Resto, Color, RestoNew).

% Encuentra índices adyacentes a agua de los puntos donde estaba ese color
encontrar_indices_color(Grid, Color, Indices) :-
    findall(I, (nth0(I, Grid, Celda), Celda = [Color|_]), Indices).

expandir_agua_desde_colores_eliminados(Grid, Color, NumOfColumns, IndicesAExpandir) :-
    encontrar_indices_color(Grid, Color, IndicesColor),
    findall(I, (
        member(I, IndicesColor),
        (   
            % El punto tiene agua adyacente
            adyacente(I, V, NumOfColumns, Grid),
            celda_tiene_agua(Grid, V)
        )
    ), IndicesAExpandir).

% ---------------Expansión Agua-------------------
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
