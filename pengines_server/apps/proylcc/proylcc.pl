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
        connect/4,
        usar_powerup/5
    ]).
:-use_module(library(lists)).
:- use_module(library(random)).

% ========================================================================================================================================================================
%                                                                   MOTOR PRINCIPAL (connect, validaciones, mismo_color)
% ========================================================================================================================================================================

% ENTRADA PRINCIPAL
% connect(+Grid, +NumOfColumns, +Path, -Effects)
connect(Grid, NumOfColumns, Path, Effects) :- % motor de todo el manejo de la jugada
    % verificamos que el camino sea válido
    camino_valido(Path, NumOfColumns, Grid),
    mismo_color(Grid, Path, Color, Cantidad),

    % verificamo si es cerrado y luego bomba
    (es_cerrado(Path) ->
        %1. En camino cerrado sea bomba o no se eliminan todas las fichas del mismo color.
        eliminar_color(Grid, Path, NumOfColumns, Color, GridSinColores, CantidadRealColor,NuevosAgua),

        % 2. condición excusiva de colocación de bombas 
        encontrar_posiciones_bombas(Path, NumOfColumns, Grid, IndicesBombas),
        (IndicesBombas \= [] ->
            colocar_bombas_en_grid(GridSinColores, IndicesBombas, GridPreGravedad)
        ;
            GridPreGravedad = GridSinColores
        )
    ;   
        %En Two dots si se conectan 13 o mas puntos del mismo color, se elimina TODO ese color de la grilla
        Cantidad >= 13 ->
            eliminar_color(Grid, Path, NumOfColumns, Color, GridPreGravedad, CantidadRealColor, NuevosAgua)
        ;
            % CASO NORMAL: Solo el camino
            CantidadRealColor = Cantidad,
            expandir_agua_en_jugada(Grid, Path, NumOfColumns, IndicesAgua),
            aplicar_agua_a_grilla(Grid, IndicesAgua, GridConAgua, NuevosAgua),
            eliminar_path(GridConAgua, Path, GridPreGravedad)
        
    ),

    length(NuevosAgua, CantidadAgua),

   % 3. Gravedad Inicial (caen las fichas y se acomodan las bombas negras)
    gravedad(GridPreGravedad, NumOfColumns, GridPostGravedad1),

    % 4. Explosión y Gravedad Final
    % (Si hay bombas en la grilla, explotan y vuelve a actuar la gravedad)
   
    explosionar_bombas(GridPostGravedad1, NumOfColumns, GridPostExplosion, HuboExplosion, AchievedBombas),
    (HuboExplosion == true ->
        gravedad(GridPostExplosion, NumOfColumns,TempFinal),
        BaseEffects = [
            effect(GridPreGravedad, [achieved([[Color, CantidadRealColor], [~, CantidadAgua]])]),
            effect(GridPostGravedad1, [cae]),
            effect(GridPostExplosion, [explosion, achieved(AchievedBombas)]),
            effect(TempFinal, [cae])
        ]
    ;
        TempFinal = GridPostGravedad1,
        BaseEffects = [
            effect(GridPreGravedad, [achieved([[Color, CantidadRealColor], [~, CantidadAgua]])]),
            effect(TempFinal, [cae])
        ]
    ),

    juntar_efectos_con_mezcla(TempFinal, NumOfColumns, BaseEffects, Effects).

%-------------------------------------------------------------------------------------------------------------
    % eliminar_color(+Grid, +Path, +NumOfColumns, +Color, -GridSinColores, -CantidadRealColor, -NuevosAgua)
    eliminar_color(Grid, Path, NumOfColumns, Color, GridSinColores, CantidadRealColor,NuevosAgua) :-
        encontrar_indices_color(Grid, Color, IndicesColorTotal),
        length(IndicesColorTotal, CantidadRealColor),

        % 1. factor común de las cosas que se hacen en todo camino cerrado, bomba o no.
        expandir_agua_en_jugada(Grid, Path, NumOfColumns, IndicesAgua1),
        aplicar_agua_a_grilla(Grid, IndicesAgua1, GridConAgua1, _),
        expandir_agua_desde_colores_eliminados(GridConAgua1, Color, NumOfColumns, IndicesAgua2),
        append(IndicesAgua1, IndicesAgua2, IndicesAgua),
        aplicar_agua_a_grilla(Grid, IndicesAgua, GridConAgua, NuevosAgua),
        eliminar_colores(GridConAgua, Color, GridSinColores).
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VALIDAMOS LA JUGADA
/* Lógica
Grilla de puntos de colores conectables.
El usuario debe poder seleccionar y conectar puntos adyacentes del mismo color
para formar una jugada válida. Al completar la jugada, esos puntos desaparecen.*/

