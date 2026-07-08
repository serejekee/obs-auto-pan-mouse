# OBS Auto Pan Mouse

An OBS Studio Lua script that automatically pans a 9:16 vertical crop window across a 16:9 source (like a game or screen capture) by tracking your global mouse cursor. Perfect for streaming or recording horizontal gameplay into vertical formats (TikTok, YouTube Shorts, Instagram Reels) without needing to manually move the camera!

## Features
- **Global Mouse Tracking**: Automatically follows your mouse cursor horizontally across the screen.
- **Smooth Panning**: Includes an adjustable `follow_speed` parameter for cinematic, smooth camera movements.
- **Auto 9:16 Crop**: Dynamically applies a Crop/Pad filter to lock the output aspect ratio to 9:16 (vertical) based on a 1920x1080 source.
- **Linux X11 Native**: Uses LuaJIT `FFI` and `libX11` to read absolute global mouse coordinates directly from the X11 Display.
- **Wayland Fallback (Demo Mode)**: If Wayland's security model blocks global cursor reading (returning `0,0`), the script automatically enters a demo mode where it smoothly pans back and forth automatically.

## Requirements
- OBS Studio (with Lua scripting support enabled)
- Linux with an X11 session (or XWayland, if the compositor allows global cursor reads). 
> **Note**: Native Wayland sessions restrict global cursor reading for security reasons. If you are on Wayland, the script will likely fall back to the automatic bounce test mode.

## Installation & Usage
1. Save the `obs_auto_pan_mouse.lua` file to your computer.
2. Open OBS Studio.
3. Go to the top menu: **Tools** -> **Scripts**.
4. Click the **+** (Add) button at the bottom left and select `horizontal_pan.lua`.
5. In the script settings panel on the right side:
   - **Source (Источник)**: Select the specific Video Capture or Screen Capture source you want to apply the vertical crop to.
   - **Follow Speed (Плавность)**: Adjust the slider to change how fast the camera follows the mouse. `1.0` is instant (snappy), while lower values like `0.05` to `0.1` provide a very smooth, cinematic drag.

## How it works
The script creates or hooks into a standard OBS Crop/Pad filter named `VerticalCrop` on your selected source. On every frame, it calculates the necessary `left` and `right` pixel crop margins to maintain a strict vertical aspect ratio, shifting the center point (`cur_cx`) towards the mouse's real-time X position. It also prevents the "camera" from panning out of bounds past the edges of your source.
