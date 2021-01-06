--[[
#//******************************//#
#//# Author: by uriid1          #//#
#//# license: GNU GPL           #//#
#//# telegram: uriid1           #//#
#//# Mail: appdurov@gmail.com   #//#
####****************************####
]]

function love.load()
    math.randomseed(os.time())
    win_w = love.graphics.getWidth()
    win_h = love.graphics.getHeight()

    -- create obj brick
    bricks = {}
    for x = 0, 12 do
        for y = 0, 5 do
            local brick = {}
            brick.w = 50
            brick.h = 35
            brick.x = 100 + brick.w*x
            brick.y = 100 + brick.h*y
            brick.xoffset = brick.w*.5
            brick.yoffset = brick.h*.5
            local r, g, b = math.random(), math.random(), 1
            function brick:draw_self()
                love.graphics.setColor(r, g, b, 1)
                love.graphics.rectangle("fill", brick.x - brick.xoffset, brick.y - brick.yoffset, brick.w, brick.h)
            end
            table.insert(bricks, brick)
        end
    end

    -- create obj desk
    desk = {}
    desk.w = 100
    desk.h = 25
    desk.x = win_w*.5
    desk.y = win_h - 35
    desk.xoffset = desk.w*.5
    desk.yoffset = desk.h*.5
    desk.hspeed = 0
    desk.speed = 10
    desk.direction = 0

    -- Movement of the desk
    function desk:step()   
        desk.direction = (key_right - key_left)
        desk.hspeed = lerp(desk.hspeed, desk.speed*desk.direction, 0.1)
        desk.x = desk.x + desk.hspeed
        desk.x = clamp(desk.x, desk.xoffset, win_w - desk.xoffset)
    end
    function desk:draw_self()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", desk.x - desk.xoffset, desk.y - desk.yoffset, desk.w, desk.h)
    end

    -- create obj ball
    ball = {}
    ball.active = false
    ball.x = 0
    ball.y = 0
    ball.r = 12
    ball.speed = 0
    ball.direction = 0
    ball.hspeed = 0
    ball.vspeed = 0

    -- Movement of the ball
    function ball:step()
        if (ball.speed ~= 0) then
            local new_dir = ball.direction * (math.pi / -180)
            ball.hspeed = ball.speed * math.cos(new_dir)
            ball.vspeed = ball.speed * math.sin(new_dir)
            ball.x = ball.x + ball.hspeed
            ball.y = ball.y + ball.vspeed
        end

        -- Activate ball
        if (not ball.active) then
            ball.speed = 0
            ball.x = desk.x
            ball.y = desk.y - ball.r*2.5
            if (key_space) then
                ball.speed = 6
                ball.direction = math.random(45, 90)
                ball.active = true
            end
        end

        -- Window collision
        if (ball.x + (ball.r + ball.hspeed) > win_w or ball.x - ball.r + ball.hspeed < 0) then
            ball.direction = -ball.direction + 180
        end
        if (ball.y - ball.r + ball.vspeed < 0) then
           ball.direction = -ball.direction
        end
        if (ball.y + ball.r + ball.vspeed > win_h) then
            ball.active = false
        end
        ball.x = clamp(ball.x, ball.r, win_w - ball.r)

    end
    -- Draw ball
    function ball:draw_self()
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.circle("fill", ball.x, ball.y, ball.r, 15)
    end

    --------- Engine
    function clamp(val, min, max) return math.max(min, math.min(max, val)) end
    function lerp(v0, v1, t) return (1 - t) * v0 + t * v1 end
    function point_direction(x1, y1, x2, y2) return ((-180/math.pi) * (math.atan2(y1 - y2, x1 - x2))) + 180 end

    -- Very thanks yal.cc/rectangle-circle-intersection-test
    function collision_circle_rect(_circle, _rect, hsp, vsp)
        local DeltaX = _circle.x - math.max( (_rect.x - _rect.xoffset) - hsp, math.min(_circle.x, (_rect.x + _rect.xoffset) - hsp ))
        local DeltaY = _circle.y - math.max( (_rect.y - _rect.yoffset) - vsp, math.min(_circle.y, (_rect.y + _rect.yoffset) - vsp ))
        return (DeltaX^2 + DeltaY^2) < (_circle.r^2)
    end
    ---------

    -------- Brick collision detection
    function brick_collision(_list_bricks, _ball, _add_spd)
        -- Top or Down
        for i=#_list_bricks, 1, -1 do
            if collision_circle_rect(_ball, bricks[i], 0, _ball.vspeed) then
                while not collision_circle_rect(_ball, bricks[i], 0, _ball.vspeed) do
                    _ball.y = _ball.y + _ball.vspeed
                end
                _ball.vspeed = 0
                _ball.direction = -_ball.direction
                _ball.speed = _ball.speed + _add_spd
                table.remove(bricks, i)
            end
        end

        -- Left or Right
        for i=#_list_bricks, 1, -1 do
            if collision_circle_rect(_ball, bricks[i], _ball.hspeed, 0) then
                while not collision_circle_rect(_ball, bricks[i], _ball.hspeed, 0) do
                    _ball.x = _ball.x + _ball.hspeed
                end
                _ball.hspeed = 0
                _ball.direction = -_ball.direction + 180
                _ball.speed = _ball.speed + _add_spd
                table.remove(bricks, i)
            end
        end

        -- Corner
        for i=#_list_bricks, 1, -1 do
            if collision_circle_rect(_ball, bricks[i], _ball.hspeed, _ball.vspeed) then
                while not collision_circle_rect(_ball, bricks[i], _ball.hspeed, _ball.vspeed) do
                    _ball.x = _ball.x + _ball.hspeed
                    _ball.y = _ball.y + _ball.vspeed
                end
                _ball.x = _ball.x + _ball.hspeed
                _ball.y = _ball.y + _ball.vspeed
                _ball.speed = _ball.speed + _add_spd
            end
        end
    end
end

function love.update(dt)
    -- Control
    mx, my = love.mouse.getPosition()
    key_left  = love.keyboard.isDown("left")  and 1 or 0
    key_right = love.keyboard.isDown("right") and 1 or 0
    key_space = love.keyboard.isDown("space") and true or false

    -- Brick collision
    brick_collision(bricks, ball, .075)

    -- desk collision
    if collision_circle_rect(ball, desk, ball.hspeed, ball.vspeed) then
        ball.x = ball.x + ball.hspeed
        ball.y = ball.y + ball.vspeed
        ball.direction = point_direction(desk.x, desk.y, ball.x, ball.y)
    end

    -- Objects movement
    ball:step()
    desk:step()
end

function love.draw()
    -- Background
    love.graphics.setBackgroundColor(.25, .25, .5, 1)

    -- Bricks
    for i = 1, #bricks, 1 do
       bricks[i]:draw_self()
    end

    -- Ball
    ball:draw_self()

    -- Desk
    desk:draw_self()
end
