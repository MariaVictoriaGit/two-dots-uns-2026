import styles from './Game.module.css';
import { PowerUp, PowerUpId } from './model';

interface PowerUpBarProps {
  powerUps: PowerUp[];
  activePowerUp: PowerUpId | null;
  onToggle: (id: PowerUpId) => void;
  disabled: boolean;
}

/**
 * Barra de power-ups en la parte inferior del tablero.
 * Muestra los botones de cada power-up con su contador de usos disponibles.
 */
export default function PowerUpBar({ powerUps, activePowerUp, onToggle, disabled }: PowerUpBarProps) {
  return (
    <div className={styles.powerUpContainer}>
      {powerUps.map(pu => (
        <button
          key={pu.id}
          className={`${styles.powerUpBtn} ${activePowerUp === pu.id ? styles.powerUpBtnActive : ''}`}
          onClick={() => onToggle(pu.id)}
          disabled={pu.count === 0 || disabled}
          title={pu.name}
        >
          <img src={pu.image} alt={pu.name} className={styles.powerUpIcon} />
          <span className={styles.powerUpBadge}>{pu.count}</span>
        </button>
      ))}
    </div>
  );
}
