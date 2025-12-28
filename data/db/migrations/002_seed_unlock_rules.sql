PRAGMA foreign_keys = ON;

-- BASE: desbloqueadas de serie
INSERT OR IGNORE INTO carta_desbloqueo(id_carta, tipo, valor) VALUES
(1,'BASE',0),(2,'BASE',0),(3,'BASE',0),(4,'BASE',0),(5,'BASE',0);

-- NIVEL: se desbloquean al llegar a nivel X
INSERT OR IGNORE INTO carta_desbloqueo(id_carta, tipo, valor) VALUES
(6,'NIVEL',2),
(7,'NIVEL',3),
(8,'NIVEL',4);

-- LOGRO: se desbloquean al conseguir un logro (valor = id_logro)
INSERT OR IGNORE INTO carta_desbloqueo(id_carta, tipo, valor) VALUES
(9,'LOGRO',1),
(10,'LOGRO',2);
