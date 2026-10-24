--!strict
-- Dueño: José.
-- HUD principal: stats arriba a la izquierda y botón de entrenar abajo al centro.
--
-- Pendiente, Etapa 1: "+1" que salta al entrenar (TrainingController.onTrained),
-- barra de distancia durante el vuelo y pantalla de resultado al aterrizar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local StatsController = require(script.Parent.Parent.Controllers.StatsController)
local Theme = require(script.Parent.Theme)
local TrainingController = require(script.Parent.Parent.Controllers.TrainingController)
local Types = require(ReplicatedStorage.Shared.Types)
local formatNumber = require(ReplicatedStorage.Shared.formatNumber)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

type Scope = Fusion.Scope<typeof(Fusion)>

local Hud = {}

local function StatRow(
	scope: Scope,
	props: { Label: string, Stat: Types.StatName, Color: Color3, LayoutOrder: number }
): Instance
	return scope:New("TextLabel")({
		LayoutOrder = props.LayoutOrder,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		FontFace = Theme.Font,
		TextSize = 24,
		TextColor3 = props.Color,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = scope:Computed(function(use)
			return `{props.Label}  {formatNumber(use(StatsController.get(props.Stat)))}`
		end),
	})
end

local function StatsPanel(scope: Scope): Instance
	return scope:New("Frame")({
		Name = "Stats",
		Position = UDim2.fromOffset(Theme.Space.L, Theme.Space.L),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.15,

		[Children] = {
			scope:New("UICorner")({ CornerRadius = Theme.RadiusPanel }),
			scope:New("UIPadding")({
				PaddingTop = UDim.new(0, Theme.Space.M),
				PaddingBottom = UDim.new(0, Theme.Space.M),
				PaddingLeft = UDim.new(0, Theme.Space.L),
				PaddingRight = UDim.new(0, Theme.Space.L),
			}),
			scope:New("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, Theme.Space.XS),
			}),
			StatRow(scope, { Label = "Power", Stat = "WingPower", Color = Theme.Power, LayoutOrder = 1 }),
			StatRow(scope, { Label = "Coins", Stat = "Coins", Color = Theme.Coins, LayoutOrder = 2 }),
		},
	})
end

local function TrainButton(scope: Scope): Instance
	return scope:New("TextButton")({
		Name = "Train",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -Theme.Space.XL),
		Size = UDim2.fromOffset(220, 64),
		BackgroundColor3 = Theme.Primary,
		BackgroundTransparency = 0,
		FontFace = Theme.Font,
		TextSize = 32,
		TextColor3 = Theme.OnPrimary,
		Text = "TRAIN +1",

		[Children] = {
			scope:New("UICorner")({ CornerRadius = Theme.RadiusButton }),
		},

		[OnEvent("Activated")] = function()
			TrainingController.train()
		end,
	})
end

function Hud.mount()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
	if playerGui == nil then
		warn("Hud: PlayerGui did not load")
		return
	end

	local scope = Fusion.scoped(Fusion)
	scope:New("ScreenGui")({
		Name = "Hud",
		ResetOnSpawn = false,
		Parent = playerGui,

		[Children] = {
			StatsPanel(scope),
			TrainButton(scope),
		},
	})
end

return table.freeze(Hud)