% camino_valido(+Path, +NumOfColumns, +Grid)
camino_valido([_], _, _).
camino_valido([X, Y|Resto], NumOfColumns, Grid):-
    celda_con_color(Grid, X),
    celda_con_color(Grid, Y),
    X \= Y,
    adyacente(X, Y, NumOfColumns, Grid),
    camino_valido([Y|Resto], NumOfColumns, Grid).

% adyacente(+X, ?Y, +NumOfColumns, +Grid)
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

% celda_con_color(+Grid, +Indice)
celda_con_color(Grid, Indice):-
    esta_elemento(Indice, Grid, Celda),
    Celda \= [],
    Celda \= [-],
    Celda = [Color | _],
    es_color(Color).

% color_en(+Grid, +Indice, ?Color)
color_en(Grid, Indice, Color):-
    esta_elemento(Indice, Grid, Celda),
    Celda = [Color | _],
    es_color(Color).

% es_color(+X)
es_color(X):-
    member(X, [r, g, y, c, p, b]).

% mismo_color(+Grid, +Path, -Color, -Cantidad)
mismo_color(Grid, [X|Z], Color, Cantidad):-
    color_en(Grid, X, Color),
    forall(member(Y, Z), color_en(Grid, Y, Color)),
    length([X|Z], Cantidad).

% esta_elemento(+E, +Lista, -X)
esta_elemento(E, Lista, X) :-
    E >= 0,
    nth0(E, Lista, X).

% =======================================================================================================================================================================
%                                                               MECÁNICAS BÁSICAS (eliminación, bombas, agua)
% =======================================================================================================================================================================


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ------------------------------------------------------------------------------- ELIMINACIÓN ------------------------------------------------------------------------------------------
% eliminar_path(+Grid, +Path, -NewGrid)
eliminar_path(Grid, [], Grid).

eliminar_path(Grid, [Idx|RestoPath], NewGrid) :-
    nth0(Idx, Grid, CeldaVieja, GridSinIdx),
    remover_color(CeldaVieja, CeldaNueva),
    nth0(Idx, TempGrid, CeldaNueva, GridSinIdx),
    eliminar_path(TempGrid, RestoPath, NewGrid).

% remover_color(+CeldaVieja, -CeldaNueva)
remover_color([-], [-]) :- !.
remover_color(Celda, [~]) :- 
    tiene_agua(Celda), !.
remover_color(_, []).

% Se encarga del flujo estándar: calcular agua, eliminar path, aplicar gravedad y armar el efecto.
% eliminacion_simple(+Grid, +Path, +NumOfColumns, +Color, +Cantidad, -Effects)
eliminacion_simple(Grid, Path, NumOfColumns, Color, Cantidad, Effects) :-
    expandir_agua_en_jugada(Grid, Path, NumOfColumns, IndicesAgua),
    aplicar_agua_a_grilla(Grid, IndicesAgua, GridConAgua, NuevosAgua),
    eliminar_path(GridConAgua, Path, GridPreGravedad),
      
    length(NuevosAgua, CantidadAgua),
    gravedad(GridPreGravedad, NumOfColumns, TempFinal),
        
    BaseEffects = [
        effect(GridPreGravedad, [achieved([[Color, Cantidad], [~, CantidadAgua]])]),
        effect(TempFinal, [cae])
    ],

    juntar_efectos_con_mezcla(TempFinal, NumOfColumns, BaseEffects, Effects).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%---------------------------------------------------------------------------------   BOMBA -----------------------------------------------------------------------------------------------------
% es_cerrado(+Path)
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

