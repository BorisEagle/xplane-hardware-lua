# Zibo 737 Linux hardware setup checklist

This checklist rebuilds the useful parts of the old Windows `ZIBO` control
profile on a fresh X-Plane 12 Linux installation. It intentionally covers only
these devices:

- Thrustmaster TCA Quadrant Boeing 1&2 (`044f:040a`)
- Thrustmaster TCA Quadrant Boeing 3&4 (`044f:040b`)
- Saitek AV8R joystick (`06a3:0461`)
- WINWING WINCTRL 3N PFP Captain (`4098:bb35`)
- Jimmi X6 (`8462:6183`)
- WINWING WINCTRL 3N PAP (`4098:bf0f`)
- WINWING WINCTRL 3N PDC L (`4098:bb61`)
- Thrustmaster TCA Yoke Boeing (`044f:0409`)

Linux can number buttons differently from Windows, especially on composite
WINWING devices. Select a device in X-Plane and operate the physical control to
identify it; treat the old button numbers below as a cross-check, not as the
primary identification method.

## 1. Prepare X-Plane and plugins

- [ ] Connect only the eight devices listed above.
- [ ] Confirm Linux sees all eight USB IDs with `lsusb`.
- [ ] Start X-Plane, open **Settings > Joystick**, and confirm every device has
      its own tab.
- [ ] Install FlyWithLua NG in
      `X-Plane 12/Resources/plugins/FlyWithLua/`.
- [ ] Copy these repository scripts into
      `X-Plane 12/Resources/plugins/FlyWithLua/Scripts/`:
  - [ ] `scripts/thrustmaster/tca_throttle_average_zibo.lua`
  - [ ] `scripts/saitek/av8r_zibo_position_lights.lua`
  - [ ] `scripts/winwing/winctrl_pdc_l_mins.lua`
- [ ] Install or restore the Linux WINCTRL plugin used by the three WINWING
      panels.
- [ ] If keeping the old TCA reverser and turn-knob functions, also restore the
      script which supplies the `FlyWithLua/improvedboetca/*` commands.
- [ ] Load the Zibo 737-800 before assigning Zibo-specific commands, so they
      appear in X-Plane's command search.
- [ ] Create a new control profile named **ZIBO Linux** and assign it to the
      Zibo 737-800.

## 2. Calibrate and assign axes

Calibrate each device separately. Do not reverse any of the axes below unless
the on-screen response moves opposite to the physical control.

### Four TCA thrust levers

The new FlyWithLua script replaces Joystick Gremlin and vJoy. Make these four
assignments exactly:

| Device | Physical lever | X-Plane axis assignment |
| --- | --- | --- |
| TCA Quadrant Boeing 1&2 | Left thrust lever | `Throttle 1` |
| TCA Quadrant Boeing 1&2 | Right thrust lever | `Throttle 2` |
| TCA Quadrant Boeing 3&4 | Left thrust lever | `Throttle 3` |
| TCA Quadrant Boeing 3&4 | Right thrust lever | `Throttle 4` |

The script sends `(Throttle 1 + Throttle 2) / 2` to Zibo engine 1 and
`(Throttle 3 + Throttle 4) / 2` to Zibo engine 2. It discovers the physical
axis slots from these four X-Plane assignments instead of relying on mapped
engine availability, which only reliably exposes engines 1 and 2 on the Zibo.
X-Plane's **Reverse** checkbox is applied to each lever. All four assignments
must be present; if one disappears, the script releases the Zibo throttle
override and periodically looks for the assignment again.

- [ ] Set the Zibo EFB option **A/T ENGAGED LOCK THROTTLE** to **ON**.
- [ ] Keep all four TCA thrust-lever response curves linear. The script reads
      physical axis values, so X-Plane custom response curves are not applied.
- [ ] Do not assign any of the four levers to `Throttle`, `Throttle 1` twice,
      or a Zibo throttle command.
- [ ] Do not create a vJoy device and do not run Joystick Gremlin on Linux.

### Remaining axes

| Device | Physical/old axis | X-Plane assignment | Old response curve |
| --- | --- | --- | --- |
| Saitek AV8R | Axis 1 | Nosewheel tiller | Linear: `(0,0) (0.129099,0) (0.25,0.157643) (0.561475,0.493631) (1,1)` |
| Saitek AV8R | Axis 2 | Command axis: engine 2 idle/cutoff | Linear |
| Saitek AV8R | Axis 3 | Command axis: engine 1 idle/cutoff | Linear |
| Jimmi X6 | Axis 0 | Yaw | Default |
| Jimmi X6 | Axis 1 | Left toe brake | Default |
| Jimmi X6 | Axis 2 | Right toe brake | Default |
| TCA Quadrant 1&2 | Axis 5 / speedbrake lever | Speedbrakes | Cubic average: `(0,0) (0.1,0.1) (0.2,0.1) (1,1)` |
| TCA Quadrant 3&4 | Axis 3 / flap lever | Flaps | Default; flap detent discretization was off |
| WINCTRL PAP | Axis 4 | Roll | Default |
| WINCTRL PAP | Axis 5 | Pitch | Default |
| TCA Yoke | Axis 4 | Roll | Default |
| TCA Yoke | Axis 5 | Pitch | Default |

