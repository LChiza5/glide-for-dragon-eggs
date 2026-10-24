--!strict
-- Dueño: Luis.
--
-- Pendiente, Etapa 3:
--   1. Revisar pases con MarketplaceService:UserOwnsGamePassAsync (con pcall) al entrar,
--      guardarlo en caché y escuchar PromptGamePassPurchaseFinished para compras en vivo.
--   2. MarketplaceService.ProcessReceipt para productos:
--      - si receipt.PurchaseId ya está en data.PurchaseHistory, devolver PurchaseGranted sin entregar;
--      - si los datos del jugador no están cargados, devolver NotProcessedYet;
--      - entregar, agregar el PurchaseId al historial y recién ahí devolver PurchaseGranted.
--   3. Los IDs salen de Config/Products.luau.

local MonetizationService = {}

-- Multiplicador de poder por entrenamiento. Devolverá 2 con el pase DoublePower.
function MonetizationService.getPowerMultiplier(_player: Player): number
	return 1
end

function MonetizationService.start() end

return table.freeze(MonetizationService)
