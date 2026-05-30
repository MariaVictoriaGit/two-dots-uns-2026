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
                  <span className={`material-symbols-outlined ${styles.objectiveWater}`}>
                    water_drop
                  </span>
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
            <div className={isVictory ? styles.victoryText : styles.defeatText}>
              {isVictory ? '¡VICTORIA!' : '¡DERROTA!'}
            </div>
            
            <button className={styles.replayButton} onClick={() => {
              setGrid(null);
              setMoves(null);
              setObjectives({});
              initGame();
            }}>
              JUGAR DE NUEVO
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default Game;