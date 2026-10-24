# Equipo, dueños y etapas

## Roles

| Integrante | Rol | Es dueño de |
|---|---|---|
| **Luis** | Líder y sistemas | Datos, economía, huevos y probabilidades, monetización, analítica. Dueño del repo y de las publicaciones. |
| **Isaac** | Gameplay y mundo | Entrenamiento, lanzamiento y planeo, reinos, dragones que te siguen, nido. Modelos en Blender. |
| **José** | Interfaz, arte y marketing | HUD, tienda, inventario, índice de dragones, animaciones de UI, icono, miniaturas, trailer. |

## Dueños por archivo

| Archivo o carpeta | Dueño |
|---|---|
| `src/server/Services/DataService.luau` | Luis |
| `src/server/Services/TrainingService.luau` | Luis |
| `src/server/Services/EggService.luau` | Luis |
| `src/server/Services/MonetizationService.luau` | Luis |
| `src/server/Services/GlideService.luau` | Isaac (medición) · Luis (pago) |
| `src/client/Controllers/StatsController.luau` | Luis |
| `src/client/Controllers/TrainingController.luau` | Isaac |
| `src/client/Controllers/GlideController.luau` | Isaac |
| `src/client/UI/` | José |
| `src/shared/Config/` | Luis (José e Isaac proponen cambios) |
| Mapa y modelos (Team Create) | Isaac |
| Icono, miniaturas, página del juego | José |

## Etapas

En cada etapa los tres trabajan a la vez, en relevo: el primero deja lista la base que usa el siguiente.

| Etapa | 1º | 2º | 3º | Cierre |
|---|---|---|---|---|
| **0 · Preparación** (días 1–3) | **Luis:** Grupo de Roblox, lugares Staging y Producción, este repo, invitar a los dos | **Isaac:** mapa en bloques (spawn, máquinas, acantilado, primer reino con marcas de distancia) | **José:** dirección de arte, paleta, bocetos de HUD, tienda e inventario | **Luis:** todos sincronizan con Rojo y entran a Staging |
| **1 · Bucle principal** (semanas 1–2) | **Luis:** datos, stats, entrenamiento validado en servidor | **Isaac:** lanzamiento y planeo, distancia → recompensa, zonas | **José:** HUD con “+1”, barra de distancia, pantalla de resultado, sonidos | **Luis:** integrar y probar: 5 minutos ya divertidos |
| **2 · Colección** (semanas 3–4) | **Luis:** huevos, rarezas, inventario, equipar, nido, ganancias offline | **Isaac:** huevos en el aire, modelos de dragones, dragón que te sigue, nido | **José:** eclosión animada, inventario, índice, avisos de rareza | **Luis:** balance de probabilidades y economía |
| **3 · Monetización y retención** (semana 5) | **Luis:** pases, productos, compra segura, renacer, recompensa diaria, clasificaciones | **Isaac:** reino 2, obstáculos en vuelo, optimización | **José:** tienda y ofertas, icono, miniaturas, trailer, página del juego | **Luis:** prueba completa de compras en Staging |
| **4 · Lanzamiento suave** (semana 6) | **Isaac:** pruebas con amigos, lista de errores | **José:** pulir primeros 5 minutos y tutorial | **Luis:** analítica (entrar → primer vuelo → primer huevo → renacer) y publicar | **Todos:** primeros anuncios con presupuesto pequeño |
| **5 · Operación** (cada semana) | **Luis (lun):** revisar métricas y decidir la actualización | **Isaac (mar–jue):** reino, evento o mecánica nueva | **José (mar–jue):** UI, cosméticos, miniatura nueva | **Luis:** vie integrar en Staging · sáb publicar |

## Metas para saber si vamos bien

- Vuelve al día siguiente (D1): 20 % o más
- Sesión promedio: 12 minutos o más
- Me gusta: 90 % o más
- Compra algo: 2–5 % de los jugadores

## El dinero

El juego se publica a nombre del Grupo de Roblox. Los Robux entran al grupo y se reparten con pagos recurrentes por porcentaje, acordados por escrito entre los tres antes de lanzar.
