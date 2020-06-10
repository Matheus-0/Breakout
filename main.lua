require 'src/Dependencies'

--[[
    Called just once at the beginning of the game, used to set up
    game objects, variables, and prepare the game world.
]]
function love.load()
    -- Set love's default filter to "nearest neighbor"
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- Seed the RNG so that calls to random are always random
    math.randomseed(os.time())

    -- Set the application title bar
    love.window.setTitle('Breakout')

    -- Initialize our nice-looking retro text fonts
    gFonts = {
        ['small'] = love.graphics.newFont('fonts/font.ttf', 8),
        ['medium'] = love.graphics.newFont('fonts/font.ttf', 16),
        ['large'] = love.graphics.newFont('fonts/font.ttf', 32)
    }

    love.graphics.setFont(gFonts['small'])

    -- Load up the graphics we'll be using throughout our states
    gTextures = {
        ['background'] = love.graphics.newImage('graphics/background.png'),
        ['main'] = love.graphics.newImage('graphics/breakout.png'),
        ['arrows'] = love.graphics.newImage('graphics/arrows.png'),
        ['hearts'] = love.graphics.newImage('graphics/hearts.png'),
        ['particle'] = love.graphics.newImage('graphics/particle.png')
    }

    -- Quads we will generate for all of our textures, they allow us
    -- to show only part of a texture and not the entire thing
    gFrames = {
        ['arrows'] = GenerateQuads(gTextures['arrows'], 24, 24),
        ['paddles'] = GenerateQuadsPaddles(gTextures['main']),
        ['balls'] = GenerateQuadsBalls(gTextures['main']),
        ['bricks'] = GenerateQuadsBricks(gTextures['main']),
        ['hearts'] = GenerateQuads(gTextures['hearts'], 10, 9),
        ['power-ups'] = GenerateQuadsPowerUps(gTextures['main'])
    }

    -- Initialize our virtual resolution, which will be rendered within our
    -- actual window no matter its dimensions
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true
    })

    -- Set up our sound effects, later, we can just index this table and
    -- call each entry's `play` method
    gSounds = {
        ['paddle-hit'] = love.audio.newSource('sounds/paddle-hit.wav'),
        ['score'] = love.audio.newSource('sounds/score.wav'),
        ['wall-hit'] = love.audio.newSource('sounds/wall-hit.wav'),
        ['confirm'] = love.audio.newSource('sounds/confirm.wav'),
        ['select'] = love.audio.newSource('sounds/select.wav'),
        ['no-select'] = love.audio.newSource('sounds/no-select.wav'),
        ['brick-hit-1'] = love.audio.newSource('sounds/brick-hit-1.wav'),
        ['brick-hit-2'] = love.audio.newSource('sounds/brick-hit-2.wav'),
        ['hurt'] = love.audio.newSource('sounds/hurt.wav'),
        ['victory'] = love.audio.newSource('sounds/victory.wav'),
        ['recover'] = love.audio.newSource('sounds/recover.wav'),
        ['high-score'] = love.audio.newSource('sounds/high-score.wav'),
        ['pause'] = love.audio.newSource('sounds/pause.wav'),
        ['power-up'] = love.audio.newSource('sounds/power-up.wav'),
        -- Music
        ['music'] = love.audio.newSource('sounds/music.wav')
    }

    -- The state machine we'll be using to transition between various states
    -- in our game instead of clumping them together in our update and draw
    -- methods
    gStateMachine = StateMachine {
        ['start'] = function () return StartState() end,
        ['play'] = function () return PlayState() end,
        ['serve'] = function () return ServeState() end,
        ['game-over'] = function () return GameOverState() end,
        ['victory'] = function () return VictoryState() end,
        ['high-scores'] = function () return HighScoreState() end,
        ['enter-high-score'] = function () return EnterHighScoreState() end,
        ['paddle-select'] = function () return PaddleSelectState() end
    }

    gStateMachine:change('start', {
        highScores = loadHighScores()
    })

    -- Play our music outside of all states and set it to looping
    gSounds['music']:play()
    gSounds['music']:setLooping(true)

    -- A table we'll use to keep track of which keys have been pressed this
    -- frame, to get around the fact that LÖVE's default callback won't let us
    -- test for input from within other functions
    love.keyboard.keysPressed = {}
end

--[[
    Called whenever we change the dimensions of our window, as by dragging
    out its bottom corner, for example. In this case, we only need to worry
    about calling out to `push` to handle the resizing. Takes in a `w` and
    `h` variable representing width and height, respectively.
]]
function love.resize(w, h)
    push:resize(w, h)
