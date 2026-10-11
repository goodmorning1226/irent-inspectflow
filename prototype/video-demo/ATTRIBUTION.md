# Third-party asset attribution

## Car Concept

- Source: KhronosGroup/glTF-Sample-Assets, `Models/CarConcept`
- Model and textures: © 2024 Darmstadt Graphics Group GmbH, Eric Chadwick
- License: Creative Commons Attribution 4.0 International (CC BY 4.0)
- Source page: https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/CarConcept
- License file: https://github.com/KhronosGroup/glTF-Sample-Assets/blob/main/Models/CarConcept/LICENSE.md

The demo hides logo/decal meshes whose names identify Khronos, 3D Commerce, logo, or decal content. Attribution remains included with the project and final video documentation.

## Mall Parking Lot HDRI

- Author: Sergej Majboroda
- Source: Poly Haven, `Mall Parking Lot`
- License: CC0 1.0 Universal / public domain dedication
- Source page: https://polyhaven.com/a/mall_parking_lot

The HDRI is used as the parking-lot background and image-based lighting for this concept demo.

## V3 previous comparison asset: five-door crossover SUV

- Source: Innerscene 3D Parts Library, `Charcoal five-door crossover SUV`
- License: CC0 1.0 Universal / public domain dedication
- Source page: https://www.innerscene.com/tools/library/3d-parts/charcoal-five-door-crossover-suv-a1996830
- Local use: body paint is changed to white and manufacturer branding is not present.

This model remains in the project for comparison but is no longer used by the active V3 render.

## V3 active vehicle: five-door compact hatchback

- Source: Innerscene 3D Parts Library, `Silver five-door compact hatchback`
- License: CC0 1.0 Universal / public domain dedication
- Source page: https://www.innerscene.com/tools/library/3d-parts/silver-five-door-compact-hatchback-6bf4a878
- Local use: body paint is replaced with a white clearcoat physical material; manufacturer branding is not present.

## V3 Park Parking environment

- Author: Andreas Mischok
- Source: Poly Haven, `Park Parking`
- License: CC0 1.0 Universal / public domain dedication
- Source page: https://polyhaven.com/a/park_parking

The V3 test uses this HDRI as both the tree-lined parking background and image-based lighting.

## Active still-image walk test: RIFE NCNN Vulkan

- Project: `nihui/rife-ncnn-vulkan`
- Source: https://github.com/nihui/rife-ncnn-vulkan
- Release used: `20221029` Windows portable package
- License: MIT
- Local installation: `C:\Users\user\.codex\tools\rife-ncnn-vulkan-20221029`

RIFE is used only to interpolate the project-owned side, front, and generated
intermediate concept frames. Its binary and model bundle are not copied into
the repository.

## Active still-image walk test: generated intermediate views

The 15°, 30°, 45°, 60°, and 75° front-left keyframes were created with the
built-in ImageGen tool using the mobile prototype's existing side and front
images as references. They are product-concept assets rather than measured
vehicle geometry. Prompt constraints are recorded in
`assets/still-walk-keyframes/PROMPTS.md`.
