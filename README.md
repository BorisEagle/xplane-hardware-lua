# X-Plane Hardware Lua

FlyWithLua scripts that improve physical cockpit hardware integration in
X-Plane 12. The initial script targets the WINWING WINCTRL 3N PDC L and the
Zibo 737-800.

## Available scripts

### WINCTRL 3N PDC L MINS acceleration

[`scripts/winwing/winctrl_pdc_l_mins.lua`](scripts/winwing/winctrl_pdc_l_mins.lua)
adds progressive acceleration to the captain-side MINS knob.

SimAppPro detects the PDC L MINS directions as held buttons, but its current
Zibo integration moves the value only at the slow rate. This script retains
that native fine adjustment and adds controlled acceleration during a
continuous hold.

| Hold time | Behaviour |
| --- | --- |
| Less than 0.30 seconds | SimAppPro fine movement only |
| 0.30–1.50 seconds | Additional 10 ft steps every 0.18 seconds |
| More than 1.50 seconds | Additional 100 ft steps every 0.20 seconds |

Movement stops immediately when the knob is released. The script writes exact
increments to Zibo's captain MINS dataref, avoiding oversized or
frame-rate-dependent jumps from the native FAST command.

## Requirements

- X-Plane 12
- Zibo 737-800
- FlyWithLua NG
- SimAppPro
- WINWING WINCTRL 3N PDC L

## Installation

1. Download
   [`winctrl_pdc_l_mins.lua`](scripts/winwing/winctrl_pdc_l_mins.lua).
2. Copy it to:

   ```text
   X-Plane 12/Resources/plugins/FlyWithLua/Scripts/
   ```

3. Start X-Plane 12 and load the Zibo 737-800.

## Configuration

Leave the default automatic PDC L mapping enabled in SimAppPro. Do not create a
custom SimAppPro key-binding profile for this workaround.

In X-Plane's joystick settings, assign the two physical MINS direction buttons
(buttons 40 and 42) to the matching commands:

| Physical direction | X-Plane command |
| --- | --- |
| MINS increase | `PDC_L/EFIS/MINS_UP_ACCEL` |
| MINS decrease | `PDC_L/EFIS/MINS_DOWN_ACCEL` |

The original SimAppPro mapping and the FlyWithLua command must both remain
active: SimAppPro supplies fine movement and Lua supplies only the additional
acceleration.

## Tuning

Acceleration timing and step sizes are defined near the top of the script:

```lua
medium_after = 0.30
fast_after   = 1.50
medium_step  = 10
fast_step    = 100
```

The supplied values were tested with the Zibo 737-800 and WINCTRL 3N PDC L.

## Related project

The separate [`improvedTCA`](https://github.com/BorisEagle/improvedTCA) fork is
kept for Thrustmaster Boeing TCA integration and upstream compatibility.

## License

This project is licensed under the [MIT License](LICENSE).
