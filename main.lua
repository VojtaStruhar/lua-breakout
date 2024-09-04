Settings = {
    player_speed = 8,
    ball_speed = 5,

    block_rows = 3,
    block_cols = 8,

    block_height = 15,
    block_offset_x = 30,
    block_offset_y = 80,
    block_gap = 5,

    collision_margin = 2 -- kinda tied to ball radius lol
}

-- represenets the player-controlled paddle
Player = {
    x = 0,
    y = 0,
    width = 100,
    height = 10,
    moving_left = false,
    moving_right = false,
    -- Returns 2 values, x and y!
    getCenter = function()
        return Player.x + Player.width / 2, Player.y + Player.height / 2
    end
}


Game = {
    ball = {
        position = { x = 0, y = 0 },
        velocity = { dx = 0, dy = 0 },
        radius = 5
    },
    score = 0,
    -- Array of breakable blocks, generated on load!
    blocks = {},
    is_playing = true,
}

Assets = {}

function love.load()
    Assets.jirka = love.graphics.newImage("jirka.png")
    Assets.impact = love.audio.newSource("impact.ogg", "static")
    Assets.impact_wall = love.audio.newSource("impact_wall.ogg", "static")
    Assets.impact_player = love.audio.newSource("impact_player.ogg", "static")

    setupGame()
end

function love.update()
    if Game.is_playing == false then
        return
    end

    if Player.moving_left then
        Player.x = Player.x - Settings.player_speed
    end
    if Player.moving_right then
        Player.x = Player.x + Settings.player_speed
    end

    local b = Game.ball

    -- move ball
    b.position.x = b.position.x + b.velocity.dx
    b.position.y = b.position.y + b.velocity.dy

    -- Check wall collisions
    if b.position.x <= Settings.collision_margin then
        b.velocity.dx = -b.velocity.dx
        Assets.impact_wall:stop()
        Assets.impact_wall:play()
    end
    if b.position.x >= love.graphics.getWidth() - Settings.collision_margin then
        b.velocity.dx = -b.velocity.dx
        Assets.impact_wall:stop()
        Assets.impact_wall:play()
    end
    if b.position.y <= Settings.collision_margin then
        -- ceiling hit
        b.velocity.dy = -b.velocity.dy
        Assets.impact_wall:stop()
        Assets.impact_wall:play()
    end

    -- player collision
    if checkCollision(Player, Game.ball) then
        Assets.impact_player:play()
        b.velocity.dy = -b.velocity.dy
        local cx, cy = Player.getCenter()
        local distance_from_center = b.position.x - cx
        Game.ball.velocity.dx = (distance_from_center / (Player.width / 2)) * Settings.ball_speed
    end


    -- Check box collisions
    for _, block in ipairs(Game.blocks) do
        if block.active then
            local dist_x = block.x - b.position.x
            local dist_y = block.y - b.position.y
            if checkCollision(block, Game.ball) then
                block.active = false
                Assets.impact:stop()
                Assets.impact:play()

                Game.score = Game.score + 1

                -- block hit horizontal
                if b.position.x > (block.x + block.width) or b.position.x < block.x then
                    b.velocity.dx = -b.velocity.dx
                else -- b.position.y > (block.y + block.height) or b.position.y < block.y then
                    b.velocity.dy = -b.velocity.dy
                end
            end
        end
    end

    -- GAME OVER
    if b.position.y > love.graphics.getHeight() then
        love.event.quit(0)
    end

    -- WIN GAME??
    if Game.score == #Game.blocks then
        Game.is_playing = false
    end
end

function love.draw()
    if Game.is_playing == false then
        love.graphics.clear(0.1, 0.9, 0.3, 1)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print("YOU WON! GOOD JOB!", love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
        love.graphics.print(
            "Press space to play again", love.graphics.getWidth() / 2, (love.graphics.getHeight() / 2) + 30
        )
        love.graphics.setColor(255, 255, 255, 255) -- white?
        love.graphics.draw(Assets.jirka,
            (love.graphics.getWidth() / 2) - 150,
            (love.graphics.getHeight() / 2) - 70)

        return
    end
    love.graphics.setColor(1, 1, 1, 1) -- white
    love.graphics.clear()

    love.graphics.print("Score: " .. tostring(Game.score), 10, 10)

    love.graphics.rectangle("fill", Player.x, Player.y, Player.width, Player.height)

    -- draw the ball
    love.graphics.circle("fill", Game.ball.position.x, Game.ball.position.y, Game.ball.radius)

    -- draw the blocks
    for _, block in ipairs(Game.blocks) do
        if block.active then
            love.graphics.setColor(block.color.r, block.color.g, block.color.b)
            love.graphics.rectangle("fill", block.x, block.y, block.width, block.height, 4, 4)
        end
    end
end

-- INPUT HANDLING

function love.keypressed(key)
    if key == "left" or key == "a" then
        Player.moving_left = true
    end
    if key == "right" or key == "d" then
        Player.moving_right = true
    end
end

function love.keyreleased(key)
    if key == "left" or key == "a" then
        Player.moving_left = false
    end
    if key == "right" or key == "d" then
        Player.moving_right = false
    end

    if Game.is_playing == false and key == "space" then
        resetGame()
        Game.is_playing = true
    end
end

-- UTILS

function checkCollision(box, ball)
    local closestX = math.max(box.x, math.min(ball.position.x, box.x + box.width))
    local closestY = math.max(box.y, math.min(ball.position.y, box.y + box.height))

    local distanceX = ball.position.x - closestX
    local distanceY = ball.position.y - closestY

    local distanceSquared = (distanceX * distanceX) + (distanceY * distanceY)

    return distanceSquared < (ball.radius * ball.radius)
end

function setupGame()
    -- place the player
    Player.x = love.graphics.getWidth() / 2
    Player.y = love.graphics.getHeight() - 30

    -- place the ball
    local px, py = Player.getCenter()
    Game.ball.position.x = px
    Game.ball.position.y = py - Player.height
    Game.ball.velocity.dx = (love.math.random() - 0.5) * Settings.ball_speed
    Game.ball.velocity.dy = -Settings.ball_speed

    -- Setup block variables
    local cur_x = Settings.block_offset_x
    local cur_y = Settings.block_offset_y
    local gap = Settings.block_gap
    local block_width = (love.graphics.getWidth() - cur_x * 2 - gap * (Settings.block_cols - 1)) / Settings.block_cols
    -- Generate the actual blocks
    for row = 1, Settings.block_rows do
        for col = 1, Settings.block_cols do
            table.insert(Game.blocks, {
                x = cur_x,
                y = cur_y,
                width = block_width,
                height = Settings.block_height,
                color = {
                    r = math.max(love.math.random(), 0.2),
                    g = math.max(love.math.random(), 0.2),
                    b = math.max(love.math.random(), 0.2)
                },
                active = true -- This is turned off when a box is hit
            })
            cur_x = cur_x + block_width + gap
        end
        cur_y = cur_y + Settings.block_height + gap
        cur_x = Settings.block_offset_x
    end
end

function resetGame()
    -- Remove all blocks
    for k in pairs(Game.blocks) do
        Game.blocks[k] = nil
    end
    -- reset score
    Game.score = 0

    -- Reload
    setupGame()
end
