PRAGMA foreign_keys = ON;

-- =========================
-- USUARIO ADMIN + PROGRESO
-- =========================
INSERT OR IGNORE INTO usuario (id_usuario, nombre_usuario, contrasena, rol)
VALUES (1, 'admin', 'admin', 'ADMIN');

INSERT OR IGNORE INTO progreso_usuario (id_usuario, nivel, experiencia, fecha_ultima_partida)
VALUES (1, 1, 0, NULL);

-- =========================
-- CARTAS (10 mínimas)
-- tipo: ATAQUE / DEFENSA / HABILIDAD
-- rareza: COMUN / RARO / EPICO / LEGENDARIO
-- =========================
INSERT OR IGNORE INTO carta (id_carta, nombre, descripcion, tipo, coste_energia, valor_base, rareza, disponible) VALUES
(1, 'Corte Rápido', 'Inflige daño directo.', 'ATAQUE', 1, 6, 'COMUN', 1),
(2, 'Golpe Firme', 'Inflige daño directo.', 'ATAQUE', 2, 10, 'COMUN', 1),
(3, 'Estocada', 'Ataque ligero y eficiente.', 'ATAQUE', 1, 5, 'COMUN', 1),
(4, 'Guardia', 'Ganas bloqueo.', 'DEFENSA', 1, 5, 'COMUN', 1),
(5, 'Bloqueo Total', 'Ganas más bloqueo.', 'DEFENSA', 2, 10, 'COMUN', 1),
(6, 'Respirar', 'Recupera un poco de vida.', 'HABILIDAD', 1, 3, 'COMUN', 1),
(7, 'Concentración', 'Ganas energía extra el próximo turno (MVP: energía +1 ahora).', 'HABILIDAD', 1, 1, 'RARO', 1),
(8, 'Doble Corte', 'Inflige daño moderado (MVP: daño directo).', 'ATAQUE', 1, 8, 'RARO', 1),
(9, 'Escudo Ligero', 'Bloqueo eficiente.', 'DEFENSA', 1, 7, 'RARO', 1),
(10, 'Furia', 'Aumenta el daño (MVP: daño directo alto).', 'ATAQUE', 2, 14, 'EPICO', 1);

-- =========================
-- ENEMIGOS (5 mínimos)
-- =========================
INSERT OR IGNORE INTO enemigo (id_enemigo, nombre, descripcion, vida_base, dano_base, recompensa_xp, disponible) VALUES
(1, 'Goblin Recluta', 'Un goblin débil pero molesto.', 18, 4, 6, 1),
(2, 'Goblin Lancero', 'Ataca con lanza desde media distancia.', 22, 5, 8, 1),
(3, 'Goblin Saqueador', 'Golpea fuerte y roba recursos.', 26, 6, 10, 1),
(4, 'Chamán Goblin', 'Usa trucos y maldiciones.', 24, 5, 12, 1),
(5, 'Jefe Goblin', 'Más duro y peligroso.', 40, 8, 20, 1);

-- =========================
-- LOGROS (3 mínimos)
-- =========================
INSERT OR IGNORE INTO logro (id_logro, nombre, descripcion, condicion, disponible) VALUES
(1, 'Primera Sangre', 'Derrota a tu primer enemigo.', 'WIN_1', 1),
(2, 'Aprendiz', 'Gana 50 de experiencia acumulada.', 'XP_50', 1),
(3, 'Veterano', 'Gana 200 de experiencia acumulada.', 'XP_200', 1);

-- =========================
-- DESBLOQUEAR CARTAS INICIALES AL ADMIN
-- =========================
INSERT OR IGNORE INTO usuario_carta (id_usuario, id_carta, desbloqueada)
SELECT 1, id_carta, 1 FROM carta WHERE id_carta BETWEEN 1 AND 5;

-- =========================
-- LOGROS (no obtenidos aún)
-- =========================
IN
