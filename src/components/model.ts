import { PrologTerm } from '../services/PengineClient';

export const colors = ["r", "c", "g", "p", "y", "b"]; // aca se puede cambiar los colores

export function colorToCss(color: typeof colors[number]): string {
    switch (color) {
        case "r": return "#e84d60";
        case "c": return "#656ddd";
        case "g": return "#2cac75";
        case "p": return "#a94ede";
        case "y": return "#fecd6c";
        case "b": return "#000000";
        default: return "white";
    }
}

export function colorToImage(color: typeof colors[number]): string {
    switch (color) {
        case "r": return "/lib/imagenes/rojo.png";
        case "c": return "/lib/imagenes/azul.png";
        case "g": return "/lib/imagenes/verde.png";
        case "p": return "/lib/imagenes/violeta.png";
        case "y": return "/lib/imagenes/amarillo.png";
        case "b": return "/lib/imagenes/bomba.png";
        default: return "";
    }
}

export type CellContent = (typeof colors[number]) | "-" | "~";

export type Grid = CellContent[][];

export type Objectives = {
  [key in CellContent]?: number; 
}

export type EffectTerm = PrologTerm & {
  functor: "effect";
  args: [Grid, EffectInfoTerm[]];
}

export type EffectInfoTerm = AchievedTerm | PrologTerm;

export type AchievedTerm = PrologTerm & {
  functor: "achieved";
  args: [CellContent, number][];
}

export type PowerUpId = 'borrar_color' | 'borrador' | 'mezclar' | 'cruz';

export interface PowerUp {
  id: PowerUpId;
  name: string;
  image: string;
  count: number;
}
