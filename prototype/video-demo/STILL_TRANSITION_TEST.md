# Still-image walking transition test

This test composites the existing mobile prototype stills into a short,
UI-free movement clip. It does not use Three.js or generate new vehicle
geometry.

## Sequence

- `0.0–1.0 s`: stable side scan frame
- `1.0–2.0 s`: eased push/pan, viewpoint blend, and directional motion trail
- `2.0–3.2 s`: stable front scan frame

There is no vertical camera bob. The transition is deliberately strongest at
the midpoint so the stationary scan frames remain sharp and can later align
with Flutter overlays.

## Render

From the repository root:

```powershell
python prototype/video-demo/scripts/render-still-walk-transition.py
```

Output:

```text
prototype/video-demo/output/still-walk-side-to-front-test-3s.mp4
```

The output is H.264, 1920×1080, 60 FPS, without audio or app UI.

## Multi-keyframe version

The more realistic test uses five generated intermediate views at 15°, 30°,
45°, 60°, and 75°. RIFE NCNN Vulkan fills the frames between them instead of
dissolving directly from the side image to the front. The checked-in renderer
looks for the portable executable in the Codex tools directory, or at the path
provided through the task-specific `IRENT_RIFE_PATH` environment variable.

```powershell
python prototype/video-demo/scripts/render-multikeyframe-walk.py
```

Output:

```text
prototype/video-demo/output/rife-multikeyframe-walk-side-to-front-test.mp4
```

The generated views are concept-demo assets. They preserve the car and scene
as closely as possible but are not a geometrically measured reconstruction.
