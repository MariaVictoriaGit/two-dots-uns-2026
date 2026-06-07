import React, { useEffect, useRef } from 'react';
import styles from './LevelSelector.module.css';

interface LevelSelectorProps {
  maxUnlockedLevel: number;
  onSelectLevel: (levelId: number) => void;
  onBackToMenu?: () => void;
}

interface Level {
    id: number;
    name: string;
    unlocked?: boolean; 
    score?: number;
}
const TOTAL_MAP_LEVELS = 50;

// Generamos la lista de niveles dinámicamente 
const LEVELS_DATA: Level[] = Array.from({ length: TOTAL_MAP_LEVELS }, (_, index) => {
  const levelId = index + 1;
  return { 
    id: levelId, 
    name: `Nivel ${levelId}` 
  };
});


export default function LevelSelector({ maxUnlockedLevel, onSelectLevel, onBackToMenu }: LevelSelectorProps) {
  const activeLevelRef = useRef<HTMLButtonElement>(null);

  // EFECTO DE AUTO-SCROLL: Se ejecuta una sola vez cuando se abre el menú
   useEffect(() => {
       if (activeLevelRef.current) {
       // scrollIntoView mueve la pantalla hasta el elemento
       activeLevelRef.current.scrollIntoView({
           behavior: 'auto', // 'smooth' para que se vea el movimiento, 'auto' para instantáneo
           block: 'center',  // Centra el nivel en la pantalla verticalmente
       });
       }
   }, []);
    
   return (
    <div className={styles.menuContainer}>
      <div className={styles.topBar}>
        {onBackToMenu && (
          <button className={styles.backButton} onClick={onBackToMenu}>
            <img src="/lib/imagenes/volver.png" alt="Volver" className={styles.backIcon} /> Volver
          </button>
        )}
        <header className={styles.header}>
          <h1 className={styles.title}>
            TWO<span>DOTS</span>
          </h1>
          <p className={styles.subtitle}>Selecciona un nivel para comenzar</p>
        </header>
      </div>

      {/* El Mapa de Niveles Colectivo */}
     <div className={styles.scrollArea}>
        <div className={styles.mapPath}>
          {LEVELS_DATA.map((lvl, index) => {
            const alignmentClass = index % 2 === 0 ? styles.leftAlign : styles.rightAlign;
            const isUnlocked = lvl.id <= maxUnlockedLevel;
            const isCurrentLevel = lvl.id === maxUnlockedLevel;

            return (
              <div key={lvl.id} className={`${styles.levelNodeWrapper} ${alignmentClass}`}>
                <button
                  ref={isCurrentLevel ? activeLevelRef : null}
                  className={styles.levelButton}
                  disabled={!isUnlocked}
                  onClick={() => onSelectLevel(lvl.id)}
                  data-unlocked={isUnlocked}
                  style={isCurrentLevel ? { outline: '4px solid white', outlineOffset: '4px' } : {}}
                >
                  {isUnlocked ? (
                    <span className={styles.levelNumber}>{lvl.id}</span>
                  ) : (
                    <span className={styles.lockedText}>Bloqueado</span>
                  )}
                </button>
                
                {/* Linea conectora */}
                {index < LEVELS_DATA.length - 1 && (
                  <div className={`${styles.connectorLine} ${index % 2 === 0 ? styles.lineRight : styles.lineLeft}`} />
                )}
              </div>
            );
          })}
        </div>
      </div>
      
    </div>
  );
}