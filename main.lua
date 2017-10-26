bump = require 'libs.bump.bump'

-- Declare the world and boundaries objects
world = nil -- storage place for bump
ground_0 = {}
ground_1 = {}

function love.load()
  -- Set up the world
  world = bump.newWorld(16)  -- 16 is our tile size

  -- Set the background
  bg = love.graphics.newImage('assets/bg/background-1.png')

  -- Create the player
  player.img = love.graphics.newImage('assets/characters/player.png')
  -- Add the player to the world
  world:add(player, player.x, player.y, player.img:getWidth(), player.img:getHeight())

  -- Draw a level
  world:add(ground_0, 120, 360, 640, 16)
  world:add(ground_1, 0, 448, 640, 32)

  -- Set up the music and play it
  music = love.audio.newSource('assets/music/theme-1.ogg')
  love.audio.play(music)
end

function love.update(dt)
  local goalX = player.x + player.xVelocity
  local goalY = player.y + player.yVelocity

  -- Apply Friction
  player.xVelocity = player.xVelocity * (1 - math.min(dt * player.friction, 1))
  player.yVelocity = player.yVelocity * (1 - math.min(dt * player.friction, 1))

  player.x, player.y, collisions, len = world:move(player, goalX, goalY, player.filter)

  -- Function that allow the player to pass the platform from below, but not above
  player.filter = function(item, other)
    local x, y, w, h = world:getRect(other)
    local px, py, pw, ph = world:getRect(item)
    local playerBottom = py + ph
    local otherBottom = y + h

    if playerBottom <= y then
      return 'slide'
    end
  end

  -- Apply gravity
  player.yVelocity = player.yVelocity + player.gravity * dt

	if love.keyboard.isDown("left", "a") and player.xVelocity > -player.maxSpeed then
    player.direction = -1
		player.xVelocity = player.xVelocity - player.acc * dt
	elseif love.keyboard.isDown("right", "d") and player.xVelocity < player.maxSpeed then
    player.direction = 1
		player.xVelocity = player.xVelocity + player.acc * dt
	end

  -- The Jump code gets a lttle bit crazy.  Bare with me.
  if love.keyboard.isDown("up", "w") then
    if -player.yVelocity < player.jumpMaxSpeed and not player.hasReachedMax then
      player.yVelocity = player.yVelocity - player.jumpAcc * dt
    elseif math.abs(player.yVelocity) > player.jumpMaxSpeed then
      player.hasReachedMax = true
    end

    player.isGrounded = false -- we are no longer in contact with the ground
  end

  for i, coll in ipairs(collisions) do
    if coll.touch.y > goalY then
      player.hasReachedMax = true
      player.isGrounded = false
    elseif coll.normal.y < 0 then
      player.hasReachedMax = false
      player.isGrounded = true
    end
  end

end

function love.keypressed(key)
  if key == "escape" then
    love.event.push("quit")
  end
end

function love.draw(dt)
  love.graphics.draw(bg, 0, 0)
  love.graphics.rectangle('fill', world:getRect(ground_0))
  love.graphics.rectangle('fill', world:getRect(ground_1))
  love.graphics.draw(player.img, player.x, player.y)
end

-- The finished player object
player = {
  x = 16,
  y = 16,
  -- The first set of values are for our rudimentary physics system
  xVelocity = 0, -- current velocity on x, y axes
  yVelocity = 0,
  acc = 100, -- the acceleration of our player
  maxSpeed = 600, -- the top speed
  friction = 20, -- slow our player down - we could toggle this situationally to create icy or slick platforms
  gravity = 80, -- we will accelerate towards the bottom
  direction = 1, -- Sprite facing or direction

  -- These are values applying specifically to jumping
  isJumping = false, -- are we in the process of jumping?
  isGrounded = false, -- are we on the ground?
  hasReachedMax = false, -- is this as high as we can go?
  jumpAcc = 500, -- how fast do we accelerate towards the top
  jumpMaxSpeed = 9.5, -- our speed limit while jumping

  -- Here are some incidental storage areas
  img = nil -- store the sprite we'll be drawing
}
