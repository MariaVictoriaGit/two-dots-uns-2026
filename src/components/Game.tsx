import { useEffect, useState, useCallback } from 'react';
import PengineClient from '../services/PengineClient';
import Board from './Board';
import { delay } from './util';
import styles from './Game.module.css';
import { CellContent, Grid, Objectives, EffectTerm, EffectInfoTerm, colors, colorToCss } from './model';
import { useHistory } from './helpers';

function Game() {
  // State
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const [pengine, setPengine] = useState<any>(null);
  const [grid, setGrid] = useState<Grid | null>(null);
  const [numOfColumns, setNumOfColumns] = useState<number | null>(null);
  const [moves, setMoves] = useState<number | null>(null);
  const [objectives, setObjectives] = useState<Objectives>({});
  const [path, setPath] = useState<number[]>([]);
  const [waiting, setWaiting] = useState(false);
  //este history no tocar tuto quema, es el coso para ver que hicimos en el pasado, no es el historial de movimientos, es el historial de estados del juego, para poder mostrar la animacion de los efectos, cada vez que se hace un movimiento se guarda el estado del juego antes de hacer el movimiento, y se muestra ese estado mientras se muestra la animacion de los efectos, y cuando termina la animacion se muestra el estado actual del juego
  const { grid: historyGrid, objectives: historyObjectives } = useHistory({ grid: grid!, objectives, waiting });

  const initGame = useCallback(async () => {
    if (!pengine) return;
    const queryS = 'init(Grid, NumOfColumns, Goals, Moves)';
    const response = await pengine.query(queryS);
    setGrid(response['Grid']);
    setNumOfColumns(response['NumOfColumns']);
    setMoves(response['Moves']);
    const objectives: Objectives = {};
    response['Goals'].forEach(([block, value]: [CellContent, number]) => {
      objectives[block] = value;
    });
    setObjectives(objectives);
  }, [pengine]);

  useEffect(() => {
    // Esto se ejecuta solo una vez, después del primer renderizado.
    async function connectToPenginesServer() {
      setPengine(await PengineClient.create()); // Espera hasta que se inicialice el servidor
    }
    connectToPenginesServer();
  }, []);

  useEffect(() => {
    if (pengine) {
      // Esto se ejecuta después de que pengine se haya establecido
      // eslint-disable-next-line react-hooks/set-state-in-effect
      initGame();
    }
  }, [pengine, initGame]);

  /**
   * Llamado mientras el usuario está dibujando un camino en la cuadrícula, cada vez que el camino cambia.
   */
  function onPathChange(newPath: number[]) {
    // No effect if waiting.
    if (waiting) {
      return;
    }
    setPath(newPath);
    console.log(JSON.stringify(newPath));
  }

  /**
   * Llamado cuando el usuario termina de dibujar un camino en la cuadrícula.
   */
  async function onPathDone() {
    /* cuando el jugador termina el camino
    * 1. Construye la consulta de Prolog con el estado del juego que quedaría así:
    connect([
            [-], [r], [c], [p], [-], [-], [-], [-],	
            [c], [y], [g], [p], [r], [-], [-], [-],	
            [r], [r], [g], [y], [r], [g], [-], [-],	
            [y], [c], [-], [y], [c], [g], [g], [-],	
            [y, ~], [c, ~], [-], [g], [c, ~], [y, ~], [c, ~], [c],	
            [c, ~], [c, ~], [-], [g, ~], [c, ~], [y, ~], [c, ~], [-],	
            [c, ~], [y, ~], [g, ~], [g, ~], [c, ~], [c, ~], [-], [-],	
            [c, ~], [y, ~], [y, ~], [y, ~], [y, ~], [-], [-], [-],	
            [-], [y, ~], [y, ~], [y], [-], [-], [-], [-]
            ], 8, [21, 29, 30],
          RGrids
        ).
    *///aca contruye una consulta de prolog con el estado actual del juego y el camino elegido por el jugador, y la envia al servidor de Prolog para que la resuelva
    const gridS = JSON.stringify(grid).replaceAll('"', '');
    const pathS = JSON.stringify(path);
    const queryS = "connect(" + gridS + "," + numOfColumns + "," + pathS + ", Effects)";
    setWaiting(true);
    const response = await pengine.query(queryS);
    setPath([]); //el camino va y viene hasta que viene la resouesta de prolog
    if (response) {
      setMoves(moves! - 1);//baja las movidas
      animateEffects(response['Effects']);//animar los efectos que devuelve prolog
    } else {
      console.log("Prolog query failed")
      setWaiting(false);
    }
  }

  /**
   * Muestra cada grilla de la secuencia como la grilla actual en intervalos de 1 segundo, y considera la otra información de efectos.
   * @param effects The list of effects to be animated.
   */
  async function animateEffects(effects: EffectTerm[]) { //itera por cada uno de los efectos, aplica el efecto actual y hace un disley de un segundo entre un efecto y otro
    for (let i = 0; i < effects.length; i++) {
      applyEffect(effects[i]);
      if (i < effects.length - 1) {
        await delay(1000);
      }
    }
    setWaiting(false);
  }

  function applyEffect(effect: EffectTerm) {//va a venir un arreglo de efectos, cada uno con una grilla y una info de efecto, esta funcion aplica el efecto actual, que es actualizar la grilla y actualizar los objetivos logrados
    const [effectGrid, effectInfo] = effect.args;//esto va a hacer una lista con los dos argumentos grilla e informacion de efecto
    setGrid(effectGrid);//seteamos la grilla
    effectInfo.forEach((effectInfoItem: EffectInfoTerm) => {
      const { functor, args } = effectInfoItem;
      switch (functor) {
        case 'achieved': //resta los puntajes logrados a los objetivos actuales achieved([[g, 3], [~, 3]])
          setObjectives(prev => {
            const newObjectives = { ...prev };
            args[0].forEach(([block, value]: [CellContent, number]) => {
              if (newObjectives[block] === undefined) {
                return;
              }
              newObjectives[block] = Math.max(newObjectives[block]! - value, 0);
            });
            return newObjectives;
          });
          break;
        default:
          break;
      }
    });
  }

  // No muestres nada hasta que el servidor de Prolog esté listo (alternativamente, renderiza una interfaz de carga).
  if (!pengine) {
    return null;
  }

  if (grid === null) {
    return null;
  }

  const isAnimating = waiting || historyGrid !== undefined;
  const gameStarted = grid !== null && moves !== null && Object.keys(objectives).length > 0;
  
  const isVictory = gameStarted && Object.values(objectives).every(val => val! <= 0);
  const isDefeat = gameStarted && moves !== null && moves <= 0 && !isVictory;
  
  const showGameOver = !isAnimating && (isVictory || isDefeat);

  return (
    <div className={styles.game} style={{ '--num-columns': numOfColumns } as React.CSSProperties}>
      <div className={styles.header}>
        <div className={styles.movesGroup}>
          <span className={styles.movesLabel}>MOVES</span>
          <strong className={styles.movesValue}>{moves}</strong>
        </div>
        
        <div className={styles.divider} />
        
        <div className={styles.objectivesGroup}>
          {Object.entries(historyObjectives ?? objectives).map(([key, value]) => {
            const isCol = colors.includes(key);
            return (
              <div key={key} className={styles.objectiveItem} data-completed={Number(value) <= 0}>
                {isCol ? (
                  <div
                    className={styles.objectiveDot}
                    style={{ backgroundColor: colorToCss(key as CellContent) }}
                  />
                ) : key === '~' ? (
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 -960 960 960"
                    className={styles.objectiveWater}
                  >
                    <path d="M300-360q17 0 28.5-11.5T340-400q0-17-11.5-28.5T300-440q-17 0-28.5 11.5T260-400q0 17 11.5 28.5T300-360Zm60-120q17 0 28.5-11.5T400-520q0-17-11.5-28.5T360-560q-17 0-28.5 11.5T320-520q0 17 11.5 28.5T360-480Zm0 240q17 0 28.5-11.5T400-280q0-17-11.5-28.5T360-320q-17 0-28.5 11.5T320-280q0 17 11.5 28.5T360-240Zm60-120q17 0 28.5-11.5T460-400q0-17-11.5-28.5T420-440q-17 0-28.5 11.5T380-400q0 17 11.5 28.5T420-360Zm0-240q17 0 28.5-11.5T460-640q0-17-11.5-28.5T420-680q-17 0-28.5 11.5T380-640q0 17 11.5 28.5T420-600Zm60 120q17 0 28.5-11.5T520-520q0-17-11.5-28.5T480-560q-17 0-28.5 11.5T440-520q0 17 11.5 28.5T480-480Zm0 240q17 0 28.5-11.5T520-280q0-17-11.5-28.5T480-320q-17 0-28.5 11.5T440-280q0 17 11.5 28.5T480-240Zm60-120q17 0 28.5-11.5T580-400q0-17-11.5-28.5T540-440q-17 0-28.5 11.5T500-400q0 17 11.5 28.5T540-360Zm0-240q17 0 28.5-11.5T580-640q0-17-11.5-28.5T540-680q-17 0-28.5 11.5T500-640q0 17 11.5 28.5T540-600Zm60 120q17 0 28.5-11.5T640-520q0-17-11.5-28.5T600-560q-17 0-28.5 11.5T560-520q0 17 11.5 28.5T600-480Zm0 240q17 0 28.5-11.5T640-280q0-17-11.5-28.5T600-320q-17 0-28.5 11.5T560-280q0 17 11.5 28.5T600-240Zm60-120q17 0 28.5-11.5T700-400q0-17-11.5-28.5T660-440q-17 0-28.5 11.5T620-400q0 17 11.5 28.5T660-360ZM251.5-174Q160-268 160-408q0-100 79.5-217.5T480-880q161 137 240.5 254.5T800-408q0 140-91.5 234T480-80q-137 0-228.5-94ZM652-230.5Q720-301 720-408q0-73-60.5-165T480-774Q361-665 300.5-573T240-408q0 107 68 177.5T480-160q104 0 172-70.5ZM480-480Z" />
                  </svg>
                ) : (
                  <span className={styles.objectiveText}>{key}</span>
                )}
                <span className={styles.objectiveValue}>{value}</span>
              </div>
            );
          })}
        </div>
      </div>
      <Board
        grid={historyGrid ?? grid}
        numOfColumns={numOfColumns!}
        path={path} //le paso camino
        onPathChange={onPathChange} //que hacer cuando el jugdor avanza o retrocede en el camino
        onDone={onPathDone} //el jugador solto el mouse, entonces se termina el camino
        readonly={waiting || historyGrid !== undefined || showGameOver} 
      />

      {showGameOver && (
        <div className={styles.gameOverOverlay}>
          <div className={styles.gameOverModal}>
            <h1 className={isVictory ? styles.victoryText : styles.defeatText}>
              {isVictory ? '¡Victoria!' : '¡Derrota!'}
            </h1>
            <button className={styles.replayButton} onClick={() => {
              setGrid(null);
              setMoves(null);
              setObjectives({});
              initGame();
            }}>
              Jugar de nuevo
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default Game;