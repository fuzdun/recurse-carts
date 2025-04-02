pgrav = 0.055
pjump = 1.0
detach_jump = .5
climb_spd = 0.1
move_spd = 0.07
air_move_spd = 0.04
chain_drag_spd = 0.05
chain_swing_spd = 0.16
max_fall_spd = 1.75
max_hor_speed = .75
grab_range = 40
on_ground = false
hit_ceiling = false
dragging_chain = false

function check_death()
    if ppos[1] < 0 or ppos[1] > 127 or ppos[2] > 140 or ppos[2] < -20 or
    mget(ppos[1] / 8 + map_x_offset, ppos[2] / 8 + map_y_offset) == 40 then
        load_level()
    end
end

function apply_player_input()
    local on_lever = has({10, 11, 12}, mget(ppos[1] / 8 + map_x_offset, ppos[2] / 8 + map_y_offset)) and btn(5)
    -- not moving chain
    if not on_lever then
        -- run
        if btn(1) then
            if on_ground then
                ppos[1] += move_spd
            else
                ppos[1] += air_move_spd
            end
        end
        if btn(0) then
            if on_ground then
                ppos[1] -= move_spd
            else
                ppos[1] -= air_move_spd
            end
        end
        -- jump
        if btnp(4) and on_ground then
            lppos[2] += pjump
            grabbed_chain = 0
        end
    end
    -- grab chain
    -- on chain
    if grabbed_chain ~= 0 then
        -- move up/down chain
        if btn(2) then
            grabbed_link_t -= climb_spd
            dragging_chain = false
        end
        if btn(3) then
            grabbed_link_t += climb_spd
        end
        if btnp(5) then
            grabbed_chain = 0
        end
        -- let go of chain
        if btnp(4) then
            if not on_ground then
                lppos[2] += detach_jump
            end
            grabbed_chain = 0
        end
    -- not on chain
    else
        if btnp(5) and not on_lever then
            for chain_i=1, #chains do
                local chain = chains[chain_i]
                for link_i=1, #chain-1 do
                    local link = chain[link_i]
                    local x_dist = ppos[1] - link[2][1]
                    local y_dist = ppos[2] - link[2][2]
                    local d = x_dist * x_dist + y_dist * y_dist
                    if d < grab_range then
                        grabbed_chain = chain_i
                        grabbed_link = link_i
                        grabbed_link_t = 0
                        if on_ground then
                            dragging_chain = true
                        end
                    end
                end
            end
        end
    end
end

function apply_player_forces()
    -- apply velocity
    local dx = ppos[1] - lppos[1]
    local dy = ppos[2] - lppos[2]
    lppos[1] = ppos[1]
    lppos[2] = ppos[2]
    -- apply drag / clamp speed
    local drag = 1
    if grabbed_chain ~= 0 then
        drag = 0.5
    end
    if on_ground then
        drag = 0.9
    end
    ppos[1] += mid(dx * drag, max_hor_speed, -max_hor_speed)
    if grabbed_chain == 0 then
        ppos[2] += min(dy, max_fall_spd) 
    end
    -- apply gravity
    if not on_ground and grabbed_chain == 0 then
        ppos[2] += pgrav
    end
    -- move up/down chain
    if grabbed_chain ~= 0 then
        local chain_len = chain_lens[lvl][grabbed_chain]
        if grabbed_link_t >= 1 then
            grabbed_link += flr(grabbed_link_t)
            grabbed_link_t = grabbed_link_t % 1
            if grabbed_link > chain_len then
                grabbed_link = chain_len
                return
            end
        end
        if grabbed_link_t < 0 then
            grabbed_link += flr(grabbed_link_t)
            grabbed_link_t = grabbed_link_t % 1
            if grabbed_link < 2 then
                grabbed_link = 2
                grabbed_link_t = 0 
                return
            end
        end
    end
end

function constrain_player_to_chain()
    local chain = chains[grabbed_chain]
    local l = chain[grabbed_link]
    local nl
    if grabbed_link == #chain then
        nl = l
    else
        nl = chain[grabbed_link + 1]
    end
    local dx = nl[2][1] - l[2][1]
    local dy = nl[2][2] - l[2][2]
    ppos[1] = l[2][1] + grabbed_link_t * dx
    if not dragging_chain then
        ppos[2] = l[2][2] + grabbed_link_t * dy
    end
