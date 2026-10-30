--!strict
-- Punto de entrada del cliente.

local DragonController = require(script.Controllers.DragonController)
local GlideController = require(script.Controllers.GlideController)
local GlideDistanceBar = require(script.UI.GlideDistanceBar)
local Hud = require(script.UI.Hud)
local InventoryController = require(script.Controllers.InventoryController)
local PurchaseController = require(script.Controllers.PurchaseController)
local StatsController = require(script.Controllers.StatsController)
local TrainingController = require(script.Controllers.TrainingController)

StatsController.start()
InventoryController.start()
PurchaseController.start()
TrainingController.start()
GlideController.start()
DragonController.start()
Hud.mount()
GlideDistanceBar.mount()
