-- WINCTRL 3N PDC L MINS acceleration for the Zibo 737-800
-- Version 1.0.0
-- Copyright (c) 2026 Borys Nechypor
-- SPDX-License-Identifier: MIT
--
-- SimAppPro supplies normal fine movement while the MINS direction button is
-- held. This script adds deterministic acceleration to the captain-side MINS:
--
--   short hold       = SimAppPro fine movement only
--   medium hold      = extra 10 ft steps
--   long hold        = extra 100 ft steps
--
-- Assign the PDC L MINS direction buttons (40 and 42) to the matching
-- PDC_L/EFIS/MINS_*_ACCEL commands created below. Keep the original automatic
-- SimAppPro mapping enabled because it supplies the initial fine movement.

dataref("WINCTRL_TIME", "sim/time/total_running_time_sec")

local mins_slew = {
    value_ref = "laminar/B738/pfd/dh_pilot",

    medium_after = 0.30,
    fast_after   = 1.50,

    medium_step = 10,
    fast_step   = 100,

    medium_interval = 0.18,
    fast_interval   = 0.20,

    press_time = 0,
    last_extra = 0,
    active_dir = 0
}


function winctrl_mins_begin(direction)
    mins_slew.press_time = WINCTRL_TIME
    mins_slew.last_extra = WINCTRL_TIME
    mins_slew.active_dir = direction
end


function winctrl_mins_update(direction)
    if mins_slew.active_dir ~= direction then
        return
    end

    local now = WINCTRL_TIME
    local held_for = now - mins_slew.press_time

    -- Short presses stay fully granular and belong solely to SimAppPro.
    if held_for < mins_slew.medium_after then
        return
    end

    local interval = mins_slew.medium_interval
    local step = mins_slew.medium_step

    if held_for >= mins_slew.fast_after then
        interval = mins_slew.fast_interval
        step = mins_slew.fast_step
    end

    if now - mins_slew.last_extra < interval then
        return
    end

    local value = get(mins_slew.value_ref)
    set(mins_slew.value_ref, value + direction * step)
    mins_slew.last_extra = now
end


function winctrl_mins_end(direction)
    if mins_slew.active_dir ~= direction then
        return
    end

    mins_slew.active_dir = 0
end


create_command(
    "PDC_L/EFIS/MINS_UP_ACCEL",
    "PDC L EFIS Minimums Up Acceleration",
    "winctrl_mins_begin(1)",
    "winctrl_mins_update(1)",
    "winctrl_mins_end(1)"
)

create_command(
    "PDC_L/EFIS/MINS_DOWN_ACCEL",
    "PDC L EFIS Minimums Down Acceleration",
    "winctrl_mins_begin(-1)",
    "winctrl_mins_update(-1)",
    "winctrl_mins_end(-1)"
)
