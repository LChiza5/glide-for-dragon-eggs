--!strict
-- Dueño: José (base hecha por Luis; el estilo es de José).
-- Barra de distancia durante el vuelo: arriba al centro y solo mientras se planea.
-- Se llena hacia la mejor distancia del jugador (BestDistance) y se pone dorada al superarla.
-- La distancia es la que ve el cliente; la que paga el servidor llega aparte por "GlideResult".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GlideController = require(script.Parent.Parent.Controllers.GlideController)
local StatsController = require(script.Parent.Parent.Controllers.StatsController)
local Theme = require(script.Parent.Theme)
local formatNumber = require(ReplicatedStorage.Shared.formatNumber)

local Children = Fusion.Children

local FILL_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local GlideDistanceBar = {}

function GlideDistanceBar.mount()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
	if playerGui == nil then
		warn("GlideDistanceBar: PlayerGui did not load")
		return
	end

	local scope = Fusion.scoped(Fusion)
	local gliding = scope:Value(false)
	local distance = scope:Value(0)
	local best = StatsController.get("BestDistance")
	local heartbeat: RBXScriptConnection? = nil

	GlideController.onGlideStarted(function()
		distance:set(0)
		gliding:set(true)
		if heartbeat == nil then
			heartbeat = RunService.Heartbeat:Connect(function()
				distance:set(math.floor(GlideController.distance()))
			end)
		end
	end)
	GlideController.onGlideEnded(function()
		gliding:set(false)
		if heartbeat ~= nil then
			heartbeat:Disconnect()
			heartbeat = nil
		end
	end)

	local isRecord = scope:Computed(function(use)
		local bestValue = use(best)
		return bestValue > 0 and use(distance) > bestValue
	end)
	local fillSize = scope:Computed(function(use)
		local bestValue = use(best)
		local ratio = if bestValue > 0 then math.clamp(use(distance) / bestValue, 0, 1) else 1
		return UDim2.fromScale(ratio, 1)
	end)

	scope:New("ScreenGui")({
		Name = "GlideDistance",
		ResetOnSpawn = false,
		Enabled = gliding,
		Parent = playerGui,

		[Children] = {
			scope:New("Frame")({
				Name = "Panel",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, Theme.Space.L),
				Size = UDim2.fromOffset(360, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
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
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = UDim.new(0, Theme.Space.S),
					}),
					scope:New("TextLabel")({
						Name = "Distance",
						LayoutOrder = 1,
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						FontFace = Theme.Font,
						TextSize = 32,
						TextColor3 = scope:Computed(function(use)
							return if use(isRecord) then Theme.Coins else Theme.Text
						end),
						Text = scope:Computed(function(use)
							return `{formatNumber(use(distance))} studs`
						end),
					}),
					scope:New("Frame")({
						Name = "Track",
						LayoutOrder = 2,
						Size = UDim2.new(1, 0, 0, Theme.Space.M),
						BackgroundColor3 = Theme.SurfaceElevated,
						BackgroundTransparency = 0,
						ClipsDescendants = true,

						[Children] = {
							scope:New("UICorner")({ CornerRadius = Theme.RadiusButton }),
							scope:New("Frame")({
								Name = "Fill",
								Size = scope:Tween(fillSize, FILL_TWEEN),
								BackgroundTransparency = 0,
								BackgroundColor3 = scope:Computed(function(use)
									return if use(isRecord) then Theme.Coins else Theme.Primary
								end),

								[Children] = {
									scope:New("UICorner")({ CornerRadius = Theme.RadiusButton }),
								},
							}),
						},
					}),
					scope:New("TextLabel")({
						Name = "Best",
						LayoutOrder = 3,
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						FontFace = Theme.Font,
						TextSize = 16,
						TextColor3 = scope:Computed(function(use)
							return if use(isRecord) then Theme.Coins else Theme.TextMuted
						end),
						Text = scope:Computed(function(use)
							local bestValue = use(best)
							if use(isRecord) then
								return "NEW BEST!"
							elseif bestValue > 0 then
								return `Best  {formatNumber(bestValue)} studs`
							end
							return "First flight!"
						end),
					}),
				},
			}),
		},
	})
end

return table.freeze(GlideDistanceBar)
