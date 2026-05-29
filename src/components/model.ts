import { PrologTerm } from '../services/PengineClient';

export const colors = ["r", "c", "g", "p", "y", "b"]; // aca se puede cambiar los colores

export function colorToCss(color: typeof colors[number]): string {
    switch (color) {
        case "r": return "#e84d60";
        case "c": return "#7bbdc9";
        case "g": return "#2cac75";
        case "p": return "#a94ede";
        case "y": return "#fecd6c";
        case "b": return "#000000";
        default: return "white";
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
