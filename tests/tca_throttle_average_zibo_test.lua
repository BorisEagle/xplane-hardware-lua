-- Run from the repository root:
-- lua tests/tca_throttle_average_zibo_test.lua
-- FlyWithLua boundary stubs; exercises the registered frame and exit callbacks.

local mapped_axis_values = {}
local mapped_axis_available = {}
local physical_axis_assignments = {}
local physical_axis_values = {}
local physical_axis_reverse = {}
local read_past_physical_axis_limit = false
local registered_frame_callback = nil
local registered_exit_callback = nil

local function bounded_physical_axis_table(values)
    return setmetatable({}, {
        __index = function(_, index)
            if index < 0 or index > 499 then
                read_past_physical_axis_limit = true
                error("physical axis index out of range: " .. tostring(index))
            end

            return values[index]
        end,
        __newindex = function(_, index, value)
            if index < 0 or index > 499 then
                error("physical axis index out of range: " .. tostring(index))
            end

            values[index] = value
        end,
    })
end

local joystick_axis_assignments =
    bounded_physical_axis_table(physical_axis_assignments)
local joystick_axis_values = bounded_physical_axis_table(physical_axis_values)
local joystick_axis_reverse = bounded_physical_axis_table(physical_axis_reverse)

PLANE_ICAO = "B738"
AIRCRAFT_PATH = "/Aircraft/B737-800X/"

function dataref_table(path)
    if path == "sim/joystick/joy_mapped_axis_value" then
        return mapped_axis_values
    end

    if path == "sim/joystick/joy_mapped_axis_avail" then
        return mapped_axis_available
    end

    if path == "sim/joystick/joystick_axis_assignments" then
        return joystick_axis_assignments
    end

    if path == "sim/joystick/joystick_axis_values" then
        return joystick_axis_values
    end

    if path == "sim/joystick/joystick_axis_reverse" then
        return joystick_axis_reverse
    end

    error("unexpected dataref table: " .. path)
end

function dataref(variable, path, access)
    local expected = {
        zibo_avg_thr1 = "laminar/B738/axis/throttle1",
        zibo_avg_thr2 = "laminar/B738/axis/throttle2",
        zibo_avg_override = "laminar/B738/throttle_override",
    }

    assert(expected[variable] == path, "unexpected scalar dataref: " .. path)
    assert(access == "writable", path .. " must be writable")
    _G[variable] = 0
end

function do_every_frame(callback)
    registered_frame_callback = callback
end

function do_on_exit(callback)
    registered_exit_callback = callback
end

function logMsg(_) end

local function assert_near(actual, expected, message)
    assert(math.abs(actual - expected) < 0.000001, message)
end

-- Regression: on a two-engine aircraft X-Plane can leave mapped Throttle 3/4
-- unavailable even though four physical axes are assigned. The script must
-- discover those physical slots, as the former Gremlin/vJoy chain did.
mapped_axis_available[20] = 1
mapped_axis_available[21] = 1
mapped_axis_available[22] = 0
mapped_axis_available[23] = 0
mapped_axis_values[20] = 0.20
mapped_axis_values[21] = 0.60
mapped_axis_values[22] = 0.40
mapped_axis_values[23] = 1.00

joystick_axis_assignments[7] = 20
joystick_axis_assignments[8] = 21
joystick_axis_assignments[13] = 22
joystick_axis_assignments[14] = 23
joystick_axis_values[7] = 0.20
joystick_axis_values[8] = 0.60
joystick_axis_values[13] = 0.40
joystick_axis_values[14] = 1.00
joystick_axis_reverse[7] = 0
joystick_axis_reverse[8] = 0
joystick_axis_reverse[13] = 0
joystick_axis_reverse[14] = 0

local path = (arg and arg[1]) or
    "scripts/thrustmaster/tca_throttle_average_zibo.lua"
dofile(path)

assert(
    not read_past_physical_axis_limit,
    "physical-axis discovery must stay within X-Plane's 0..499 array"
)
assert(
    registered_frame_callback == "tca_update_throttle_average()",
    "the averaging handler must run every frame"
)
assert(
    registered_exit_callback == "tca_release_throttle_override()",
    "the Zibo throttle override must be released when the script exits"
)

tca_update_throttle_average()

assert(zibo_avg_override == 1, "four assigned axes must enable the override")
assert_near(zibo_avg_thr1, 0.40, "engine 1 must average Throttle 1 and 2")
assert_near(zibo_avg_thr2, 0.70, "engine 2 must average Throttle 3 and 4")

-- X-Plane stores reversal separately from the raw physical values. Apply it
-- before averaging so the script follows each axis's Reverse checkbox.
joystick_axis_reverse[7] = 1
joystick_axis_values[7] = 0.20
joystick_axis_values[8] = 0.60
tca_update_throttle_average()

assert_near(zibo_avg_thr1, 0.70, "reversed axes must be inverted before averaging")
joystick_axis_reverse[7] = 0

-- Clamp each physical input before averaging, protecting Zibo from bad values.
joystick_axis_values[7] = -0.50
joystick_axis_values[8] = 1.50
joystick_axis_values[13] = 0.20
joystick_axis_values[14] = 0.60
tca_update_throttle_average()

assert_near(zibo_avg_thr1, 0.50, "engine 1 inputs must be clamped")
assert_near(zibo_avg_thr2, 0.40, "valid engine 2 inputs must remain unchanged")

-- A corrupt non-number-like value must fail safe instead of reaching Zibo.
joystick_axis_values[7] = 0 / 0
local before_nan_thr1 = zibo_avg_thr1
local before_nan_thr2 = zibo_avg_thr2
tca_update_throttle_average()

assert(zibo_avg_override == 0, "NaN input must release the override")
assert_near(zibo_avg_thr1, before_nan_thr1, "NaN must not change engine 1")
assert_near(zibo_avg_thr2, before_nan_thr2, "NaN must not change engine 2")

-- X-Plane uses -0.01 while an assigned physical axis has no usable reading.
joystick_axis_values[7] = -0.01
tca_update_throttle_average()
assert(zibo_avg_override == 0, "the dead-axis marker must release the override")

-- If any of the four assignments disappears, release control and keep the
-- last outputs untouched instead of commanding an incomplete throttle pair.
joystick_axis_values[7] = 0.20
joystick_axis_assignments[13] = 0
local last_thr1 = zibo_avg_thr1
local last_thr2 = zibo_avg_thr2
tca_update_throttle_average()

assert(zibo_avg_override == 0, "a missing assigned axis must release the override")
assert_near(zibo_avg_thr1, last_thr1, "missing axes must not change engine 1")
assert_near(zibo_avg_thr2, last_thr2, "missing axes must not change engine 2")

-- Assignments can appear after FlyWithLua loads (for example after the user
-- selects the device profile). Rediscovery must recover without a reload, and
-- slot 499 verifies the inclusive upper bound.
joystick_axis_assignments[499] = 22
joystick_axis_values[499] = 0.80
joystick_axis_reverse[499] = 0
for _ = 1, 61 do
    tca_update_throttle_average()
end

assert(zibo_avg_override == 1, "late axis assignments must be rediscovered")
assert_near(zibo_avg_thr2, 0.70, "slot 499 must be included in discovery")
assert(
    not read_past_physical_axis_limit,
    "rediscovery must stay within X-Plane's 0..499 array"
)

zibo_avg_override = 1
tca_release_throttle_override()
assert(zibo_avg_override == 0, "the exit callback must release the override")

print("PASS (" .. _VERSION .. "): averaging, clamping, fail-safe, shutdown")
