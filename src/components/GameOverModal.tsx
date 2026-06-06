import styles from './Game.module.css';

interface GameOverModalProps {
  isPaused: boolean;
  isVictory: boolean;
  isDefeat: boolean;
  isMuted: boolean;
  onResume: () => void;
  onToggleMute: () => void;
  onNextLevel: () => void;
  onRetry: () => void;
  onMainMenu: () => void;
}

/**
 * Modal que se muestra al pausar, ganar o perder el nivel.
 * Incluye botones dinámicos según el estado del juego.
 */
export default function GameOverModal({
  isPaused,
  isVictory,
  isDefeat,
  isMuted,
  onResume,
  onToggleMute,
  onNextLevel,
  onRetry,
  onMainMenu,
}: GameOverModalProps) {
  return (
    <div className={styles.gameOverOverlay}>
      <div className={styles.gameOverModal}>

        {/* Título Dinámico */}
        {isPaused ? (
          <div className={styles.pauseText}>PAUSA</div>
        ) : isVictory ? (
          <div className={styles.victoryText}>¡VICTORIA!</div>
        ) : (
          <div className={styles.defeatText}>¡DERROTA!</div>
        )}

        {/* Botones Dinámicos */}
        <div className={styles.modalButtons}>

          {/* BOTONES DE PAUSA */}
          {isPaused && (
            <>
              <button className={styles.primaryButton} onClick={onResume}>REANUDAR</button>
              <button className={styles.secondaryButton} onClick={onToggleMute}>
                {isMuted ? '🎵 ACTIVAR SONIDO' : '🔇 MUTEAR SONIDO'}
              </button>
            </>
          )}

          {/* BOTONES DE VICTORIA */}
          {isVictory && !isPaused && (
            <button className={styles.primaryButton} onClick={onNextLevel}>SIGUIENTE NIVEL</button>
          )}

          {/* BOTONES DE DERROTA */}
          {isDefeat && !isPaused && (
            <button className={styles.primaryButton} onClick={onRetry}>VOLVER A INTENTAR</button>
          )}

          {/* BOTÓN UNIVERSAL: VOLVER AL MENÚ */}
          <button className={styles.secondaryButton} onClick={onMainMenu}>
            MENÚ PRINCIPAL
          </button>

        </div>
      </div>
    </div>
  );
}