The old profile assigned pitch and roll to both the PAP and TCA Yoke. That can
make the controls fight each other. Choose one primary set:

- [ ] Recommended: keep pitch and roll on the TCA Yoke, and set the PAP pitch
      and roll axes to **Do nothing**.
- [ ] If the PAP axes are intentionally required, verify both devices rest at
      precisely centered values before leaving them enabled together.

For the AV8R command axes, configure the low/high detents as follows if the
current X-Plane UI still exposes the command-axis editor:

| AV8R axis | One end | Other end |
| --- | --- | --- |
| Engine 2 command axis | `laminar/B738/engine/mixture2_idle` | `laminar/B738/engine/mixture2_cutoff` |
| Engine 1 command axis | `laminar/B738/engine/mixture1_idle` | `laminar/B738/engine/mixture1_cutoff` |

Operate each axis after assignment and swap its two commands only if the
physical direction is backwards.

## 3. Restore button assignments

### Saitek AV8R (`06a3:0461`)

| Old button | Command |
| ---: | --- |
| 0 | `laminar/B738/push_button/park_brake_on_off` |
| 1 | `laminar/B738/push_button/et_reset_capt` |
| 2 | `laminar/B738/push_button/chrono_cycle_capt` |
| 3 | `laminar/B738/push_button/chrono_capt_et_mode` |
| 4 | `sim/lights/landing_lights_off` |
| 5 | `laminar/B738/spring_switch/landing_lights_all` |
| 6 / 7 | `laminar/B738/switch/rwy_light_left_off` / `laminar/B738/switch/rwy_light_left_on` |
| 8 / 9 | `laminar/B738/switch/rwy_light_right_off` / `laminar/B738/switch/rwy_light_right_on` |
| 10 / 11 | `laminar/B738/toggle_switch/taxi_light_brightness_off` / `laminar/B738/toggle_switch/taxi_light_brightness_on` |
| 12 | `laminar/B738/toggle_switch/position_light_steady` |
| 13 | `laminar/B738/toggle_switch/position_light_strobe` |
| 14 / 18 | `laminar/B738/pilot/barometer_up` / `laminar/B738/pilot/barometer_down` |
| 16 / 20 | `laminar/B738/pfd/dh_pilot_up` / `laminar/B738/pfd/dh_pilot_dn` |

The AV8R position-light script supplies the missing **OFF** position when both
buttons 12 and 13 are released.

### TCA Quadrant Boeing 1&2 (`044f:040a`)

| Old button | Command |
| ---: | --- |
| 1 | `laminar/B738/autopilot/autothrottle_arm_toggle` |
| 2 | `laminar/B738/autopilot/left_toga_press` |
| 4 and 5 | `FlyWithLua/improvedboetca/rev1on` |
| 6 / 9 | `laminar/B738/spring_toggle_switch/APU_start_pos_up` / `laminar/B738/spring_toggle_switch/APU_start_pos_dn` |
| 7 | `laminar/B738/push_button/park_brake_on_off` |
| 8 / 10 | `laminar/B738/knob/left_wiper_up` / `laminar/B738/knob/left_wiper_dn` |
| 11 | `laminar/B738/rotary/eng1_start_off` |
| 12 | `laminar/B738/rotary/eng1_start_cont` |
| 13 | `laminar/B738/rotary/eng1_start_flt` |
| 14 / 15 | `FlyWithLua/improvedboetca/turndecr` / `FlyWithLua/improvedboetca/turnincr` |
| 16 | `laminar/B738/rotary/eng1_start_grd` |

### TCA Quadrant Boeing 3&4 (`044f:040b`)

| Old button | Command |
| ---: | --- |
| 0 | `laminar/B738/autopilot/autothrottle_arm_toggle` |
| 1 | `laminar/B738/autopilot/left_toga_press` |
| 3 and 4 | `FlyWithLua/improvedboetca/rev2on` |
| 6 / 9 | `laminar/B738/knob/right_wiper_up` / `laminar/B738/knob/right_wiper_dn` |
| 8 / 10 | `laminar/B738/knob/autobrake_up` / `laminar/B738/knob/autobrake_dn` |
| 11 | `laminar/B738/rotary/eng2_start_off` |
| 12 | `laminar/B738/rotary/eng2_start_cont` |
| 13 | `laminar/B738/rotary/eng2_start_flt` |
| 16 | `laminar/B738/rotary/eng2_start_grd` |

### WINCTRL 3N PAP (`4098:bf0f`)