% Encontrar posiciones de bombas usando Flood Fill desde los bordes
% encontrar_posiciones_bombas(+Path, +NumOfColumns, +Grid, -IndicesBombas)
encontrar_posiciones_bombas(Path, NumOfColumns, Grid, IndicesBombas) :-
    extraer_loop(Path, Loop),
    length(Grid, TotalCells),
    bordes_grilla(TotalCells, NumOfColumns, Bordes),
    
    % Le "restamos" a los Bordes todos los puntos que estén en el Loop (la figura cerrada real)
    subtract(Bordes, Loop, BordesLibres),
   
    inundar(BordesLibres, Loop, NumOfColumns, Grid, [], Exterior),
    MaxI is TotalCells - 1,
    findall(I, (
        between(0, MaxI, I),
        \+ member(I, Path), % No ponemos bombas en lugares que son parte del Path original
        \+ member(I, Exterior)
    ), IndicesBombas).

% Extrae únicamente la parte del Path que forma el ciclo cerrado
% extraer_loop(+Path, -Loop)
extraer_loop(Path, Loop) :-
    last(Path, Ultimo),
    extraer_desde(Ultimo, Path, Loop).

extraer_desde(E, [E|Resto], [E|Resto]) :- !.
extraer_desde(E, [_|Resto], Loop) :-
    extraer_desde(E, Resto, Loop).


% Encontrar todas las posiciones de los bordes de la grilla sin duplicados
% bordes_grilla(+TotalCells, +NumOfColumns, -BordesUnicos)
bordes_grilla(TotalCells, NumOfColumns, BordesUnicos) :-
    MaxI is TotalCells - 1,
    findall(I, (
        between(0, MaxI, I),
        es_borde(I, NumOfColumns, TotalCells)
    ), Bordes),
    sort(Bordes, BordesUnicos).

% Un índice es borde si está en la fila 0, última fila, columna 0 o última columna
% es_borde(?I, +NumOfColumns, +TotalCells)
es_borde(I, NumOfColumns, _) :- I < NumOfColumns.
es_borde(I, NumOfColumns, TotalCells) :- I >= TotalCells - NumOfColumns.
es_borde(I, NumOfColumns, _) :- I mod NumOfColumns =:= 0.
es_borde(I, NumOfColumns, _) :- I mod NumOfColumns =:= NumOfColumns - 1.

% Flood Fill (Inundación)
% inundar(+ToVisit, +Path, +NumOfColumns, +Grid, +Visited, -FinalVisited)
inundar([], _, _, _, Visited, Visited).
inundar([Act | RestoToVisit], Path, NumOfColumns, Grid, Visited, FinalVisited) :-
    % Si el nodo actual ya fue visitado (por precaución), lo salteamos
    ( member(Act, Visited) ->
        inundar(RestoToVisit, Path, NumOfColumns, Grid, Visited, FinalVisited)
    ;
        % Agregamos Act a los visitados
        NuevoVisited = [Act | Visited],
        % Buscamos vecinos válidos (adentro de grilla, ortogonales)
        vecinos_ortogonales(Act, NumOfColumns, Grid, Vecinos),
        % Filtramos vecinos: que no estén en Path, no estén en NuevoVisited, no estén en RestoToVisit
        findall(V, (
            member(V, Vecinos),
            \+ member(V, Path),
            \+ member(V, NuevoVisited),
            \+ member(V, RestoToVisit)
        ), VecinosValidos),
        % Agregamos los vecinos válidos a la cola de procesamiento
        append(RestoToVisit, VecinosValidos, NuevoToVisit),
        % Llamada recursiva
        inundar(NuevoToVisit, Path, NumOfColumns, Grid, NuevoVisited, FinalVisited)
    ).

% vecinos_ortogonales(+I, +NumOfColumns, +Grid, -Vecinos)
vecinos_ortogonales(I, NumOfColumns, Grid, Vecinos) :-
    findall(V, adyacente(I, V, NumOfColumns, Grid), Vecinos).

% Coloca las bombas respetando el agua si la hubiera
% colocar_bombas_en_grid(+Grid, +IndicesBombas, -NewGrid)
colocar_bombas_en_grid(Grid, [], Grid).
colocar_bombas_en_grid(Grid, [Idx|RestoIdx], NewGrid) :-
    nth0(Idx, Grid, CeldaOriginal, GridSinIdx),
    
    (es_obstaculo(CeldaOriginal) ->
        CeldaNueva = CeldaOriginal
    ;
    tiene_agua(CeldaOriginal) -> 
    CeldaNueva = [b, ~] 
    ; 
    CeldaNueva = [b] ),
    
    nth0(Idx, TempGrid, CeldaNueva, GridSinIdx),
    colocar_bombas_en_grid(TempGrid, RestoIdx, NewGrid).

