import React from 'react';
import { CellContent, colorToImage } from "./model";
import styles from "./Cell.module.css";


interface CellProps {
    value: CellContent[];
    onMouseEnter: () => void;
    onMouseDown: () => void;
    waterNeighbors?: {
        top: boolean;
        right: boolean;
        bottom: boolean;
        left: boolean;
    };
}

function Cell({ value, onMouseEnter, onMouseDown, waterNeighbors }: CellProps) {
    const { top = false, right = false, bottom = false, left = false } = waterNeighbors || {};

    const content = value.map((cellContent, i) => {
        switch (cellContent) {
            case "~": {
                const style = {
                    "--tl-radius": (!top && !left) ? "50%" : "0px",
                    "--tr-radius": (!top && !right) ? "50%" : "0px",
                    "--br-radius": (!bottom && !right) ? "50%" : "0px",
                    "--bl-radius": (!bottom && !left) ? "50%" : "0px",
                } as React.CSSProperties;
                return <div className={styles.water} style={style} key="water" />;
            }
            case "-": return <div className={styles.empty} key="empty" />;
            default: return (
                <button
                    className={styles.color}
                    onMouseDown={onMouseDown}
                    onMouseEnter={onMouseEnter}
                    key={cellContent}
                >
                    <img 
                        src={colorToImage(cellContent)} 
                        alt={cellContent} 
                        draggable={false}
                        style={{ width: '100%', height: '100%', objectFit: 'cover', userSelect: 'none', pointerEvents: 'none' }} 
                    />
                </button>
            );
        }
    });

    return (
        <div className={styles.cell}>
            {content}
        </div>
    );
}

export default Cell;