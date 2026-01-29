PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- =====================================================
-- SEED CONSOLIDADO (seed.sql + migraciones 002..003 + starter_deck)
-- Deja la BD lista para jugar (admin + cartas + logros + reglas + enemigos + starter deck)
-- =====================================================

-- -------------------------
-- Usuario admin + progreso
-- -------------------------
INSERT OR IGNORE INTO usuario (id_usuario, nombre_usuario, contrasena, rol)
VALUES (1, 'admin', 'admin', 'ADMIN');

INSERT OR IGNORE INTO progreso_usuario (id_usuario, nivel, experiencia, fecha_ultima_partida)
VALUES (1, 1, 0, NULL);

-- -------------------------
-- Enemigos base (5)
-- -------------------------
INSERT OR IGNORE INTO enemigo (id_enemigo, nombre, descripcion, vida_base, dano_base, recompensa_xp, disponible, tipo, imagen) VALUES
(1, 'Goblin Recluta',  'Un goblin débil pero molesto.',         18, 4,  6,  1, 'Normal', ''),
(2, 'Goblin Lancero',  'Ataca con lanza desde media distancia.',22, 5,  8,  1, 'Normal', ''),
(3, 'Goblin Saqueador','Golpea fuerte y roba recursos.',        26, 6, 10,  1, 'Normal', ''),
(4, 'Chamán Goblin',   'Usa trucos y maldiciones.',             24, 5, 12,  1, 'Élite',  ''),
(5, 'Jefe Goblin',     'Más duro y peligroso.',                 40, 8, 20,  1, 'Jefe',   '');

-- -------------------------
-- Cartas + logros + reglas (según migración 003)
-- Limpieza (para idempotencia)
-- -------------------------
DELETE FROM usuario_logro;
DELETE FROM usuario_carta;
DELETE FROM carta_desbloqueo;

DELETE FROM logro;
DELETE FROM carta;

-- Reset autoincrement (opcional)
DELETE FROM sqlite_sequence WHERE name IN ('carta','logro');

-- 25 CARTAS
INSERT OR IGNORE INTO carta (id_carta, nombre, descripcion, tipo, coste_energia, valor_base, rareza, disponible, imagen, fondo) VALUES
(1,  'Corte Rápido',           'Inflige daño directo.',                          'ATAQUE',    1,  6, 'COMUN',      1, '', ''),
(2,  'Estocada Precisa',       'Ataque eficiente contra un solo objetivo.',      'ATAQUE',    1,  5, 'COMUN',      1, '', ''),
(3,  'Golpe Firme',            'Inflige un golpe pesado.',                       'ATAQUE',    2, 10, 'COMUN',      1, '', ''),
(4,  'Guardia',                'Ganas bloqueo.',                                 'DEFENSA',   1,  5, 'COMUN',      1, '', ''),
(5,  'Bloqueo Total',          'Ganas mucho bloqueo.',                           'DEFENSA',   2, 10, 'COMUN',      1, '', ''),
(6,  'Respirar',               'Recuperas vida.',                                'HABILIDAD', 1,  3, 'COMUN',      1, '', ''),
(7,  'Paso Atrás',             'Te preparas para el siguiente golpe (bloqueo).', 'DEFENSA',   1,  7, 'RARO',      1, '', ''),
(8,  'Doble Corte',            'Ataque doble simplificado (daño directo).',      'ATAQUE',    1,  8, 'RARO',      1, '', ''),
(9,  'Escudo Ligero',          'Bloqueo eficiente de bajo coste.',               'DEFENSA',   1,  7, 'RARO',      1, '', ''),
(10, 'Concentración',          'Obtienes +1 energía.',                            'HABILIDAD', 1,  1, 'RARO',      1, '', ''),
(11, 'Furia Controlada',       'Inflige daño alto.',                              'ATAQUE',    2, 14, 'EPICO',     1, '', ''),
(12, 'Curación de Campamento', 'Recuperas vida con calma.',                       'HABILIDAD', 2,  8, 'RARO',      1, '', ''),
(13, 'Golpe Aplastante',       'Ataque contundente.',                             'ATAQUE',    2, 16, 'EPICO',     1, '', ''),
(14, 'Muro Improvisado',       'Bloqueo elevado.',                                'DEFENSA',   2, 15, 'EPICO',     1, '', ''),
(15, 'Impulso',                'Ganas +2 energía.',                               'HABILIDAD', 1,  2, 'EPICO',     1, '', ''),
(16, 'Corte Giratorio',        'Daño sólido y constante.',                        'ATAQUE',    1, 11, 'RARO',      1, '', ''),
(17, 'Barrera',                'Bloqueo moderado y estable.',                     'DEFENSA',   1,  9, 'RARO',      1, '', ''),
(18, 'Veredicto del Castillo', 'Daño masivo tras una gran victoria.',             'ATAQUE',    3, 24, 'LEGENDARIO',1, '', ''),
(19, 'Bolsa del Tesorero',     'Aseguras recursos (MVP: +energía).',              'HABILIDAD', 1,  1, 'EPICO',     1, '', ''),
(20, 'Manos Ligeras',          'Aprovechas el gasto (MVP: curación).',            'HABILIDAD', 1,  6, 'EPICO',     1, '', ''),
(21, 'Marcha Real',            'Resistes la travesía (bloqueo).',                 'DEFENSA',   2, 18, 'EPICO',     1, '', ''),
(22, 'Ejecución del Monarca',  'Golpe final devastador.',                         'ATAQUE',    3, 26, 'LEGENDARIO',1, '', ''),
(23, 'Suerte del Aventurero',  'La fortuna te sonríe (MVP: +energía).',           'HABILIDAD', 1,  1, 'RARO',      1, '', ''),
(24, 'Danza Intocable',        'Bloqueo perfecto por anticipación.',              'DEFENSA',   1, 12, 'EPICO',     1, '', ''),
(25, 'Retirada Estratégica',   'Aprendes del fracaso (curación ligera).',         'HABILIDAD', 1,  4, 'RARO',      1, '', '');

