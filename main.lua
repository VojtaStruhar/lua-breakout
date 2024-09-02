player = {
    position = { x = 0, y = 0 },
    width = 100,
    height = 10,
    moving_left = false,
    moving_right = false,
    -- Returns 2 values, x and y!
    getCenter = function()
        return player.position.x + player.width / 2, player.position.y + player.height / 2
    end
}

settings = {
    player_speed = 8,
    ball_speed = 5,

    block_rows = 1,
    block_cols = 3,

    block_height = 15,
    block_offset_x = 30,
    block_offset_y = 80,
    block_gap = 5,

    collision_margin = 2 -- kinda tied to ball radius lol
}

game = {
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

media = {}

function love.load()
    media.jirka = love.graphics.newImage("jirka.png")
    media.impact = love.audio.newSource("impact.ogg", "static")
    media.impact_wall = love.audio.newSource("impact_wall.ogg", "static")
    media.impact_player = love.audio.newSource("impact_player.ogg", "static")

    -- place the player
    player.position.x = love.graphics.getWidth() / 2
    player.position.y = love.graphics.getHeight() - 30

    -- place the ball
    local px, py = player.getCenter()
    game.ball.position.x = px
    game.ball.position.y = py - player.height
    game.ball.velocity.dx = (love.math.random() - 0.5) * settings.ball_speed
    game.ball.velocity.dy = -settings.ball_speed

    -- Setup block variables
    local cur_x = settings.block_offset_x
    local cur_y = settings.block_offset_y
    local gap = settings.block_gap
    local block_width = (love.graphics.getWidth() - cur_x * 2 - gap * (settings.block_cols - 1)) / settings.block_cols
    -- Generate the actual blocks
    for row = 1, settings.block_rows do
        for col = 1, settings.block_cols do
            table.insert(game.blocks, {
                x = cur_x,
                y = cur_y,
                width = block_width,
                height = settings.block_height,
                color = {
                    r = math.max(love.math.random(), 0.2),
                    g = math.max(love.math.random(), 0.2),
                    b = math.max(love.math.random(), 0.2)
                },
                active = true -- This is turned off when a box is hit
            })
            cur_x = cur_x + block_width + gap
        end
        cur_y = cur_y + settings.block_height + gap
        cur_x = settings.block_offset_x
    end
end

function love.update()
    if game.is_playing == false then
        return
    end

    if player.moving_left then
        player.position.x = player.position.x - settings.player_speed
    end
    if player.moving_right then
        player.position.x = player.position.x + settings.player_speed
    end

    local b = game.ball

    -- move ball
    b.position.x = b.position.x + b.velocity.dx
    b.position.y = b.position.y + b.velocity.dy

    -- Check wall collisions
    if b.position.x <= settings.collision_margin then
        b.velocity.dx = -b.velocity.dx
        media.impact_wall:stop()
        media.impact_wall:play()
    end
    if b.position.x >= love.graphics.getWidth() - settings.collision_margin then
        b.velocity.dx = -b.velocity.dx
        media.impact_wall:stop()
        media.impact_wall:play()
    end
    if b.position.y <= settings.collision_margin then
        -- ceiling hit
        b.velocity.dy = -b.velocity.dy
        media.impact_wall:stop()
        media.impact_wall:play()
    end

    -- player collision
    local player_block = {
        x = player.position.x,
        y = player.position.y,
        width = player.width,
        height = player.height
    }
    if checkCollision(player_block, game.ball) then
        media.impact_player:play()
        b.velocity.dy = -b.velocity.dy
        local cx, cy = player.getCenter()
        local distance_from_center = b.position.x - cx
        game.ball.velocity.dx = (distance_from_center / (player.width / 2)) * settings.ball_speed
    end


    -- Check box collisions
    for _, block in ipairs(game.blocks) do
        if block.active then
            local dist_x = block.x - b.position.x
            local dist_y = block.y - b.position.y
            if checkCollision(block, game.ball) then
                block.active = false
                media.impact:stop()
                media.impact:play()

                game.score = game.score + 1

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
    if game.score == #game.blocks then
        game.is_playing = false
    end
end

function love.draw()
    if game.is_playing == false then
        love.graphics.clear(0.1, 0.9, 0.3, 1)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print("YOU WON! GOOD JOB!", love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
        love.graphics.print(
            "Press space to play again", love.graphics.getWidth() / 2, (love.graphics.getHeight() / 2) + 30
        )
        love.graphics.setColor(255, 255, 255, 255) -- white?
        love.graphics.draw(media.jirka,
            (love.graphics.getWidth() / 2) - 150,
            (love.graphics.getHeight() / 2) - 70)

        return
    end
    love.graphics.setColor(1, 1, 1, 1) -- white
    love.graphics.clear()

    love.graphics.print("Score: " .. tostring(game.score), 10, 10)

    love.graphics.rectangle("fill", player.position.x, player.position.y, player.width, player.height)

    -- draw the ball
    love.graphics.circle("fill", game.ball.position.x, game.ball.position.y, game.ball.radius)

    -- draw the blocks
    for _, block in ipairs(game.blocks) do
        if block.active then
            love.graphics.setColor(block.color.r, block.color.g, block.color.b)
            love.graphics.rectangle("fill", block.x, block.y, block.width, block.height, 4, 4)
        end
    end
end

-- INPUT HANDLING

function love.keypressed(key)
    if key == "left" or key == "a" then
        player.moving_left = true
    end
    if key == "right" or key == "d" then
        player.moving_right = true
    end
end

function love.keyreleased(key)
    if key == "left" or key == "a" then
        player.moving_left = false
    end
    if key == "right" or key == "d" then
        player.moving_right = false
    end

    if game.is_playing == false and key == "space" then
        resetGame()
        game.is_playing = true
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

function resetGame()
    -- Remove all blocks
    for k in pairs(game.blocks) do
        game.blocks[k] = nil
    end
    -- reset score
    game.score = 0

    -- Reload
    love.load()
end
