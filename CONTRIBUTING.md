# Contributing

## Prerequisites

- [Blender](https://www.blender.org/) (3.2+) with the GIANTS I3D Exporter addon
- [GIANTS Editor](https://gdn.giants-software.com/)
- [GIANTS Texture Tool](https://gdn.giants-software.com/) — see below

## Project structure

```
FS25_DynamicHalls/   the mod itself - ships as-is, this is what gets zipped/installed
Source/               .blend files and source PNG textures - never shipped with the mod
```

## Texture workflow (PNG -> DDS)

Source textures are authored as `.png` files under `Source/` and converted to
`.dds` (the format the GIANTS Engine actually loads) using GIANTS' own
Texture Tool. The converted `.dds` file is written next to its source `.png`.

### Setup (one-time)

1. Download the Texture Tool from GDN and extract it somewhere permanent
   (not your Desktop/Downloads — pick a folder you won't clean up later).
2. Add that folder to your user `PATH` environment variable, so
   `textureTool.exe` is callable from anywhere.
3. Restart VS Code fully (quit and reopen, not just "Reload Window" — `PATH`
   changes are only picked up by new processes).

### Running the conversion

Press `Ctrl+Shift+B` in VS Code (runs the default build task), or open the
command palette and run `Tasks: Run Task` -> **Build Textures (PNG -> DDS)**.
This recursively converts every `.png` under `Source/` to a sibling `.dds`.
Unchanged files are skipped automatically based on file timestamps.

If you need to force-regenerate everything (e.g. after a Texture Tool
upgrade), run the **Build Textures (PNG -> DDS, force)** task instead.

### Naming conventions

The Texture Tool automatically picks conversion settings based on the source
PNG's filename suffix — no manual configuration needed for normal cases:

| Suffix          | Color space | Notes                                                                    |
|------------------|-------------|---------------------------------------------------------------------------|
| `_diffuse.png`   | sRGB        | Standard color/albedo map. BC1 (opaque) or BC7 (with alpha).              |
| `_normal.png`    | linear      | Tangent-space normal map; vectors are renormalized automatically.         |
| `_specular.png`  | linear      | Roughness correction auto-enabled if a matching `_normal.png` exists.     |
| `_alpha.png`     | —           | Converted to a signed distance field for crisp alpha-cutout edges.        |
| anything else    | linear      | Format inferred from channel count (1ch -> BC4, 3ch -> BC1, 4ch -> BC7).  |

Follow these suffixes for new textures and the correct settings are applied
automatically. If a texture genuinely needs to deviate from its suffix
default, add a `.gim` file next to it with the same base name (e.g.
`wall01_diffuse.gim`) overriding just the specific option — see
`template.gim` in the Texture Tool's install folder for the full list of
overridable options.