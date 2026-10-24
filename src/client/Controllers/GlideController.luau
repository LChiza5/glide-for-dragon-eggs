--!strict
-- Dueño: Isaac.
--
-- Pendiente, Etapa 1:
--   1. Al saltar desde el acantilado, abrir las alas: menos gravedad y avance hacia adelante.
--   2. Más WingPower (StatsController.get("WingPower")) = planeo más largo.
--   3. Cámara que siga el vuelo y marcador de distancia en pantalla (coordinar con José).
--   4. Al tocar el suelo, avisar con el RemoteEvent "GlideLanded"; el servidor mide y paga.

local GlideController = {}

function GlideController.start() end

return table.freeze(GlideController)
