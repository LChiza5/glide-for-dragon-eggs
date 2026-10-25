--!strict
-- Punto de entrada del servidor. Los requires no arrancan nada; el orden de arranque es el de abajo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Services.DataService)
local EggService = require(script.Services.EggService)
local GlideService = require(script.Services.GlideService)
local MonetizationService = require(script.Services.MonetizationService)
local RebirthService = require(script.Services.RebirthService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local TrainingService = require(script.Services.TrainingService)

Remotes.setupServer()

DataService.start()
MonetizationService.start()
TrainingService.start()
RebirthService.start()
GlideService.start()
EggService.start()
