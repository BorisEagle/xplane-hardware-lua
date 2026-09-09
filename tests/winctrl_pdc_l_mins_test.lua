-- Run from the repository root: lua tests/winctrl_pdc_l_mins_test.lua
-- FlyWithLua boundary stubs; exercises the registered command callbacks.

        value = 500
        commands = {}
        function dataref(name, ref) _G[name] = 0 end
        function get(ref) return value end
        function set(ref, v) value = v end
        function create_command(name, desc, begin, hold, finish)
            commands[name] = {begin, hold, finish}
        end
    
local path = arg[1] or 'scripts/winwing/winctrl_pdc_l_mins.lua'
for _, direction in ipairs({1, -1}) do
    value = 500
    dofile(path)
    local name = 'PDC_L/EFIS/MINS_' .. (direction == 1 and 'UP' or 'DOWN') .. '_ACCEL'
    local phases = commands[name]
    assert((loadstring or load)(phases[1]))()
    assert(value == 500 + direction, 'tap must immediately move exactly one foot')
    WINCTRL_TIME = 0.29
    assert((loadstring or load)(phases[2]))()
    assert(value == 500 + direction, 'short hold must not accelerate')
    WINCTRL_TIME = 0.31
    assert((loadstring or load)(phases[2]))()
    assert(value == 500 + direction * 11, 'medium stage must add ten feet')
    WINCTRL_TIME = 1.51
    assert((loadstring or load)(phases[2]))()
    assert(value == 500 + direction * 111, 'fast stage must add one hundred feet')
    assert((loadstring or load)(phases[3]))()
    WINCTRL_TIME = 2
    assert((loadstring or load)(phases[2]))()
    assert(value == 500 + direction * 111, 'release must stop movement')
end
print('PASS (' .. _VERSION .. '): up/down taps, short holds, both acceleration stages, release')
