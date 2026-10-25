--!strict
-- Punto de entrada del cliente.

local GlideController = require(script.Controllers.GlideController)
local Hud = require(script.UI.Hud)
local InventoryController = require(script.Controllers.InventoryController)
local StatsController = require(script.Controllers.StatsController)
local TrainingController = require(script.Controllers.TrainingController)

StatsController.start()
InventoryController.start()
TrainingController.start()
GlideController.start()
Hud.mount()
