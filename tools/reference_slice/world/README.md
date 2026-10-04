# World adapter for the approval slice

Entry API: `reference_world.gd`, a presentation-only `Node2D` added under the actual
`main.level_builder.level_root`. Set `density` to 48 or 32 before `setup(main)`;
`set_density(value)` changes the live raster treatment without altering physics.
`background_path(biome)` returns a panorama path for root's screen-space backdrop.

The current integration covers the same flat 12×8 native fixture in Meadow and
Volcanic, original pendulum/bearing/chain artwork, masonry, turf/basalt, putting
variants, water, sand and yellow launch pad. Water retains its native identity in
both views. Lava artwork is prepared but not substituted for the fixture's water.
Ice and other unshown hazards retain native art; the four remaining biomes and
elevated geometry are outside this approval slice.

Root owns the integrated manual entrypoint and launcher. The specialist helper
below only captures a static world review, has no automated shots, and then exits:

```powershell
godot4 --path . --rendering-method gl_compatibility res://tools/reference_slice/world/preview.tscn -- --world-density=48 --world-stage=refined2
godot4 --path . --rendering-method gl_compatibility res://tools/reference_slice/world/preview.tscn -- --world-density=32 --world-stage=refined2
godot4 --path . --rendering-method gl_compatibility res://tools/reference_slice/world/preview.tscn -- --world-density=48 --world-biome=volcanic --world-stage=refined2
```

These commands were run in `C:/Users/Rony/Projects/a-stroke-of-luck` with Godot 4.6.2,
Compatibility rendering, at 1280×720; all returned 0 without runtime error output.
They use native production HUD only to isolate world inspection; root's composite
captures are the authority for the integrated UI/background treatment.

Re-export original world assets with `python tools/reference_slice/world/export_world.py`.
`world_assets.gd` provides `texture(path,density)` and `sprite(...)` for root feedback.
Strike/dust/water frames are `d48/fx/{kind}_{0..3}.png` with parallel `d32` paths.

Recorded code checks: `godot4 --headless --path . --script res://tools/reference_slice/world/reference_world.gd --check-only`;
short headless editor imports; nine world-only rendered captures across the initial
and two refined candidates. Final helpers use `--world-stage=refined2` and also
write JSON reports: unchanged physics after setup and repeated density changes,
stable node counts, exact pendulum center/88-unit extents, and native pause freezing
both decorative and hazard clocks. All three final reports passed those checks.
The full verifier and wider physics/lifecycle suite belong to root's integrated
pass. Native input feel and human style approval are not claimed by these captures.
