Ball = Class{}

function Ball:init(skin)
    -- Simple positional and dimensional variables
    self.width = 8
    self.height = 8

    -- These variables are for keeping track of our velocity on both the X and Y axis
    self.dy = 0
    self.dx = 0

    -- This will effectively be the color of our ball
    self.skin = skin
end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Ball:collides(target)
    -- First, check to see if the left edge of either is farther to the right than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- Then check to see if the bottom edge of either is higher than the top edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- If the above aren't true, they're overlapping
    return true
end

--[[
    Places the ball in the middle of the screen, with no movement.
]]
function Ball:reset()
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 2

    self.dx = 0
    self.dy = 0
end

function Ball:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    -- Allow ball to bounce off walls
    if self.x <= 0 then
        self.x = 0

        self.dx = -self.dx

        if self.dy < 1.5 then
            self.dy = self.dy * 1.05
        end

        gSounds['wall-hit']:play()
    end

    if self.x >= VIRTUAL_WIDTH - 8 then
        self.x = VIRTUAL_WIDTH - 8

        self.dx = -self.dx

        if self.dy < 1.5 then
            self.dy = self.dy * 1.05
        end

        gSounds['wall-hit']:play()
    end

    if self.y <= 0 then
        self.y = 0

        self.dy = -self.dy

        gSounds['wall-hit']:play()
    end
end

function Ball:render()
    love.graphics.draw(gTextures['main'], gFrames['balls'][self.skin], self.x, self.y)
end
