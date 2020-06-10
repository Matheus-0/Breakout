PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our play state via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores

    self.balls = {params.ball}

    self.ballsCount = 1

    self.level = params.level
    self.recoverPoints = params.recoverPoints
    self.lockedBricksCount = params.lockedBricksCount

    self.powerUpTimer = 1

    self.hasKey = false

    -- Give ball random starting velocity
    self.balls[1].dx = math.random(-200, 200)
    self.balls[1].dy = math.random(-50, -100)

    self.powerUps = {}
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false

            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true

        gSounds['pause']:play()

        return
    end

    -- Power timer logic
    if self.powerUpTimer >= 0 then
        self.powerUpTimer = self.powerUpTimer - dt
    else
        p = PowerUp(
            math.random(0, VIRTUAL_WIDTH - 16),
            self.paddle.y - 100,
            (self.lockedBricksCount > 0) and (not self.hasKey)
        )

        table.insert(self.powerUps, p)

        self.powerUpTimer = 12
    end

    -- Update positions based on velocity
    self.paddle:update(dt)

    -- Update power-ups and check collisions
    for k, power in pairs(self.powerUps) do
        power:update(dt)

        if power:collides(self.paddle) then
            if power.type >= 1 and power.type <= 9 then
                self:powerUpBall()
            elseif power.type == 10 then
                self.hasKey = true

                gSounds['power-up']:play()
            end

            table.remove(self.powerUps, k)
        end
    end

    for k, ball in pairs(self.balls) do
        ball:update(dt)

        if ball:collides(self.paddle) then
            -- Raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- Tweak angle of bounce based on where it hits the paddle
            --

            -- If we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            -- Else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end

        -- Detect collision across all bricks with the ball
        for i, brick in pairs(self.bricks) do
            -- Only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then
                local brickUnlocked = false

                if self.locked then
                    if self.hasKey then
                        self.score = self.score + 1000

                        brickUnlocked = true
                    end
                else
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)
                end

                -- Add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

                -- Trigger the brick's hit function, which removes it from play
                brick:hit(self.hasKey)

                if brickUnlocked then
                    self.hasKey = false
                    self.lockedBricksCount = self.lockedBricksCount - 1
                end

                -- If we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- Can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- Increase size when recovering
                    if self.paddle.size < 4 then
                        self.paddle:resize(self.paddle.size + 1)
                    end

                    -- Multiply recover points by 2
                    self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                    -- Play recover sound effect
                    gSounds['recover']:play()
                end

                -- Go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = ball,
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- Collision code for bricks
                --
                -- We check to see if the opposite side of our velocity is outside of the brick,
                -- if it is, we trigger a collision on that side, else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly
                --

                -- Left edge, only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    -- Flip X velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                -- Right edge, only check if we're moving left and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    -- Flip X velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                -- Top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    -- Flip Y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                -- Bottom edge if no X collisions or top collision, last possibility
                else
                    -- Flip Y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- Slightly scale the Y velocity to speed up the game, capping at +- 150
                -- if math.abs(ball.dy) < 150 then
                --     ball.dy = ball.dy * 1.02
                -- end

                -- Only allow colliding with one brick, for corners
                break
            end
        end

        -- If ball goes below bounds, revert to serve state and decrease health
        if ball.y >= VIRTUAL_HEIGHT then
            if self.ballsCount <= 1 then
                self.health = self.health - 1

                gSounds['hurt']:play()

                if self.paddle.size > 1 then
                    self.paddle:resize(self.paddle.size - 1)
                end

                if self.health == 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints
                    })
                end
            else
                table.remove(self.balls, k)

                self.ballsCount = self.ballsCount - 1
            end
        end
    end

    -- For rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- Render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- Render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    for k, power in pairs(self.powerUps) do
        power:render()
    end

    for k, ball in pairs(self.balls) do
        ball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    PowerUp.renderBar(self.hasKey)

    -- Pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])

        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end

    return true
end

function PlayState:powerUpBall()
    first = Ball(math.random(7))
    second = Ball(math.random(7))

    first.x = self.balls[1].x
    second.x = self.balls[1].x

    first.y = self.balls[1].y
    second.y = self.balls[1].y

    first.dx = self.balls[1].dx
    second.dx = self.balls[1].dx

    first.dy = -math.abs(self.balls[1].dy / 2)
    second.dy = -math.abs(self.balls[1].dy / 4)

    table.insert(self.balls, first)
    table.insert(self.balls, second)

    self.ballsCount = self.ballsCount + 2

    gSounds['power-up']:play()
end
