-- TCA Boeing four-lever throttle averaging for the Zibo 737-800.
-- Version 1.0.0
-- Copyright (c) 2026 Borys Nechypor
-- SPDX-License-Identifier: MIT
--
-- X-Plane assignments:
--   Quadrant Boeing 1&2 left lever  -> Throttle 1
--   Quadrant Boeing 1&2 right lever -> Throttle 2
--   Quadrant Boeing 3&4 left lever  -> Throttle 3
--   Quadrant Boeing 3&4 right lever -> Throttle 4
--
-- The first pair is averaged into Zibo engine 1 and the second pair into
-- Zibo engine 2. This replaces the old Joystick Gremlin + vJoy mapping.

local aircraft_path = string.lower(AIRCRAFT_PATH or "")
local is_zibo_737 = PLANE_ICAO == "B738" and (
    string.find(aircraft_path, "800x", 1, true) ~= nil or
    string.find(aircraft_path, "zibo", 1, true) ~= nil
)

-- Aircraft changes force a FlyWithLua script reload. Avoid binding Zibo-only
-- datarefs in other aircraft (including the Laminar B738).
if not is_zibo_737 then
    logMsg("TCA throttle averaging: inactive outside the Zibo 737-800.")
    return
end

local THROTTLE_1 = 20
local THROTTLE_2 = 21
local THROTTLE_3 = 22
local THROTTLE_4 = 23

local mapped_axis_values = dataref_table("sim/joystick/joy_mapped_axis_value")
local mapped_axis_available = dataref_table("sim/joystick/joy_mapped_axis_avail")

dataref("zibo_avg_thr1", "laminar/B738/axis/throttle1", "writable")
dataref("zibo_avg_thr2", "laminar/B738/axis/throttle2", "writable")
dataref("zibo_avg_override", "laminar/B738/throttle_override", "writable")

local function clamp_throttle(value)
    if value < 0 then
        return 0
    end

    if value > 1 then
        return 1
    end

    return value
end

local function axis_is_ready(index)
    local value = mapped_axis_values[index]

    return mapped_axis_available[index] == 1 and
        type(value) == "number" and
        value == value -- NaN is the only Lua number which is not equal to itself.
end

local function all_throttle_axes_are_ready()
    return axis_is_ready(THROTTLE_1) and
        axis_is_ready(THROTTLE_2) and
        axis_is_ready(THROTTLE_3) and
        axis_is_ready(THROTTLE_4)
end

function tca_release_throttle_override()
    zibo_avg_override = 0
end

function tca_update_mapped_throttle_average()
    if not all_throttle_axes_are_ready() then
        tca_release_throttle_override()
        return
    end

    local engine_1 = (
        clamp_throttle(mapped_axis_values[THROTTLE_1]) +
        clamp_throttle(mapped_axis_values[THROTTLE_2])
    ) / 2
    local engine_2 = (
        clamp_throttle(mapped_axis_values[THROTTLE_3]) +
        clamp_throttle(mapped_axis_values[THROTTLE_4])
    ) / 2

    -- Write valid positions before taking control, preventing a one-frame jump
    -- when all four mapped axes first become available.
    zibo_avg_thr1 = engine_1
    zibo_avg_thr2 = engine_2
    zibo_avg_override = 1
end

do_every_frame("tca_update_mapped_throttle_average()")
do_on_exit("tca_release_throttle_override()")

logMsg(
    "TCA throttle averaging: assign four thrust levers to " ..
    "Throttle 1, 2, 3 and 4 in X-Plane."
)
