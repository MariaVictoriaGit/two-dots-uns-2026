import React, { useEffect } from 'react';
import { colors, colorToCss, Grid } from './model';
import Cell from './Cell';
import { connectable, connectionInPath, isAdyacent, isConnectableDot } from './helpers';
import Connector from './Connector';
import styles from './Board.module.css';

interface BoardProps {
    grid: Grid;
    numOfColumns: number;
    path: number[];
    onPathChange: (path: number[]) => void;
    onDone: () => void;
    readonly?: boolean;
}

function Board({ grid, numOfColumns, path, onPathChange, onDone, readonly }: BoardProps) {

    function onDotDown(pos: number) {
        if (readonly) {
            return;
        }
        if (path.length === 0) {    // Presionó el primer cuadrado, así que se inicia el camino con ese cuadrado.
            onPathChange([pos]);
        }
    }

    function onDotHover(pos: number) {
        if (path.length === 0) { // Ignorar si no se está formando un camino.    
            return;
        }
        if (!grid[pos].some(content => isConnectableDot(content))) { // Ignorar si el cuadrado no tiene un punto conectable.
            return;
        }
        if (!isAdyacent(pos, path[path.length - 1], numOfColumns)) { // Ignorar si no hay adyacencia entre el cuadrado y el último del camino.
            return;
        }
        if (path.length > 1 && pos === path[path.length - 2]) { // Quitar el último cuadrado del camino si se regresa al anterior. Esto permite corregir errores al formar el camino.         
            onPathChange(path.slice(0, path.length - 1));
        } else if (path.length > 2 && path.slice(0, path.length - 2).includes(path[path.length - 1])) { // Ignorar si el cuadrado ya está en un camino cerrado.
            return;
        } else if (connectable(pos, path[path.length - 1], grid)) { // Agregar el cuadrado al camino si es adyacente, no está ya en el camino, y es igual o siguiente potencia que el último en el camino.  
            onPathChange(path.concat([pos])); // Agregar un cuadrado al camino si es adyacente, no está ya en el camino, y es igual o siguiente potencia que el último en el camino.  
        }
    }

    useEffect(() => {
        function onUp() {
            if (path.length === 0) return;  // Ignorar si no se está formando un camino.
            if (path.length === 1) {
                onPathChange([]);
            } else {
                onDone();
            }
        }
        window.addEventListener("mouseup", onUp);
        return () => window.removeEventListener("mouseup", onUp);
    }, [path, onPathChange, onDone]);

    useEffect(() => {
        window.addEventListener("keydown", e => {
            if (e.key === "Escape") {
                onPathChange([]);
            }
        });
    }, []);

    const numOfRows = grid.length / numOfColumns;
    return (
        <div className={styles.board} style={{ '--num-columns': numOfColumns, '--num-rows': numOfRows } as React.CSSProperties}>
            <div className={styles.cells}>
                {grid.map((cell, pos) => {
                    const row = Math.floor(pos / numOfColumns);
                    const col = pos % numOfColumns;
                    const hasWater = (p: number) => {
                        return p >= 0 && p < grid.length && grid[p].includes("~");
                    };
                    const waterNeighbors = {
                        top: row > 0 ? hasWater(pos - numOfColumns) : false,
                        bottom: row < numOfRows - 1 ? hasWater(pos + numOfColumns) : false,
                        left: col > 0 ? hasWater(pos - 1) : false,
                        right: col < numOfColumns - 1 ? hasWater(pos + 1) : false,
                    };
                    return (
                        <Cell
                            value={cell}
                            onMouseDown={() => onDotDown(pos)}
                            onMouseEnter={() => onDotHover(pos)}
                            waterNeighbors={waterNeighbors}
                            key={pos}
                        />
                    );
                })}
            </div>
            <div className={styles.horizontalConnectors}>
                {Array.from({ length: numOfRows * (numOfColumns - 1) }, (_, i) => {
                    const row = Math.floor(i / (numOfColumns - 1));
                    const column = i % (numOfColumns - 1);
                    const posA = row * numOfColumns + column;
                    const posB = posA + 1;
                    let from;
                    if (connectionInPath(posA, posB, path)) {
                        from = posA;
                    } else if (connectionInPath(posB, posA, path)) {
                        from = posB;
                    }
                    return (
                        <Connector
                            type={"horizontal"}
                            color={from !== undefined ? colorToCss(grid[from].find(content => colors.includes(content))!) : undefined}
                            key={i}
                        />
                    );
                })}
            </div>
            <div className={styles.verticalConnectors}>
                {Array.from({ length: (numOfRows - 1) * numOfColumns }, (_, i) => {
                    const row = Math.floor(i / numOfColumns);
                    const column = i % numOfColumns;
                    const posA = row * numOfColumns + column;
                    const posB = (row + 1) * numOfColumns + column;
                    let from;
                    if (connectionInPath(posA, posB, path)) {
                        from = posA;
                    } else if (connectionInPath(posB, posA, path)) {
                        from = posB;
                    }
                    return (
                        <Connector
                            type={"vertical"}
                            color={from !== undefined ? colorToCss(grid[from].find(content => colors.includes(content))!) : undefined}
                            key={i}
                        />
                    );
                })}
            </div>
        </div>
    );

}

export default Board;