% adyacente_bomba(+X, -Y, +NumOfColumns, +Grid)
adyacente_bomba(X, Y, NumOfColumns, Grid) :-
    length(Grid, Len),
    FilaX is X // NumOfColumns,
    ColX is X mod NumOfColumns,
    between(-1, 1, DFila),
    between(-1, 1, DCol),
    (DFila \= 0 ; DCol \= 0),
    FilaY is FilaX + DFila,
    ColY is ColX + DCol,
    FilaY >= 0,
    ColY >= 0,
    ColY < NumOfColumns,
    Y is FilaY * NumOfColumns + ColY,
    Y < Len.

% Detecta dónde cayeron las bombas, busca vecinos y limpia
% explosionar_bombas(+Grid, +NumOfColumns, -GridFinal, -HuboExplosion, -AchievedBombas)
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
        sort(IndicesBrutos, IndicesUnicos),
        
        findall(I, (
            member(I, IndicesUnicos),
            nth0(I, Grid, Celda),
            \+ es_obstaculo(Celda) % Si es obstáculo, lo ignoramos
        ), IndicesAEliminar),

        contar_colores_destruidos(Grid, IndicesAEliminar, AchievedBombasBase),
        
        % expansión de agua  para mojar todos los índices destruidos (si al menos uno toca agua)
        expandir_agua_en_jugada(Grid, IndicesAEliminar, NumOfColumns, TodosLosAguaBruto),
        
        % Juntamos y aplicamos el agua
        sort(TodosLosAguaBruto, TodosLosAgua),
        aplicar_agua_a_grilla(Grid, TodosLosAgua, GridConAgua, NuevosAguaBomba),
        
        % Contamos el agua nueva y la agregamos a los objetivos cumplidos
        length(NuevosAguaBomba, CantidadAguaBomba),
        (CantidadAguaBomba > 0 ->
            append(AchievedBombasBase, [[~, CantidadAguaBomba]], AchievedBombas)
        ;
            AchievedBombas = AchievedBombasBase
        ),
        
        eliminar_path(GridConAgua, IndicesAEliminar, GridFinal)
    ;   
        HuboExplosion = false,
        GridFinal = Grid,
        AchievedBombas = []
    ).

% contar_colores_destruidos(+Grid, +Indices, -Achieved)
contar_colores_destruidos(Grid, Indices, Achieved) :-
    findall(Color, (
        member(I, Indices),
        nth0(I, Grid, Celda),
        Celda = [Color|_],
        es_color(Color)
    ), ColoresDestruidos),
    contar_ocurrencias(ColoresDestruidos, Achieved).

% contar_ocurrencias(+Lista, -Frecuencias)
contar_ocurrencias([], []).
contar_ocurrencias([H|T], Frecuencias) :-
    contar_ocurrencias(T, RestoFrecuencias),
    actualizar_frecuencia(H, RestoFrecuencias, Frecuencias).

% actualizar_frecuencia(+Color, +Frecuencias, -FrecuenciasActualizadas)
actualizar_frecuencia(C, [], [[C, 1]]).
actualizar_frecuencia(C, [[C, N]|T], [[C, N1]|T]) :- N1 is N + 1, !.
actualizar_frecuencia(C, [[C1, N1]|T], [[C1, N1]|T2]) :-
    C \= C1,
    actualizar_frecuencia(C, T, T2).

% Elimina las celdas usando remover_color/2 para no romper la lógica de agua/obstáculos
%eliminar_colores(+Grid, +Color, -NewGrid)
eliminar_colores([], _, []).
eliminar_colores([Celda|Resto], Color, [NuevaCelda|RestoNew]) :-
    (Celda = [Color|_] -> 
        remover_color(Celda, NuevaCelda)
    ;   
        NuevaCelda = Celda
    ),
    eliminar_colores(Resto, Color, RestoNew).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%--------------------------------------------------------------------------------------------     AGUA      ----------------------------------------------------------------------------

