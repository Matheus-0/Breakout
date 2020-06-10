Brick = Class{}

-- Some of the colors in our palette (to be used with particle systems)
paletteColors = {
    -- Blue
    [1] = {
        ['r'] = 99,
        ['g'] = 155,
        ['b'] = 255
    },
    -- Green
    [2] = {
        ['r'] = 106,
        ['g'] = 190,
        ['b'] = 47
    },
    -- Red
    [3] = {
        ['r'] = 217,
        ['g'] = 87,
        ['b'] = 99
    },
    -- Purple
    [4] = {
        ['r'] = 215,
        ['g'] = 123,
        ['b'] = 186
    },
    -- Gold
    [5] = {
        ['r'] = 251,
        ['g'] = 242,
        ['b'] = 54
    }
}

function Brick:init(x, y, locked)
    -- Used for coloring and score calculation
    self.tier = 0
    self.color = 1

    self.x = x
    self.y = y

    self.width = 32
    self.height = 16

    self.locked = locked

    -- Used to determine whether this brick should be rendered
    self.inPlay = true

    -- Particle system belonging to the brick, emitted on hit
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 64)

    -- Lasts between 0.5 to 1 seconds seconds
    self.psystem:setParticleLifetime(0.5, 1)

    -- Give it an acceleration of anywhere between X1, Y1 and X2, Y2 (0, 0) and (80, 80) here
    -- gives generally downward
    self.psystem:setLinearAcceleration(-15, 0, 15, 80)

    -- Spread of particles, normal looks more natural than uniform
    self.psystem:setAreaSpread('normal', 10, 10)
end

--[[
    Triggers a hit on the brick, taking it out of play if at 0 health or
    changing its color otherwise.
]]
function Brick:hit(key)
    if key and self.locked then
        self.psystem:setParticleLifetime(1, 3)
        self.psystem:setAreaSpread('normal', 15, 15)
        self.psystem:setColors(255, 255, 0, 55, 255, 255, 0, 0)

        self.psystem:emit(1024)

        self.psystem:setParticleLifetime(0.5, 1)
        self.psystem:setAreaSpread('normal', 10, 10)

        gSounds['brick-hit-1']:stop()
        gSounds['brick-hit-1']:play()

        self.locked = false
    elseif self.locked then
        gSounds['wall-hit']:play()
    else
        -- Set the particle system to interpolate between two colors, in this case, we give
        -- it our self.color but with varying alpha, brighter for higher tiers, fading to 0
        -- over the particle's lifetime (the second color)
        self.psystem:setColors(
            paletteColors[self.color].r,
            paletteColors[self.color].g,
            paletteColors[self.color].b,
            55 * (self.tier + 1),
            paletteColors[self.color].r,
            paletteColors[self.color].g,
            paletteColors[self.color].b,
            0
        )

        self.psystem:emit(64)

        -- Sound on hit
        gSounds['brick-hit-2']:stop()
        gSounds['brick-hit-2']:play()

        -- If we're at a higher tier than the base, we need to go down a tier
        -- If we're already at the lowest color, else just go down a color
        if self.tier > 0 then
            if self.color == 1 then
                self.tier = self.tier - 1
                self.color = 5
            else
                self.color = self.color - 1
            end
        else
            -- If we're in the first tier and the base color, remove brick from play
            if self.color == 1 then
                self.inPlay = false
            else
                self.color = self.color - 1
            end
        end

        -- Play a second layer sound if the brick is destroyed
        if not self.inPlay then
            gSounds['brick-hit-1']:stop()
            gSounds['brick-hit-1']:play()
        end
    end
end

function Brick:update(dt)
    self.psystem:update(dt)
end

function Brick:render()
    if self.inPlay then
        if self.locked then
            love.graphics.draw(gTextures['main'], gFrames['bricks'][22], self.x, self.y)
        else
            love.graphics.draw(gTextures['main'],
                -- Multiply color by 4 (-1) to get our color offset, then add tier to that
                -- to draw the correct tier and color brick onto the screen
                gFrames['bricks'][1 + ((self.color - 1) * 4) + self.tier], self.x, self.y
            )
        end
    end
end

--[[
    Need a separate render function for our particles so it can be called after all bricks are drawn,
    otherwise, some bricks would render over other bricks' particle systems.
]]
function Brick:renderParticles()
    love.graphics.draw(self.psystem, self.x + 16, self.y + 8)
end
