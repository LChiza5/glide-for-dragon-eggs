--!strict
-- Dueño: Luis.
-- Pide al servidor que muestre la ventana de compra de un pase o producto, y avisa cómo salió el pedido.
-- El cliente solo manda la clave (por ejemplo "DoublePower" o "EggPack3"); el servidor decide si se puede y qué ID usar.
-- El resultado de la compra no llega aquí: se ve en los atributos del Player (OwnsDoublePower, FreeEggs, LuckUntil...),
-- que ya se leen con StatsController.get.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local resultCallbacks: { (Types.PurchaseResult) -> () } = {}

local PurchaseController = {}

-- Claves de pases: DoublePower, AutoTrain, Vip, ExtraDragonSlots, DoubleLuck, FastHatch.
-- Claves de productos: StarterPack, EggPack3, EggPack10, LuckPotion, DoubleOffline.
function PurchaseController.request(key: string)
	Remotes.get("RequestPurchase"):FireServer(key)
end

-- Enciende o apaga el entrenamiento automático (solo tiene efecto con el pase AutoTrain).
function PurchaseController.setAutoTrain(on: boolean)
	Remotes.get("SetAutoTrain"):FireServer(on)
end

-- Corre cuando el servidor responde a un pedido de compra: ok = true si se mostró la ventana de Roblox,
-- o ok = false con el motivo (para avisar "ya lo tienes", "no está disponible"...).
function PurchaseController.onResult(callback: (Types.PurchaseResult) -> ())
	table.insert(resultCallbacks, callback)
end

function PurchaseController.start()
	Remotes.get("PurchaseResult").OnClientEvent:Connect(function(result: Types.PurchaseResult)
		for _, callback in resultCallbacks do
			task.spawn(callback, result)
		end
	end)
end

return table.freeze(PurchaseController)
