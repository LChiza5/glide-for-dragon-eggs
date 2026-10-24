--!strict
-- Punto de entrada del cliente.

local GlideController = require(script.Controllers.GlideController)
local Hud = require(script.UI.Hud)
local StatsController = require(script.Controllers.StatsController)
local TrainingController = require(script.Controllers.TrainingController)

StatsController.start()
TrainingController.start()
GlideController.start()
Hud.mount()