% Encuentra índices adyacentes a agua de los puntos donde estaba ese color
% encontrar_indices_color(+Grid, +Color, -Indices)
encontrar_indices_color(Grid, Color, Indices) :-
    findall(I, (nth0(I, Grid, Celda), Celda = [Color|_]), Indices).

% expandir_agua_desde_colores_eliminados(+Grid, +Color, +NumOfColumns, -IndicesAExpandir)
expandir_agua_desde_colores_eliminados(Grid, Color, NumOfColumns, IndicesAExpandir) :-
     encontrar_indices_color(Grid, Color, IndicesColor),
    findall(I,
        (
            member(I, IndicesColor),
            adyacente(I, V, NumOfColumns, Grid),
            celda_tiene_agua(Grid, V)
        ),
        Iniciales
    ),
    expandir_agua_por_color(Grid, NumOfColumns,Iniciales,IndicesAExpandir).

% expandir_agua_por_color(+Grid, +NumOfColumns, +Iniciales, -Resultado)
expandir_agua_por_color(Grid, NumOfColumns, Iniciales, Resultado) :-
    expandir_agua_por_color_rec(Iniciales, Grid, NumOfColumns, Iniciales, ResultadoUnico),
    sort(ResultadoUnico, Resultado).

expandir_agua_por_color_rec([], _, _, Visitados, Visitados).
expandir_agua_por_color_rec([Act|Resto], Grid, NumOfColumns, Visitados, Resultado) :-
    color_en(Grid, Act, ColorAct),
    findall(Vecino, (
        adyacente(Act, Vecino, NumOfColumns, Grid),
        color_en(Grid, Vecino, ColorVecino),
        ColorAct == ColorVecino,           % Verifica que sea del mismo color
        \+ member(Vecino, Visitados)       % Evita ciclos
    ), NuevosVecinos),
    append(Resto, NuevosVecinos, NuevaCola),
    append(Visitados, NuevosVecinos, NuevosVisitados),
    expandir_agua_por_color_rec(NuevaCola, Grid, NumOfColumns, NuevosVisitados, Resultado).

% ---------------Expansión Agua-------------------
% expandir_agua_en_jugada(+Grid, +Path, +NumOfColumns, -IndicesAExpandir)
expandir_agua_en_jugada(Grid, Path, NumOfColumns, Resultado) :-
    % Buscamos si existe un punto P en el camino que..
    member(P, Path), 
    (   
        % ya tenga agua él mismo
        celda_tiene_agua(Grid, P) 
    ;   
        % o tenga un vecino V que tenga agua
        adyacente(P, V, NumOfColumns, Grid),
        celda_tiene_agua(Grid, V)
    ), 
    !,
    Resultado = Path.

expandir_agua_en_jugada(_, _, _, []). % Si no se cumple lo de arriba, devolvemos lista vacía (no se moja nada nuevo)

% celda_tiene_agua(+Grid, +Idx)
celda_tiene_agua(Grid, Idx) :- 
    nth0(Idx, Grid, Celda), %busca la celda Idx en la grilla
    tiene_agua(Celda). %se fija si la celda en el índice dado tiene agua

% --------aplicamos el agua a la grilla-----------
% aplicar_agua_a_grilla(+Grid, +IndicesADarAgua, -NewGrid, -Nuevos)
aplicar_agua_a_grilla(Grid, IndicesADarAgua, NewGrid, Nuevos) :-
    aplicar_agua_rec(Grid, IndicesADarAgua, NewGrid, Nuevos).
% Caso base
aplicar_agua_rec(Grid, [], Grid, []).
% Caso recursivo
aplicar_agua_rec(Grid, [Idx|RestoIdx], NewGrid, Nuevos) :-
    % Sacamos la celda vieja y nos guardamos la grilla sin el idx
    nth0(Idx, Grid, CeldaOriginal, GridSinIdx),
    
    (es_obstaculo(CeldaOriginal) ->
        % Si es un obstáculo, lo ignoramos por completo
        CeldaNueva = CeldaOriginal,
        Nuevos = RestoNuevos
        ;
        tiene_agua(CeldaOriginal) -> 
        CeldaNueva = CeldaOriginal,
        Nuevos = RestoNuevos
    ; 
        append(CeldaOriginal, [~], CeldaNueva),
        Nuevos = [Idx|RestoNuevos]
    ),
    % Usamos el mismo nth0, pero "al revés", para tapar remplazar el idx por el nuevo 
    nth0(Idx, TempGrid, CeldaNueva, GridSinIdx),
    
    aplicar_agua_rec(TempGrid, RestoIdx, NewGrid, RestoNuevos).


