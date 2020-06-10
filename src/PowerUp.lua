PowerUp = Class{}

function PowerUp:init(x, y, valid)
    self.x = x
    self.y = y

    self.dx = 0
    self.dy = 0

    self.width = 16
    self.height = 16

    if valid then
        self.type = 10
    else
        self.type = math.random(1, 9)
    end

    self.collided = false

    self.blinkTimer = 0
    self.startTimer = 0

    self.visible = true
end

function PowerUp:update(dt)
    if self.startTimer < 3.5 then
        self.startTimer = self.startTimer + dt
        self.blinkTimer = self.blinkTimer + dt

        if self.blinkTimer > 0.5 then
            self.blinkTimer = self.blinkTimer - 0.5

            self.visible = not self.visible
        end
    else
        self.visible = true

        self.y = self.y + 1
    end
end

function PowerUp:collides(target)
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end

    return true
end

function PowerUp:render()
    if self.visible then
        love.graphics.draw(gTextures['main'], gFrames['power-ups'][self.type], self.x, self.y)
    end
end

function PowerUp:renderBar(key)
    local x = 4
    local y = VIRTUAL_HEIGHT - 20

    if key then
        love.graphics.draw(gTextures['main'], gFrames['power-ups'][10], x, y)
    end
end
