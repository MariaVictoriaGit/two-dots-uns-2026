import styles from './MainMenu.module.css';

interface MainMenuProps {
  onStart: () => void;
  onSelectLevel: () => void;
}

/**
 * Pantalla del menú principal.
 * Muestra el título del juego y dos botones: Iniciar y Elegir Nivel.
 */
export default function MainMenu({ onStart, onSelectLevel }: MainMenuProps) {
  return (
    <div className={styles.container}>
      <div className={styles.menu}>
        <h1 className={styles.title}>
          TWO<span>DOTS</span>
        </h1>
        <div className={styles.buttons}>
          <button className={styles.primaryButton} onClick={onStart}>INICIAR</button>
          <button className={styles.secondaryButton} onClick={onSelectLevel}>ELEGIR NIVEL</button>
        </div>
      </div>
    </div>
  );
}
