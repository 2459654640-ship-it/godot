# D-6 painterly asset sources

These PNGs were generated for this project with the session's image generation
tool. The generator's exact model name is not exposed; they are not claimed to
have been made by a specifically named model. No screenshot/reference scene
was imported as a background or used as a substitute for 3D level geometry.

The character direction sheets share the Ivan sheet as a style/identity
reference. Every cast member has a separate design; five authored views mirror
to eight directions. Ivan has idle and two authored stride poses. NPC walking
uses restrained 2D mesh deformation for the short existing yielding motion.
Portraits are cropped from the same figures so their identity matches gameplay.

`tools/painted-sources.json` maps source files to runtime atlases. Rebuild with:

```sh
python tools/pack_painted_assets.py --sources art-source --manifest tools/painted-sources.json
python tools/pack_painted_materials.py --sources art-source
```

Pillow and NumPy are authoring dependencies only. The game uses the prepared
PNGs, not Python or an image generation service. The packing tools slice, align,
resize and derive subtle normal/roughness channels; they do not invent faces or
repaint the character sheets. Original source PNGs are retained unchanged.

Materials: layered plaster/paint, ceramic tiles, worn wood, concrete, wool and
medallion carpet. They are applied to actual modular meshes. Item atlas: fourteen
quest items plus spare satchel and mug illustrations.
