PRAGMA foreign_keys = ON;

-- Reglas de desbloqueo por carta
CREATE TABLE IF NOT EXISTS carta_desbloqueo (
    id_carta INTEGER NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('BASE','NIVEL','LOGRO')),
    valor INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (id_carta, tipo, valor),
    FOREIGN KEY (id_carta) REFERENCES carta(id_carta)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_carta_desbloqueo_tipo_valor
ON carta_desbloqueo(tipo, valor);