% ==============================================================================================================================================
%                                                  FÍSICAS (gravedad, transponer matrices)
% ==============================================================================================================================================
%------------ pasamos de la grilla plana a filas y columnas para facilitar la manipulacion de la gravedad -----------
% grilla_filas(+GridFlat, +NumCol, -Filas)
grilla_filas([], _, []).
grilla_filas(GridFlat, NumCol, [Fila|Resto]) :-
    length(Fila, NumCol),
    append(Fila, RestoFlat, GridFlat),
    grilla_filas(RestoFlat, NumCol, Resto).

% transponer(+Matriz, -Transpuesta)
transponer([], []).
transponer([[]|_], []) :- !.
transponer(Matriz, [Columna|Resto]) :-
    primera_columna(Matriz, Columna, RestoFilas),
    transponer(RestoFilas, Resto).

% primera_columna(+Matriz, -Columna, -RestoFilas)
primera_columna([], [], []).
primera_columna([[X|Xs]|Filas], [X|Col], [Xs|Resto]) :-
    primera_columna(Filas, Col, Resto).

% grid_a_columnas(+GridFlat, +NumCol, -Columnas)
grid_a_columnas(GridFlat, NumCol, Columnas) :-
    grilla_filas(GridFlat, NumCol, Filas),
    transponer(Filas, Columnas).

% aplicar_gravedad_columnas(+Columnas, -ColumnasProcesadas)
aplicar_gravedad_columnas([], []).
aplicar_gravedad_columnas([Col|Resto], [NuevaCol|RestoNuevo]) :-
    gravedad_columna_con_obstaculos(Col, NuevaCol),
    aplicar_gravedad_columnas(Resto, RestoNuevo).

% gravedad(+GridFlat, +NumCols, -NewGridFlat)
gravedad(GridFlat, NumCols, NewGridFlat) :-
   
    grid_a_columnas(GridFlat, NumCols, Columnas),
    
    aplicar_gravedad_columnas(Columnas, ColumnasProcesadas),
    
    % Volvemos a la estructura original, transponemos las columnas procesadas para obtener filas
    transponer(ColumnasProcesadas, FilasProcesadas),
    
    % Aplanamos la lista de filas para volver a tener una lista simple
    append(FilasProcesadas, NewGridFlat), !.

%--------Gravedad Con Obstaculos --------
% gravedad_columna_con_obstaculos(+Columna, -NuevaColumna)
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


% acomodar_con_obstaculos(+ColumnaOriginal, +FichasDisponibles, -ColumnaResultante)
acomodar_con_obstaculos([], [], []).
% Si hay obstáculo, se queda y NO consume ficha
acomodar_con_obstaculos([C|RestoM], Fichas, [C|RestoR]) :-
    es_obstaculo(C), !,
    acomodar_con_obstaculos(RestoM, Fichas, RestoR).
% Si hay agua, pone ficha + agua y consume una ficha
acomodar_con_obstaculos([C|RestoM], [[Color]|RestoF], [[Color, ~]|RestoR]) :-
    (C = [~] ;
        tiene_agua(C)), !,
    acomodar_con_obstaculos(RestoM, RestoF, RestoR).
% Si es celda normal, pone ficha y consume una ficha
acomodar_con_obstaculos([_|RestoM], [F|RestoF], [F|RestoR]) :-
    acomodar_con_obstaculos(RestoM, RestoF, RestoR).


% --- AUXILIARES ---
% crear_vacios_random(+N, -ListaVacios)
crear_vacios_random(0, []) :- !.
crear_vacios_random(N, [[Color]|R]) :-
    N > 0,
    random_member(Color, [r,g,y,c,p]),
    N1 is N - 1,
    crear_vacios_random(N1, R).

% tiene_color_real(+Celda)
tiene_color_real(Celda) :- 
    Celda = [Color|_], 
    es_color(Color).

% tiene_agua(+Celda)
tiene_agua(Celda) :- 
    member(~, Celda).

% es_obstaculo(+Celda)
es_obstaculo([-]).

