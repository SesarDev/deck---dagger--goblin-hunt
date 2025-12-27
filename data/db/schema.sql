PRAGMA foreign_keys = ON;

-- =========================
-- TABLAS PRINCIPALES
-- =========================

CREATE TABLE IF NOT EXISTS usuario (
    id_usuario      INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_usuario  TEXT NOT NULL UNIQUE,
    contrasena      TEXT NOT NULL,
    rol             TEXT NOT NULL DEFAULT 'PLAYER'
        CHECK (rol IN ('PLAYER','ADMIN'))
);

CREATE TABLE IF NOT EXISTS progreso_usuario (
    id_progreso         INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario          INTEGER NOT NULL UNIQUE,
    nivel               INTEGER NOT NULL DEFAULT 1 CHECK (nivel >= 1),
    experiencia         INTEGER NOT NULL DEFAULT 0 CHECK (experiencia >= 0),
    fecha_ultima_partida TEXT,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS carta (
    id_carta        INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre          TEXT NOT NULL UNIQUE,
    descripcion     TEXT NOT NULL DEFAULT '',
    tipo            TEXT NOT NULL DEFAULT 'ATAQUE'
        CHECK (tipo IN ('ATAQUE','DEFENSA','HABILIDAD')),
    coste_energia   INTEGER NOT NULL DEFAULT 1 CHECK (coste_energia >= 0),
    valor_base      INTEGER NOT NULL DEFAULT 0 CHECK (valor_base >= 0),
    rareza          TEXT NOT NULL DEFAULT 'COMUN'
        CHECK (rareza IN ('COMUN','RARO','EPICO','LEGENDARIO')),
    disponible      INTEGER NOT NULL DEFAULT 1 CHECK (disponible IN (0,1))
);

CREATE TABLE IF NOT EXISTS enemigo (
    id_enemigo      INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre          TEXT NOT NULL UNIQUE,
    descripcion     TEXT NOT NULL DEFAULT '',
    vida_base       INTEGER NOT NULL DEFAULT 10 CHECK (vida_base > 0),
    dano_base       INTEGER NOT NULL DEFAULT 1 CHECK (dano_base >= 0),
    recompensa_xp   INTEGER NOT NULL DEFAULT 5 CHECK (recompensa_xp >= 0),
    disponible      INTEGER NOT NULL DEFAULT 1 CHECK (disponible IN (0,1))
);

CREATE TABLE IF NOT EXISTS logro (
    id_logro        INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre          TEXT NOT NULL UNIQUE,
    descripcion     TEXT NOT NULL DEFAULT '',
    condicion       TEXT NOT NULL DEFAULT '',
    disponible      INTEGER NOT NULL DEFAULT 1 CHECK (disponible IN (0,1))
);

-- =========================
-- TABLAS PUENTE (N:M)
-- =========================

CREATE TABLE IF NOT EXISTS usuario_carta (
    id_usuario  INTEGER NOT NULL,
    id_carta    INTEGER NOT NULL,
    desbloqueada INTEGER NOT NULL DEFAULT 0 CHECK (desbloqueada IN (0,1)),
    PRIMARY KEY (id_usuario, id_carta),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (id_carta) REFERENCES carta(id_carta)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS usuario_logro (
    id_usuario  INTEGER NOT NULL,
    id_logro    INTEGER NOT NULL,
    obtenido    INTEGER NOT NULL DEFAULT 0 CHECK (obtenido IN (0,1)),
    fecha_obtencion TEXT,
    PRIMARY KEY (id_usuario, id_logro),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (id_logro) REFERENCES logro(id_logro)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =========================
-- ÍNDICES RECOMENDADOS
-- =========================

CREATE INDEX IF NOT EXISTS idx_progreso_usuario_id_usuario ON progreso_usuario(id_usuario);
CREATE INDEX IF NOT EXISTS idx_usuario_carta_id_carta ON usuario_carta(id_carta);
CREATE INDEX IF NOT EXISTS idx_usuario_logro_id_logro ON usuario_logro(id_logro);
