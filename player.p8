lppos = {20, 11}
ppos = {20, 11}
pgrav = 0.08
pjump = 1.5
climb_spd = 0.1
grabbed_chain = 0
grabbed_link = 4
grabbed_link_t = 0.5
swing_force = .20
swing_vel = 0
move_spd = 0.05
air_move_spd = 0.02
max_fall_spd = 1.75
max_hor_speed = 1
grab_range = 32

function apply_player_input()

end

function update_player()
    if grabbed_chain == 0 or on_ground then
        local dx = ppos[1] - lppos[1]
        local dy = ppos[2] - lppos[2]
        lppos[1] = ppos[1]
        lppos[2] = ppos[2]
        local drag = 1
        if on_ground then
            drag = 0.9
        end
        ppos[1] += mid(dx * drag, max_hor_speed, -max_hor_speed)
        ppos[2] += min(dy, max_fall_spd) 
        if not on_ground then
            ppos[2] += pgrav
        end
        if not btn(5) then
            if btn(1) then
                if on_ground then
                    ppos[1] += move_spd
                else
                    ppos[1] += air_move_spd
                end
                -- lppos[1] -= 0.05
            end
            if btn(0) then
                if on_ground then
                    ppos[1] -= move_spd
                else
                    ppos[1] -= air_move_spd
                end
                -- lppos[1] += 0.05
            end
        end
        if btnp(4) and on_ground then
            lppos[2] += pjump
        end
        if btnp(5) then
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
                    end
                end
            end
        end
    else
        if not on_ground then
            if btn(2) then
                grabbed_link_t -= climb_spd
            end
            if btn(3) then
                grabbed_link_t += climb_spd
            end
            if btn(1) then
                if sgn(swing_vel) == 1 then
                    swing_vel = 0
                end
                swing_vel -= swing_force
            end
            if btn(0) then
                if sgn(swing_vel) == -1 then
                    swing_vel = 0
                end
                swing_vel += swing_force
            end
            swing_vel *= 0.5
            if grabbed_link_t >= 1 then
                grabbed_link += flr(grabbed_link_t)
                grabbed_link_t = grabbed_link_t % 1
                if grabbed_link > chain_len then
                    grabbed_chain = 0
                    return
                end
            end
            if grabbed_link_t < 0 then
                grabbed_link += flr(grabbed_link_t)
                grabbed_link_t = grabbed_link_t % 1
                if grabbed_link < 1 then
                    grabbed_link = 1
                    grabbed_link_t = 0 
                    return
                end
            end
            local chain = chains[grabbed_chain]
            local l = chain[grabbed_link]
            local nl = chain[grabbed_link + 1]
            local dx = nl[2][1] - l[2][1]
            local dy = nl[2][2] - l[2][2]
            lppos[1] = ppos[1]
            lppos[2] = ppos[2]
            ppos[1] = l[2][1] + dx * grabbed_link_t
            ppos[2] = l[2][2] + dy * grabbed_link_t
            if btnp(4) then
                lppos[2] += pjump
                grabbed_chain = 0
            end
        end
    end
    if on_ground and grabbed_chain != 0 then
        chains[grabbed_chain][grabbed_link][2][1] = ppos[1]
        chains[grabbed_chain][grabbed_link][2][2] = ppos[2]
    end
end

on_ground = false
hit_ceiling = false

function collide_player()
    --above
    local ltop = mget((ppos[1] - 1.5) / 8, (ppos[2] - 2.5) / 8)
    local rtop = mget((ppos[1] + 1.5) / 8, (ppos[2] - 2.5) / 8)
    if fget(ltop, 0) or fget(rtop, 0) then
        if not hit_ceiling then
            hit_ceiling = true
            local ceil_y = flr((ppos[2] - 2.5) / 8) * 8  + 10
            ppos[2] = ceil_y
            lppos[2] = ceil_y
        end
    else
        hit_ceiling = false
    end
    --below
    local lfoot = mget((ppos[1] - 1.5) / 8, (ppos[2] + 2.5) / 8)
    local rfoot = mget((ppos[1] + 1.5) / 8, (ppos[2] + 2.5) / 8)
    if fget(lfoot, 0) or fget(rfoot, 0) then
        local floor_y = flr((ppos[2] + 2.5) / 8) * 8 - 2
        if not on_ground then
            ppos[2] = floor_y
            lppos[2] = floor_y
        end
        on_ground = true
    else
        on_ground = false
    end
    --sides
    local lear = mget((ppos[1] - 2.5) / 8, (ppos[2] - 1.5) / 8)
    local lhand = mget((ppos[1] - 2.5) / 8, (ppos[2] + 1.5) / 8)
    local rear = mget((ppos[1] + 2) / 8, (ppos[2] - 1.5) / 8)
    local rhand = mget((ppos[1] + 2) / 8, (ppos[2] + 1.5) / 8)
    if fget(rear, 0) or fget(rhand, 0) then
        local wall_x = flr((ppos[1] + 2.5) / 8) * 8 - 2
        ppos[1] = wall_x
        lppos[1] = wall_x
    end
    if fget(lear, 0) or fget(lhand, 0) then
        local wall_x = flr((ppos[1] - 2.5) / 8) * 8 + 10
        ppos[1] = wall_x
        lppos[1] = wall_x
    end
end