-- 8 LOGROS
INSERT OR IGNORE INTO logro (id_logro, nombre, descripcion, condicion, disponible) VALUES
(1, 'Cabeza de Cartel',         'Derrota al jefe del primer mapa por primera vez.',           'KILL_BOSS_1',        1),
(2, 'Amasador de Oro',          'Acumula 500 de oro en una misma run.',                       'GOLD_500',           1),
(3, 'Manirroto',                'Gasta 700 de oro en una misma run.',                         'SPEND_700',          1),
(4, 'A las Puertas del Castillo','Llega al Castillo.',                                       'REACH_CASTLE',       1),
(5, 'Caída del Monarca',        'Derrota al boss del Castillo.',                              'KILL_CASTLE_BOSS',   1),
(6, 'Veterano de los Sucesos',  'Completa 30 eventos acumulados.',                            'EVENTS_30',          1),
(7, 'Intocable',                'Gana un combate sin recibir daño.',                          'NO_HIT_BATTLE',      1),
(8, 'Sin Rumbo',                'No llegues al jefe del primer mapa (run fallida temprano).', 'FAIL_BEFORE_BOSS_1', 1);

-- Reglas de desbloqueo
-- BASE: 1..12
INSERT OR IGNORE INTO carta_desbloqueo(id_carta, tipo, valor)
SELECT id_carta, 'BASE', 0 FROM carta WHERE id_carta BETWEEN 1 AND 12;

-- NIVEL: 13..17
INSERT OR IGNORE INTO carta_desbloqueo(id_carta, tipo, valor) VALUES
(13, 'NIVEL', 2),
(14, 'NIVEL', 3),
(15, 'NIVEL', 4),
(16, 'NIVEL', 5),
(17, 'NIVEL', 6);

-- LOGRO: 18..25 (mapeo 1:1 con logros 1..8)
INSERT OR IGNORE INTO carta_desbloqueo(id_carta, tipo, valor) VALUES
(18, 'LOGRO', 1),
(19, 'LOGRO', 2),
(20, 'LOGRO', 3),
(21, 'LOGRO', 4),
(22, 'LOGRO', 5),
(23, 'LOGRO', 6),
(24, 'LOGRO', 7),
(25, 'LOGRO', 8);

-- Usuario_logro (crear filas para el admin)
INSERT OR IGNORE INTO usuario_logro (id_usuario, id_logro, obtenido, fecha_obtencion)
SELECT 1, id_logro, 0, NULL FROM logro;

-- Usuario_carta (crear filas para el admin: todas bloqueadas)
INSERT OR IGNORE INTO usuario_carta (id_usuario, id_carta, desbloqueada)
SELECT 1, id_carta, 0 FROM carta;

-- Desbloquear BASE para el admin
UPDATE usuario_carta
SET desbloqueada = 1
WHERE id_usuario = 1
  AND id_carta IN (SELECT id_carta FROM carta_desbloqueo WHERE tipo='BASE');

-- -------------------------
-- Starter deck (mazo inicial) para runs
-- -------------------------
DELETE FROM starter_deck;
INSERT INTO starter_deck(card_id, copies) VALUES (1, 5);
INSERT INTO starter_deck(card_id, copies) VALUES (4, 4);
INSERT INTO starter_deck(card_id, copies) VALUES (6, 1);

COMMIT;

-- =====================================================
-- Checks rápidos (opcional, para DB Browser)
-- SELECT * FROM starter_deck;
-- SELECT COUNT(*) AS n FROM carta;
-- SELECT COUNT(*) AS n FROM enemigo;
-- =====================================================
