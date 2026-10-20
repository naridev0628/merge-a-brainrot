--!strict
local MiniEvent = require('../src/shared/MiniEvent')

local function fixed(sample: number): () -> number
    return function() return sample end
end

local function valid(current: number, nextValue: number)
    assert(nextValue % 1 == 0, 'Result must remain integer hundredths')
    assert(nextValue >= 50 and nextValue <= 150, 'Result must remain in the advertised range')
    local difference = math.abs(nextValue - current)
    assert(difference >= 10 and difference <= 30, 'Every update must move by 0.10 to 0.30')
    if current == 50 then assert(nextValue > current, 'Minimum must increase') end
    if current == 150 then assert(nextValue < current, 'Maximum must decrease') end
end

assert(MiniEvent.IntervalSeconds == 90)
assert(MiniEvent.Initial == 100)
assert(MiniEvent.next(100, fixed(0)) == 70)
assert(MiniEvent.next(100, fixed(1)) == 130)
assert(MiniEvent.next(50, fixed(0)) == 60)
assert(MiniEvent.next(50, fixed(1)) == 80)
assert(MiniEvent.next(150, fixed(0)) == 120)
assert(MiniEvent.next(150, fixed(1)) == 140)
print('PASS initial value, 90-second period, RNG endpoints, and inward boundary movement')

-- Every valid current value: each equiprobable RNG bucket reaches one distinct
-- legal result; together the buckets cover all legal outcomes exactly once.
for current = 50, 150 do
    local expected: {[number]: boolean} = {}
    local choiceCount = 0
    for candidate = 50, 150 do
        local difference = math.abs(candidate - current)
        if difference >= 10 and difference <= 30 then
            expected[candidate] = true
            choiceCount += 1
        end
    end
    local visited: {[number]: boolean} = {}
    for bucket = 1, choiceCount do
        local value = MiniEvent.next(current, fixed((bucket - .5) / choiceCount))
        valid(current, value)
        assert(expected[value], 'Unexpected choice')
        assert(not visited[value], 'Uniform buckets must not repeat a choice')
        visited[value] = true
    end
    for value in expected do assert(visited[value], 'Every legal result must be reachable') end
    for _, sample in {-math.huge, -1, 0, .25, .5, .75, 1, 2, math.huge, 0 / 0} do
        valid(current, MiniEvent.next(current, fixed(sample)))
    end
end
print('PASS all 101 current values, uniform legal outcome coverage, and safe RNG clamping')

local seed = 2137
local function random(): number
    seed = (seed * 48271) % 2147483647
    return seed / 2147483647
end
local current = MiniEvent.Initial
for _ = 1, 10000 do
    local nextValue = MiniEvent.next(current, random)
    valid(current, nextValue)
    current = nextValue
end
for _, invalid in {49, 151, 100.5, math.huge, 0 / 0} do
    assert(not pcall(MiniEvent.next, invalid, fixed(.5)), 'Invalid state must be rejected')
end
print('PASS 10,000-update random walk and invalid current-state rejection')
