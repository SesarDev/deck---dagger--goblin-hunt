PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- Añadir columna 'imagen' (ruta a recurso/archivo)
-- Recomendación: TEXT con DEFAULT para no romper inserts existentes
ALTER TABLE enemigo ADD COLUMN imagen TEXT NOT NULL DEFAULT '';

-- (Opcional) índice si vas a filtrar/buscar por imagen (normalmente no hace falta)
-- CREATE INDEX IF NOT EXISTS idx_enemigo_imagen ON enemigo(imagen);

COMMIT;
