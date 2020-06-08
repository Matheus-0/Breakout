-- Push library
push = require 'lib/push'

-- Class library
Class = require 'lib/class'

-- A few global constants, centralized
require 'src/constants'

-- The ball that travels around, breaking bricks and triggering lives lost
require 'src/Ball'

-- The entities in our game map that give us points when we collide with them
require 'src/Brick'

-- A class used to generate our brick layouts (levels)
require 'src/LevelMaker'

-- The rectangular entity the player controls, which deflects the ball
require 'src/Paddle'

-- A basic class which will allow us to transition to and from game states
require 'src/StateMachine'

-- Utility functions, mainly for splitting our sprite sheet for paddles, balls, bricks, etc.
require 'src/Util'

-- Each of the individual states our game can be in at once
require 'src/states/BaseState'
require 'src/states/EnterHighScoreState'
require 'src/states/GameOverState'
require 'src/states/HighScoreState'
require 'src/states/PaddleSelectState'
require 'src/states/PlayState'
require 'src/states/ServeState'
require 'src/states/StartState'
require 'src/states/VictoryState'
