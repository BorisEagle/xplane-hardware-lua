# X-Plane Hardware Lua

FlyWithLua scripts that improve physical cockpit hardware integration in
X-Plane 12. The initial script targets the WINWING WINCTRL 3N PDC L and the
Zibo 737-800.

## Available scripts

### WINCTRL 3N PDC L MINS acceleration

[`scripts/winwing/winctrl_pdc_l_mins.lua`](scripts/winwing/winctrl_pdc_l_mins.lua)
adds progressive acceleration to the captain-side MINS knob.

The script handles both fine adjustment and staged acceleration itself,
including on Linux without SimAppPro.

| Hold time | Behaviour |
| --- | --- |
| On press | One immediate 1 ft step |
| Less than 0.30 seconds | No additional movement |
| 0.30–1.50 seconds | 10 ft steps every 0.18 seconds |
| At least 1.50 seconds | 100 ft steps every 0.20 seconds |

Movement stops immediately when the knob is released. The script writes exact
increments to Zibo's captain MINS dataref, avoiding oversized or
frame-rate-dependent jumps from the native FAST command.

## Requirements

- X-Plane 12
- Zibo 737-800
- FlyWithLua NG
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

SimAppPro is not required. Keep the Linux WINCTRL plugin installed for the
other panel functions.

In X-Plane's joystick settings, assign the two physical MINS direction buttons
(buttons 40 and 42) to the matching commands:

| Physical direction | X-Plane command |
| --- | --- |
| MINS increase | `PDC_L/EFIS/MINS_UP_ACCEL` |
| MINS decrease | `PDC_L/EFIS/MINS_DOWN_ACCEL` |

The Linux [WINCTRL plugin](https://github.com/BorisEagle/winctrl-xplane-plugin)
skips its own handling for buttons assigned in X-Plane, so Lua owns both the
initial step and acceleration. Keep only one copy of this script loaded.
On Windows, disable any parallel SimAppPro MINS mapping to avoid duplicate
movement.

This fix retains the existing direct-dataref behaviour; it does not implement
the plugin's recovery of the last MINS value after RST/unset.

## Tuning

Acceleration timing and step sizes are defined near the top of the script:

```lua
medium_after = 0.30
fast_after   = 1.50
medium_step  = 10
fast_step    = 100
```

The acceleration timings were previously tested with the Zibo 737-800 and
WINCTRL 3N PDC L. The standalone initial-step fix is checked with a Lua test
harness; in-simulator verification is still required.

## Related project

The separate [`improvedTCA`](https://github.com/BorisEagle/improvedTCA) fork is
kept for Thrustmaster Boeing TCA integration and upstream compatibility.

## License

This project is licensed under the [MIT License](LICENSE).