end

function collide_player()
    --above
    local l_top = {flr((ppos[1] - 1.5) / 8), flr((ppos[2] - 2.5) / 8)}
    local r_top = {flr((ppos[1] + 1.5) / 8), flr((ppos[2] - 2.5) / 8)}
    if fget(mget(l_top[1] + map_x_offset, l_top[2] + map_y_offset), 0) or fget(mget(r_top[1] + map_x_offset, r_top[2] + map_y_offset), 0) then
        if not hit_ceiling then
            hit_ceiling = true
            local ceil_y = l_top[2] * 8  + 10
            ppos[2] = ceil_y
            lppos[2] = ceil_y
            if grabbed_chain ~= 0 then
                chains[grabbed_chain][grabbed_link][2][2] = ppos[2] + 1
                chains[grabbed_chain][grabbed_link][1][2] = ppos[2]
            end
        end
    else
        hit_ceiling = false
    end
    --below
    local l_foot = {flr((ppos[1] - 1.5) / 8), flr((ppos[2] + 2.5) / 8)} 
    local r_foot = {flr((ppos[1] + 1.5) / 8), flr((ppos[2] + 2.5) / 8)}
    local l_tile = mget(l_foot[1] + map_x_offset, l_foot[2] + map_y_offset)
    local r_tile = mget(r_foot[1] + map_x_offset, r_foot[2] + map_y_offset)
    local floor_y = l_foot[2] * 8 - 2
    local falling = ppos[2] >= lppos[2]
    local hit_standard_block = fget(l_tile, 0) or fget(r_tile, 0)
    local hit_one_sided_block = grabbed_chain == 0 and (fget(r_tile, 6) or fget(l_tile, 6))
    if hit_standard_block or (hit_one_sided_block and falling and lppos[2] <= floor_y ) then
        if not on_ground then
            ppos[2] = floor_y
            lppos[2] = floor_y
        end
        on_ground = true
        if grabbed_chain ~= 0 then
            chains[grabbed_chain][grabbed_link][2][2] = ppos[2] - 1
            chains[grabbed_chain][grabbed_link][1][2] = ppos[2]
            if not dragging_chain and grabbed_link < chain_lens[lvl][grabbed_chain] then
                grabbed_link += 1
            end
            dragging_chain = true
        end
        -- on_ground = false
    else
        dragging_chain = false
        on_ground = false
    end
    --sides
    local l_ear = {flr((ppos[1] - 2) / 8), flr((ppos[2] - 1.5) / 8)}
    local l_hand = {flr((ppos[1] - 2) / 8), flr((ppos[2] + 1.5) / 8)}
    local r_ear = {flr((ppos[1] + 2) / 8), flr((ppos[2] - 1.5) / 8)}
    local r_hand = {flr((ppos[1] + 2) / 8), flr((ppos[2] + 1.5) / 8)}
    if fget(mget(r_ear[1] + map_x_offset, r_ear[2] + map_y_offset), 0) or fget(mget(r_hand[1] + map_x_offset, r_hand[2] + map_y_offset), 0) then
        local wall_x = r_ear[1] * 8 - 2
        ppos[1] = wall_x
        lppos[1] = wall_x
        if grabbed_chain ~= 0 then
            chains[grabbed_chain][grabbed_link][2][1] = ppos[1] - 1
            chains[grabbed_chain][grabbed_link][1][1] = ppos[1]
        end
    end
    if fget(mget(l_ear[1] + map_x_offset, l_ear[2] + map_y_offset), 0) or fget(mget(l_hand[1] + map_x_offset, l_hand[2] + map_y_offset), 0) then
        local wall_x = l_ear[1] * 8 + 10
        ppos[1] = wall_x
        lppos[1] = wall_x
        if grabbed_chain ~= 0 then
            chains[grabbed_chain][grabbed_link][2][1] = ppos[1] + 1
            chains[grabbed_chain][grabbed_link][1][1] = ppos[1]
        end
    end
end
