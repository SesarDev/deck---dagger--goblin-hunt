PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- 1) Limpiar tablas dependientes (orden importante por FK)
DELETE FROM usuario_logro;
DELETE FROM usuario_carta;
DELETE FROM carta_desbloqueo;

DELETE FROM logro;
DELETE FROM carta;

-- Reset autoincrement (opcional, pero útil si quieres IDs 1..N consistentes)
DELETE FROM sqlite_sequence WHERE name IN ('carta','logro');

-- 2) Insertar 25 CARTAS (ids fijos para reglas)
-- Campos: id_carta, nombre, descripcion, tipo, coste_energia, valor_base, rareza, disponible
INSERT OR IGNORE INTO carta (id_carta, nombre, descripcion, tipo, coste_energia, valor_base, rareza, disponible) VALUES
-- ===== 12 BASE (desbloqueadas de serie) =====
(1,  'Corte Rápido',           'Inflige daño directo.',                          'ATAQUE',   1,  6, 'COMUN',      1),
(2,  'Estocada Precisa',       'Ataque eficiente contra un solo objetivo.',      'ATAQUE',   1,  5, 'COMUN',      1),
(3,  'Golpe Firme',            'Inflige un golpe pesado.',                       'ATAQUE',   2, 10, 'COMUN',      1),
(4,  'Guardia',                'Ganas bloqueo.',                                 'DEFENSA',  1,  5, 'COMUN',      1),
(5,  'Bloqueo Total',          'Ganas mucho bloqueo.',                           'DEFENSA',  2, 10, 'COMUN',      1),
(6,  'Respirar',               'Recuperas vida.',                                'HABILIDAD',1,  3, 'COMUN',      1),
(7,  'Paso Atrás',             'Te preparas para el siguiente golpe (bloqueo).', 'DEFENSA',  1,  7, 'RARO',      1),
(8,  'Doble Corte',            'Ataque doble simplificado (daño directo).',      'ATAQUE',   1,  8, 'RARO',      1),
(9,  'Escudo Ligero',          'Bloqueo eficiente de bajo coste.',               'DEFENSA',  1,  7, 'RARO',      1),
(10, 'Concentración',          'Obtienes +1 energía.',                            'HABILIDAD',1,  1, 'RARO',      1),
(11, 'Furia Controlada',       'Inflige daño alto.',                              'ATAQUE',   2, 14, 'EPICO',     1),
(12, 'Curación de Campamento', 'Recuperas vida con calma.',                       'HABILIDAD',2,  8, 'RARO',      1),

-- ===== 5 POR NIVEL (se desbloquean al subir) =====
(13, 'Golpe Aplastante',       'Ataque contundente.',                             'ATAQUE',   2, 16, 'EPICO',     1),
(14, 'Muro Improvisado',       'Bloqueo elevado.',                                'DEFENSA',  2, 15, 'EPICO',     1),
(15, 'Impulso',                'Ganas +2 energía.',                               'HABILIDAD',1,  2, 'EPICO',     1),
(16, 'Corte Giratorio',        'Daño sólido y constante.',                        'ATAQUE',   1, 11, 'RARO',      1),
(17, 'Barrera',                'Bloqueo moderado y estable.',                     'DEFENSA',  1,  9, 'RARO',      1),

-- ===== 8 POR LOGROS (una por cada logro) =====
(18, 'Veredicto del Castillo', 'Daño masivo tras una gran victoria.',             'ATAQUE',   3, 24, 'LEGENDARIO',1),
(19, 'Bolsa del Tesorero',     'Aseguras recursos (MVP: +energía).',              'HABILIDAD',1,  1, 'EPICO',     1),
(20, 'Manos Ligeras',          'Aprovechas el gasto (MVP: curación).',            'HABILIDAD',1,  6, 'EPICO',     1),
(21, 'Marcha Real',            'Resistes la travesía (bloqueo).',                 'DEFENSA',  2, 18, 'EPICO',     1),
(22, 'Ejecución del Monarca',  'Golpe final devastador.',                         'ATAQUE',   3, 26, 'LEGENDARIO',1),
(23, 'Suerte del Aventurero',  'La fortuna te sonríe (MVP: +energía).',           'HABILIDAD',1,  1, 'RARO',      1),
(24, 'Danza Intocable',        'Bloqueo perfecto por anticipación.',              'DEFENSA',  1, 12, 'EPICO',     1),
(25, 'Retirada Estratégica',   'Aprendes del fracaso (curación ligera).',         'HABILIDAD',1,  4, 'RARO',      1);

-- 3) Insertar 8 LOGROS (ids fijos)
INSERT OR IGNORE INTO logro (id_logro, nombre, descripcion, condicion, disponible) VALUES
(1, 'Cabeza de Cartel',        'Derrota al jefe del primer mapa por primera vez.',          'KILL_BOSS_1',        1),
(2, 'Amasador de Oro',         'Acumula 500 de oro en una misma run.',                      'GOLD_500',           1),
(3, 'Manirroto',               'Gasta 700 de oro en una misma run.',                        'SPEND_700',          1),
(4, 'A las Puertas del Castillo','Llega al Castillo.',                                      'REACH_CASTLE',       1),
(5, 'Caída del Monarca',       'Derrota al boss del Castillo.',                              'KILL_CASTLE_BOSS',   1),
(6, 'Veterano de los Sucesos', 'Completa 30 eventos acumulados.',                            'EVENTS_30',          1),
(7, 'Intocable',               'Gana un combate sin recibir daño.',                          'NO_HIT_BATTLE',      1),
(8, 'Sin Rumbo',               'No llegues al jefe del primer mapa (run fallida temprano).','FAIL_BEFORE_BOSS_1', 1);

-- 4) Reglas de desbloqueo: 12 BASE, 5 NIVEL, 8 LOGRO
-- BASE: 1..12
INSERT OR IGNORE INTO carta_desbloqueo(id_carta, tipo, valor)
SELECT id_carta, 'BASE', 0 FROM carta WHERE id_carta BETWEEN 1 AND 12;

-- NIVEL: 13..17 (niveles recomendados: 2..6)
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

-- 5) Reconstruir estado del usuario admin (id_usuario=1)
-- Asegurar progreso (si no existiera)
INSERT OR IGNORE INTO progreso_usuario (id_usuario, nivel, experiencia, fecha_ultima_partida)
VALUES (1, 1, 0, NULL);

-- Crear filas de usuario_logro para el usuario (todos no obtenidos)
INSERT OR IGNORE INTO usuario_logro (id_usuario, id_logro, obtenido, fecha_obtencion)
SELECT 1, id_logro, 0, NULL FROM logro;

-- Crear filas de usuario_carta para el usuario (todas bloqueadas inicialmente)
INSERT OR IGNORE INTO usuario_carta (id_usuario, id_carta, desbloqueada)
SELECT 1, id_carta, 0 FROM carta;

-- Desbloquear BASE para el usuario
UPDATE usuario_carta
SET desbloqueada = 1
WHERE id_usuario = 1
  AND id_carta IN (SELECT id_carta FROM carta_desbloqueo WHERE tipo='BASE');

COMMIT;