| Old button | Command |
| ---: | --- |
| 0 | `laminar/B738/autopilot/capt_disco_press` |
| 2 / 3 | `sim/flight_controls/pitch_trimA_down` / `sim/flight_controls/pitch_trimA_up` |
| 4 / 5 | `sim/flight_controls/pitch_trimB_down` / `sim/flight_controls/pitch_trimB_up` |
| 6 / 7 | `sim/flight_controls/aileron_trim_left` / `sim/flight_controls/aileron_trim_right` |
| 8 / 9 | `sim/flight_controls/rudder_trim_left` / `sim/flight_controls/rudder_trim_right` |
| 10 | `xpilot/ptt` |
| 16 | `laminar/B738/push_button/gear_off` |
| 17 | `laminar/B738/push_button/gear_up` |
| 18–25 | X-Plane eight-way hat commands, clockwise from up |
| 26 | `PAP3/MCP/COURSE_R_UP_ACCEL` |
| 38 / 39 | `PAP3/MCP/VERT_SPEED_DOWN_ACCEL` / `PAP3/MCP/VERT_SPEED_UP_ACCEL` |
| 100 | `laminar/B738/push_button/gear_down` |

### WINCTRL 3N PDC L (`4098:bb61`)

The old Windows numbers were 39/41 for MINS and 42/44 for BARO. The Linux
WINCTRL plugin can expose different numbers. In the current Linux mapping, use
the physical MINS direction controls (typically buttons 40 and 42) for the two
FlyWithLua commands:

| Physical control | Command |
| --- | --- |
| MINS decrease | `PDC_L/EFIS/MINS_DOWN_ACCEL` |
| MINS increase | `PDC_L/EFIS/MINS_UP_ACCEL` |
| BARO decrease | `PDC_L/EFIS/BARO_DOWN_ACCEL` |
| BARO increase | `PDC_L/EFIS/BARO_UP_ACCEL` |

Do not assign a second MINS command to the same controls; the FlyWithLua script
already provides the one-foot tap and accelerated hold behavior.

### TCA Yoke Boeing (`044f:0409`)

| Old button | Command |
| ---: | --- |
| 0 | `laminar/B738/autopilot/capt_disco_press` |
| 1 | `sim/autopilot/servos_toggle` |
| 2 / 3 | `sim/flight_controls/pitch_trimA_down` / `sim/flight_controls/pitch_trimA_up` |
| 4 / 5 | `sim/flight_controls/pitch_trimB_down` / `sim/flight_controls/pitch_trimB_up` |
| 6 / 7 | `sim/flight_controls/aileron_trim_left` / `sim/flight_controls/aileron_trim_right` |
| 8 / 9 | `sim/flight_controls/rudder_trim_left` / `sim/flight_controls/rudder_trim_right` |
| 10 | `xpilot/ptt` |
| 11 | `laminar/B738/autopilot/left_at_dis_press` |
| 15 | `sim/view/ridealong` |
| 16 | `laminar/B738/push_button/gear_off` |
| 17 | `sim/flight_controls/landing_gear_up` |
| 18–25 | X-Plane eight-way hat commands, clockwise from up |
| 100 | `laminar/B738/push_button/gear_down` |

### PFP Captain and Jimmi X6

- [ ] Leave the WINCTRL 3N PFP Captain buttons unassigned in X-Plane; the old
      profile had no direct button mappings for this device. Let the WINCTRL
      plugin handle the panel.
- [ ] Leave Jimmi X6 buttons unassigned; only its yaw and brake axes were used.

## 4. Verify the finished profile

- [ ] Open `FlyWithLua_Debug.txt` and confirm none of the three repository
      scripts was quarantined or stopped.
- [ ] Move each of the four TCA thrust levers separately and confirm X-Plane
      highlights `Throttle 1`, `Throttle 2`, `Throttle 3`, and `Throttle 4` in
      that order.
- [ ] With levers 1 and 2 together, confirm only Zibo engine 1 follows their
      average; repeat with levers 3 and 4 for engine 2.
- [ ] Split the two levers in one pair deliberately and confirm the engine sits
      halfway between them.
- [ ] Disconnect one quadrant temporarily and confirm the script releases the
      throttle override rather than driving one engine from a partial pair.
- [ ] Reconnect it, recalibrate if X-Plane requests it, and reload FlyWithLua
      scripts.
- [ ] Test idle, approximately 40%, takeoff thrust, and full forward positions.
- [ ] Engage autothrottle and confirm the Zibo EFB throttle-lock behavior feels
      correct before flying.
- [ ] Check pitch, roll, yaw, both toe brakes, tiller, speedbrake, and flap
      travel for full range and correct direction.
- [ ] Check the AV8R three-position light switch, PDC L MINS tap/hold behavior,
      reversers, engine-start selectors, gear controls, trims, PTT, and hat.
- [ ] Save the **ZIBO Linux** profile and make a backup copy after the ground
      test succeeds.
