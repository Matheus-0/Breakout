-- Global patterns (used to make the entire map a certain shape)
NONE = 1
SINGLE_PYRAMID = 2
MULTI_PYRAMID = 3

-- Per row patterns

-- All colors the same in this row
SOLID = 1
-- Alternate colors
ALTERNATE = 2
-- Skip every other block
SKIP = 3
-- No blocks this row
NONE = 4

LevelMaker = Class{}

--[[
    Creates a table of bricks to be returned to the main game, with different
    possible ways of randomising rows and columns of bricks. Calculates the
    brick colors and tiers to choose based on the level passed in.
]]
function LevelMaker.createMap(level)
    local bricks = {}

    -- Randomly choose the number of rows
    local numRows = math.random(1, 5)

    -- Randomly choose the number of columns, ensuring odd
    local numCols = math.random(7, 13)

    numCols = numCols % 2 == 0 and (numCols + 1) or numCols

    -- Highest possible spawned brick color in this level, ensure we don't go above 3
    local highestTier = math.min(3, math.floor(level / 5))

    -- Highest color of the highest tier, no higher than 5
    local highestColor = math.min(5, level % 5 + 3)

    -- Lay out bricks such that they touch each other and fill the space
    for y = 1, numRows do
        -- Whether we want to enable skipping for this row
        local skipPattern = math.random(1, 2) == 1 and true or false

        -- Whether we want to enable alternating colors for this row
        local alternatePattern = math.random(1, 2) == 1 and true or false

        -- Choose two colors to alternate between
        local alternateColor1 = math.random(1, highestColor)
        local alternateColor2 = math.random(1, highestColor)
        local alternateTier1 = math.random(0, highestTier)
        local alternateTier2 = math.random(0, highestTier)

        -- Used only when we want to skip a block, for skip pattern
        local skipFlag = math.random(2) == 1 and true or false

        -- Used only when we want to alternate a block, for alternate pattern
        local alternateFlag = math.random(2) == 1 and true or false

        -- Solid color we'll use if we're not skipping or alternating
        local solidColor = math.random(1, highestColor)
        local solidTier = math.random(0, highestTier)

        for x = 1, numCols do
            -- If skipping is turned on and we're on a skip iteration...
            if skipPattern and skipFlag then
                -- Turn skipping off for the next iteration
                skipFlag = not skipFlag

                -- Lua doesn't have a continue statement, so this is the workaround
                goto continue
            else
                -- Flip the flag to true on an iteration we don't use it
                skipFlag = not skipFlag
            end

            local lockBrick = false

            if math.random(0, math.max(50 / level, 5)) <= 1 then
                lockBrick = true
            end

            --[[
                X coordinate:
                - Decrement x by 1 because tables are 1-indexed, coordinates are 0
                - Multiply by 32, the brick width
                - The screen should have 8 pixels of padding, we can fit 13 columns + 16 pixels total
                - Left side padding for when there are fewer than 13 columns
            ]]

            --[[
                Y coordinate:
                - Just use y * 16, since we need top padding anyway
            ]]

            b = Brick((x-1) * 32 + 8 + (13 - numCols) * 16, y * 16, lockBrick)

            lockBrick = false

            -- If we're alternating, figure out which color/tier we're on
            if alternatePattern and alternateFlag then
                b.color = alternateColor1
                b.tier = alternateTier1

                alternateFlag = not alternateFlag
            else
                b.color = alternateColor2
                b.tier = alternateTier2

                alternateFlag = not alternateFlag
            end

            -- If not alternating and we made it here, use the solid color/tier
            if not alternatePattern then
                b.color = solidColor
                b.tier = solidTier
            end

            table.insert(bricks, b)

            -- Lua's version of the 'continue' statement
            ::continue::
        end
    end 

    -- In the event we didn't generate any bricks, try again
    if #bricks == 0 then
        return self.createMap(level)
    else
        return bricks
    end
end
