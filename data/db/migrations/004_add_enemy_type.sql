PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- 1) Añadir columna tipo si no existe
ALTER TABLE enemigo ADD COLUMN tipo TEXT NOT NULL DEFAULT 'NORMAL';

-- 2) (Opcional) índice para consultas por tipo
CREATE INDEX IF NOT EXISTS idx_enemigo_tipo ON enemigo(tipo);

COMMIT;
