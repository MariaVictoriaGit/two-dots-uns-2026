import { useEffect, useRef } from 'react';

/**
 * Hook personalizado para manejar la reproducción de audio.
 * Crea un objeto Audio una sola vez y controla play/pause según `shouldPlay`.
 * @param src - Ruta al archivo de audio.
 * @param shouldPlay - Si es true, reproduce; si es false, pausa.
 */
export function useAudio(src: string, shouldPlay: boolean): void {
  const audioRef = useRef<HTMLAudioElement | null>(null);

  // Crear el objeto Audio una sola vez
  useEffect(() => {
    const audio = new Audio(src);
    audio.loop = true;
    audioRef.current = audio;
    return () => {
      audio.pause();
      audio.src = '';
    };
  }, [src]);

  // Controlar reproducción según shouldPlay
  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;
    if (shouldPlay) {
      audio.play().catch(() => {});
    } else {
      audio.pause();
    }
  }, [shouldPlay]);
}
