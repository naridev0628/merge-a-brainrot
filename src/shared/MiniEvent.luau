--!strict
-- Pure server-event rule, expressed in hundredths to avoid multiplier drift.
local MiniEvent = {
    IntervalSeconds = 90,
    Minimum = 50,
    Maximum = 150,
    Initial = 100,
}

function MiniEvent.next(currentHundredths: number, random: () -> number): number
    assert(currentHundredths % 1 == 0 and currentHundredths >= MiniEvent.Minimum and currentHundredths <= MiniEvent.Maximum, 'Multiplier must be an integer from 50 to 150')
    local choices: {number} = {}
    for delta = -30, 30 do
        local nextValue = currentHundredths + delta
        if math.abs(delta) >= 10 and nextValue >= MiniEvent.Minimum and nextValue <= MiniEvent.Maximum then
            table.insert(choices, nextValue)
        end
    end
    -- An inclusive 1 must select the final bucket, not index past the array.
    -- Out-of-range/NaN RNG samples are also harmless for injected generators.
    local sample = random()
    if sample ~= sample then sample = 0 end
    sample = math.clamp(sample, 0, 1)
    local index = math.min(#choices, math.floor(sample * #choices) + 1)
    return choices[index]
end

return MiniEvent
