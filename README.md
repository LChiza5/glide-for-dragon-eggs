# +1 Glide for Dragon Eggs

Simulador incremental para Roblox: entrenas tus alas (+1 por toque), te lanzas desde un acantilado, planeas por reinos y encuentras huevos de dragón. Los dragones te hacen planear más lejos y generan monedas en tu nido, incluso desconectado.

Equipo: **Luis** (sistemas y liderazgo) · **Isaac** (gameplay y mundo) · **José** (interfaz, arte y marketing).

## Cómo se trabaja

- **El código vive en este repo** (archivos `.luau`) y Rojo lo sincroniza a Roblox Studio. Nadie edita scripts dentro de Studio.
- **El mapa, los modelos y el diseño de la UI** se editan en Team Create, en el lugar de **Staging**.
- **El juego es del Grupo de Roblox**, no de una cuenta personal. Solo se publica a **Producción** lo que se probó en Staging.

Detalles en [CONTRIBUTING.md](CONTRIBUTING.md), roles y etapas en [docs/EQUIPO.md](docs/EQUIPO.md), diseño del juego en [docs/DISENO.md](docs/DISENO.md). Qué le toca hacer ahora a cada quien: [docs/PENDIENTES.md](docs/PENDIENTES.md).

## Primera vez (cada integrante)

1. Instalar [Roblox Studio](https://create.roblox.com/), [Git](https://git-scm.com/) y [VS Code](https://code.visualstudio.com/).
2. Instalar [Rokit](https://github.com/rojo-rbx/rokit) (gestor de herramientas). En Windows: bajar `rokit-*-windows-x86_64.zip` de sus Releases, descomprimir y correr `rokit self-install`.
3. Clonar el repo y, dentro de la carpeta:

   ```bash
   rokit install      # instala rojo, wally, stylua, selene y luau-lsp en las versiones del proyecto
   wally install      # descarga los paquetes (Fusion, ProfileStore)
   rojo plugin install  # instala el plugin de Rojo en Studio
   ```

   Para que VS Code reconozca los tipos de los paquetes (repetir después de cada `wally install`):

   ```bash
   rojo sourcemap default.project.json --output sourcemap.json
   wally-package-types --sourcemap sourcemap.json Packages/
   wally-package-types --sourcemap sourcemap.json ServerPackages/
   ```

4. Abrir la carpeta en VS Code y aceptar las extensiones recomendadas.

## Día a día

```bash
git pull
rojo serve
```

En Studio: abrir **tu propia copia** del lugar de pruebas → pestaña Plugins → Rojo → **Connect**. Cada vez que guardas un `.luau`, Studio se actualiza.

Antes de abrir un Pull Request:

```bash
stylua src
selene src
```

## Estructura

```
src/
├── shared/   → ReplicatedStorage.Shared       (lo usan servidor y cliente)
│   ├── Config/      Balance, Eggs, Products
│   ├── Remotes.luau
│   ├── Types.luau
│   └── formatNumber.luau
├── server/   → ServerScriptService.Server     (solo servidor)
│   ├── init.server.luau
│   └── Services/    Data, Training, Glide, Egg, Monetization
└── client/   → StarterPlayerScripts.Client    (solo cliente)
    ├── init.client.luau
    ├── Controllers/ Stats, Training, Glide
    └── UI/          Theme, Hud
```

Cada archivo dice arriba quién es su dueño y qué le falta.