% ========================================================================================
%       RESOLUCIÓN DE PUNTO MUERTO (DEADLOCK) - MEZCLA AUTOMÁTICA
% ========================================================================================

% 1. Verifica si hay al menos un par de colores iguales conectados en todo el tablero
hay_movimientos(Grid, NumOfColumns) :-
    nth0(Idx, Grid, Celda),
    Celda = [Color|_],
    es_color(Color),
    adyacente(Idx, Vecino, NumOfColumns, Grid),
    nth0(Vecino, Grid, CeldaVecina),
    CeldaVecina = [Color|_],
    !. % Optimización: Al encontrar el PRIMER par válido, corta la búsqueda y da true.

% 2. junta los efectos. Si no hay movimientos, inyecta una mezcla al final de la animación.
juntar_efectos_con_mezcla(GridFinal, NumOfColumns, BaseEffects, Effects) :-
    ( hay_movimientos(GridFinal, NumOfColumns) ->
        Effects = BaseEffects % Todo normal, hay movimientos
    ;
        mezclar_grilla_segura(GridFinal, NumOfColumns, GridMezclada),
        % No hay masmovimientos, Mezclamos la grilla de forma segura
        ( hay_movimientos(GridMezclada, NumOfColumns) ->
            % Se salvó, le mandamos el tablero mezclado
            append(BaseEffects, [effect(GridMezclada, [mezcla_automatica])], Effects)
        ;
            % Se agotaron los intentos y sigue trabado. Mandamos la señal de muerte.
            append(BaseEffects, [effect(GridMezclada, [deadlock])], Effects)
        )
    ).

% 3. Lógica de mezcla SEGURA (que garantice que quede al menos un movimiento)
mezclar_grilla_segura(Grid, NumOfColumns, GridSegura) :-
    intentar_mezclar(Grid, NumOfColumns, 10, GridSegura).

intentar_mezclar(Grid, NumOfColumns, Intentos, GridSegura) :-
    Intentos > 0,
    mezclar_grilla_base(Grid, GridMezclada),
    ( hay_movimientos(GridMezclada, NumOfColumns) ->
        GridSegura = GridMezclada % Éxito
    ;
        IntentosRestantes is Intentos - 1,
        intentar_mezclar(GridMezclada, NumOfColumns, IntentosRestantes, GridSegura)
    ).
intentar_mezclar(Grid, _, 0, Grid). % Fallback: Si intentó 10 veces y no pudo, devuelve lo que hay para no romper la app.

mezclar_grilla_base(Grid, ShuffledGrid) :-
    findall(Color, (member(Celda, Grid), Celda = [Color|_], es_color(Color)), ColoresPuros),
    mezclar_lista(ColoresPuros, ColoresMezclados),
    reconstruir_grilla_mezclada(Grid, ColoresMezclados, ShuffledGrid).

% reconstruir_grilla_mezclada(+GridMolde, +ColoresDisponibles, -NuevaGrid)
reconstruir_grilla_mezclada([], [], []).
reconstruir_grilla_mezclada([CeldaOrig|RestoOrig], ColoresDisp, [NuevaCelda|RestoNueva]) :-
    es_obstaculo(CeldaOrig), !, % Es un obstáculo. Se copia igual y NO se consume ningún color.
    NuevaCelda = CeldaOrig,
    reconstruir_grilla_mezclada(RestoOrig, ColoresDisp, RestoNueva).
reconstruir_grilla_mezclada([CeldaOrig|RestoOrig], [ColorNuevo|RestoDisp], [NuevaCelda|RestoNueva]) :-
    tiene_agua(CeldaOrig), !, % La celda original tenía agua. Le metemos el color nuevo + el agua. Se consume 1 color.
    NuevaCelda = [ColorNuevo, ~],
    reconstruir_grilla_mezclada(RestoOrig, RestoDisp, RestoNueva).
reconstruir_grilla_mezclada([_|RestoOrig], [ColorNuevo|RestoDisp], [[ColorNuevo]|RestoNueva]) :-
    reconstruir_grilla_mezclada(RestoOrig, RestoDisp, RestoNueva). % Celda normal. Se pone el color puro. Se consume 1 color.


