# Cómo trabajamos

## Ramas

- `main` siempre funciona. Nadie sube directo a `main`.
- Una rama por cosa: `feat/planeo`, `feat/tienda-ui`, `fix/monedas-duplicadas`.
- Ramas cortas: si una rama vive más de 3–4 días, se parte en pedazos.

```bash
git checkout main
git pull
git checkout -b feat/planeo
# ...trabajar...
git add src/server/Services/GlideService.luau
git commit -m "Medir distancia de planeo en el servidor"
git push -u origin feat/planeo
```

Después, en GitHub: **Pull Request** hacia `main`. Otro integrante lo revisa y lo aprueba. El CI (formato, lint y build) tiene que estar en verde.

## Commits

- En español, en presente y cortos: "Agregar tienda de pases", "Arreglar huevo que no eclosiona".
- Un commit = un cambio que se entiende solo.

## Reglas del código

- Todo lo que da monedas, poder, huevos o dragones se decide **en el servidor**. El cliente solo pide.
- Todo parámetro que llega por un RemoteEvent se trata como `unknown` y se valida.
- Los números del juego van en `src/shared/Config/`, no sueltos en el código.
- Los colores, letras y espacios de la UI van en `src/client/UI/Theme.luau`.
- Si tocas un archivo de otro dueño, avísale antes o pídele revisión.

## Studio y Team Create

- Scripts: **solo** en este repo. Si alguien edita un script en Studio, Rojo lo pisa al sincronizar.
- Mapa, modelos y diseño visual: en Team Create sobre el lugar de **Staging**.
- Cada programador prueba con `rojo serve` en **su propia copia** del lugar, no en el compartido, para no pisarse.

## Publicar

1. Luis junta lo aprobado en `main` y lo sincroniza a **Staging**.
2. Se prueba entre los tres (compras de prueba incluidas).
3. Si todo está bien, se publica a **Producción** el sábado, con su nota de actualización.