end

--[[
    Called every frame, passing in `dt` since the last frame. `dt`
    is short for 'delta time' and is measured in seconds. Multiplying
    this by any changes we wish to make in our game will allow our
    game to perform consistently across all hardware, otherwise, any
    changes we make will be applied as fast as possible and will vary
    across system hardware.
]]
function love.update(dt)
    -- This time, we pass in dt to the state object we're currently using
    gStateMachine:update(dt)

    -- Reset keys pressed
    love.keyboard.keysPressed = {}
end

--[[
    A callback that processes key strokes as they happen, just the once.
    Does not account for keys that are held down, which is handled by a
    separate function (`love.keyboard.isDown`). Useful for when we want
    things to happen right away, just once, like when we want to quit.
]]
function love.keypressed(key)
    -- Add to our table of keys pressed this frame
    love.keyboard.keysPressed[key] = true
end

--[[
    A custom function that will let us test for individual keystrokes outside
    of the default `love.keypressed` callback, since we can't call that logic
    elsewhere by default.
]]
function love.keyboard.wasPressed(key)
    if love.keyboard.keysPressed[key] then
        return true
    else
        return false
    end
end

--[[
    Called each frame after update, is responsible simply for
    drawing all of our game objects and more to the screen.
]]
function love.draw()
    -- Begin drawing with push, in our virtual resolution
    push:apply('start')

    -- Background should be drawn regardless of state, scaled to fit our
    -- virtual resolution
    local backgroundWidth = gTextures['background']:getWidth()
    local backgroundHeight = gTextures['background']:getHeight()

    love.graphics.draw(
        gTextures['background'],
        -- Draw at coordinates 0, 0
        0, 0,
        -- No rotation
        0,
        -- Scale factors on X and Y axis so it fills the screen
        VIRTUAL_WIDTH / (backgroundWidth - 1), VIRTUAL_HEIGHT / (backgroundHeight - 1)
    )

    -- Use the state machine to defer rendering to the current state we're in
    gStateMachine:render()

    -- Display FPS for debugging, simply comment out to remove
    displayFPS()

    push:apply('end')
end

--[[
    Loads high scores from a .lst file, saved in LÖVE2D's default save directory in a subfolder
    called 'breakout'.
]]
function loadHighScores()
    love.filesystem.setIdentity('breakout')

    -- If the file doesn't exist, initialize it with some default scores
    if not love.filesystem.exists('breakout.lst') then
        local scores = ''

        for i = 10, 1, -1 do
            scores = scores .. 'CTO\n'
            scores = scores .. tostring(i * 1000) .. '\n'
        end

        love.filesystem.write('breakout.lst', scores)
    end

    -- Flag for whether we're reading a name or not
    local name = true
    local currentName = nil

    local counter = 1

    -- Initialize scores table with at least 10 blank entries
    local scores = {}

    for i = 1, 10 do
        -- Blank table, each will hold a name and a score
        scores[i] = {
            name = nil,
            score = nil
        }
    end

    -- Iterate over each line in the file, filling in names and scores
    for line in love.filesystem.lines('breakout.lst') do
        if name then
            scores[counter].name = string.sub(line, 1, 3)
        else
            scores[counter].score = tonumber(line)

            counter = counter + 1
        end

        -- Flip the name flag
        name = not name
    end

    return scores
end

--[[
    Renders hearts based on how much health the player has. First renders
    full hearts, then empty hearts for however much health we're missing.
]]
function renderHealth(health)
    -- Start of our health rendering
    local healthX = VIRTUAL_WIDTH - 100

    -- Render health left
    for i = 1, health do
        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][1], healthX, 4)

        healthX = healthX + 11
    end

    -- Render missing health
    for i = 1, 3 - health do
        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][2], healthX, 4)

        healthX = healthX + 11
    end
end

--[[
    Renders the current FPS.
]]
function displayFPS()
    -- Simple FPS display across all states
    love.graphics.setFont(gFonts['small'])

    love.graphics.setColor(0, 255, 0, 255)

    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 5, 5)
end

--[[
    Simply renders the player's score at the top right, with left-side padding
    for the score number.
]]
function renderScore(score)
    love.graphics.setFont(gFonts['small'])

    love.graphics.print('Score:', VIRTUAL_WIDTH - 60, 5)

    love.graphics.printf(tostring(score), VIRTUAL_WIDTH - 50, 5, 40, 'right')
end