% mezclar_lista(+Lista, -ListaMezclada)
mezclar_lista([], []).
mezclar_lista(Lista, [Elem|RestoMezclado]) :-
    % 1. Elegimos un elemento al azar de la lista original
    random_member(Elem, Lista),
    % 2. Lo removemos de la lista (select saca la primera coincidencia que encuentra)
    select(Elem, Lista, RestoLista),
    % 3. Repetimos el proceso con los elementos que sobran
    mezclar_lista(RestoLista, RestoMezclado).

% =========================================================================================================================================================================
%                                                              HABILIDADES ESPECIALES (Power-Ups)
% =========================================================================================================================================================================

% usar_powerup(+PowerUp, +Grid, +NumOfColumns, +TargetIndices, -Effects)
% Borrar un color entero 
usar_powerup(borrar_color, Grid, NumOfColumns, [TargetIdx], Effects) :-
    color_en(Grid, TargetIdx, Color),
    eliminar_color(Grid, [TargetIdx], NumOfColumns, Color, GridPreGravedad, CantidadRealColor, NuevosAgua),
    length(NuevosAgua, CantidadAgua),
    gravedad(GridPreGravedad, NumOfColumns, TempFinal),
    BaseEffects = [
        effect(GridPreGravedad, [achieved([[Color, CantidadRealColor], [~, CantidadAgua]])]),
        effect(TempFinal, [cae])
    ],
    % Enviamos a chequear deadlock por si borrar este color rompió el tablero
    juntar_efectos_con_mezcla(TempFinal, NumOfColumns, BaseEffects, Effects).

% Borrar una sola ficha con un borrador
usar_powerup(borrador, Grid, NumOfColumns, [TargetIdx], Effects) :-
    color_en(Grid, TargetIdx, Color),
    % Definimos que el camino es solo esa ficha y la cantidad es 1
    Path = [TargetIdx],
    Cantidad = 1,
    eliminacion_simple(Grid, Path, NumOfColumns, Color, Cantidad, Effects).

% Romper la fila y columna de una ficha (Cruz)
usar_powerup(cruz, Grid, NumOfColumns, [TargetIdx], Effects) :-
    indices_en_cruz(TargetIdx, NumOfColumns,  Grid, PathCruz),
    contar_colores_destruidos(Grid, PathCruz, AchievedBase),
    expandir_agua_en_jugada(Grid, PathCruz, NumOfColumns, IndicesAgua),
    aplicar_agua_a_grilla(Grid, IndicesAgua, GridConAgua, NuevosAgua),
    eliminar_path(GridConAgua, PathCruz, GridPreGravedad),
    length(NuevosAgua, CantidadAgua),
    (CantidadAgua > 0 ->
        append(AchievedBase, [[~, CantidadAgua]], AchievedFinal)
    ;
        AchievedFinal = AchievedBase
    ),
    gravedad(GridPreGravedad, NumOfColumns, TempFinal),
    BaseEffects = [
        effect(GridPreGravedad, [achieved(AchievedFinal)]),
        effect(TempFinal, [cae])
    ],
    % Enviamos a chequear deadlock
    juntar_efectos_con_mezcla(TempFinal, NumOfColumns, BaseEffects, Effects).

% Mezclar todo el tablero 
usar_powerup(mezclar, Grid, NumOfColumns, _, Effects) :-
    mezclar_grilla_segura(Grid, NumOfColumns, ShuffledGrid),
    % Verificamos cómo quedó después del intento de mezcla
    ( hay_movimientos(ShuffledGrid, NumOfColumns) ->
        Effects = [ effect(ShuffledGrid, []) ]
    ;
        % Si ni siquiera la mezcla lo salvó, forzamos la muerte de la partida
        Effects = [ effect(ShuffledGrid, [deadlock]) ]
    ).

% indices_en_cruz(+TargetIdx, +NumOfColumns, +Grid, -IndicesCruz)
indices_en_cruz(TargetIdx, NumOfColumns, Grid, IndicesCruz) :-
    FilaObjetivo is TargetIdx // NumOfColumns,
    ColObjetivo is TargetIdx mod NumOfColumns,
    
    % Encontramos todos los índices que compartan fila o columna
    findall(I, (
        nth0(I, Grid, _),
        (I // NumOfColumns =:= FilaObjetivo ; I mod NumOfColumns =:= ColObjetivo)
    ), IndicesCruz).



