chains = { }
tracks = { }
link_dist = 3
drag_dist = 15
grav = 0.03
chain_spd = .4
chain_len = 40

cur_chain_ts = {0, 0, 0}
cur_track_segs = {1, 1, 1}

chain_router = {
    [10] = 1,
    [11] = 2,
    [12] = 3
}

-- blue chain = 1
-- green = 2
-- red = 3

function apply_chain_input()
    -- move based on input
        local lever = mget(ppos[1] / 8 + map_x_offset, ppos[2] / 8 + map_y_offset)
        if has({10, 11, 12}, lever) then
            local chain_idx = chain_router[lever]
            local chain = chains[chain_idx]
            printh(#tracks[chain_idx])
            if btn(5) and #tracks[chain_idx] > 1 then
                local seg = tracks[chain_idx][cur_track_segs[chain_idx]]
                local next_seg = tracks[chain_idx][cur_track_segs[chain_idx] + 1]
                local dx = next_seg[1] - seg[1]
                local dy = next_seg[2] - seg[2]
                local seg_len = sqrt(dx * dx + dy * dy)
                if btn(1) then
                    if rev_tracks[lvl][chain_idx] then
                        cur_chain_ts[chain_idx] -= 0.5 / seg_len 
                    else
                        cur_chain_ts[chain_idx] += 0.5 / seg_len 
                    end
                end
                if btn(0) then
                    if rev_tracks[lvl][chain_idx] then
                        cur_chain_ts[chain_idx] += 0.5 / seg_len 
                    else
                        cur_chain_ts[chain_idx] -= 0.5 / seg_len 
                    end
                end
                local x = seg[1] + (next_seg[1] - seg[1]) * cur_chain_ts[chain_idx]
                local y = seg[2] + (next_seg[2] - seg[2]) * cur_chain_ts[chain_idx]
                chain[1][2][1] = x + 3
                chain[1][2][2] = y + 5
                if cur_chain_ts[chain_idx] >= 1 then
                    if cur_track_segs[chain_idx] == #tracks[chain_idx] - 1 then
                        cur_chain_ts[chain_idx] = 1
                    else
                        cur_track_segs[chain_idx] += 1 
                        cur_chain_ts[chain_idx] = 0.01
                    end
                end
                if cur_chain_ts[chain_idx] <= 0  then
                    if cur_track_segs[chain_idx] == 1 then
                        cur_chain_ts[chain_idx] = 0
                    else
                        cur_track_segs[chain_idx] -= 1 
                        cur_chain_ts[chain_idx] = 1
                    end
                end
                -- if btn(2) then
                --     chain[1][2][2] -= chain_spd
                -- end
                -- if btn(3) then
                --     chain[1][2][2] += chain_spd
                -- end
            end
        end
        if grabbed_chain ~= 0 then
            local spd = dragging_chain and chain_drag_spd or chain_swing_spd
            if btn(1) then
                chains[grabbed_chain][grabbed_link][2][1] += spd
            end
            if btn(0) then
                chains[grabbed_chain][grabbed_link][2][1] -= spd
            end
        end
end

function apply_chain_forces()
    -- apply velocity + gravity
    for chain in all(chains) do
        for i=2, #chain do
            local link = chain[i]
            local dx = link[2][1] - link[1][1]
            if dragging_chain then
                dx = mid(dx, -max_hor_speed, max_hor_speed)
            end
            link[1][1] = link[2][1]
            link[2][1] += dx
            local dy = link[2][2] - link[1][2] + grav
            link[1][2] = link[2][2]
            link[2][2] += dy
        end
    end
end

function update_chains()
    for chain_i=1, #chains do
        local chain = chains[chain_i]
        -- handle collisions
        for i=1, #chain do
            local l = chain[i]
            local map_x = flr(l[2][1] / 8)
            local map_y = flr(l[2][2] / 8)
            local wall_l = map_x * 8
            local wall_t = map_y * 8
            local m_spr = mget(map_x + map_x_offset, map_y + map_y_offset)
            if fget(m_spr, 0) then
                local x0, y0, x1, y1 = l[1][1], l[1][2], l[2][1], l[2][2]
                if fget(m_spr, 5) then
                    local bx0, by0, bx1, by1 = wall_l, wall_t, wall_l + 8, wall_t + 8
                    local col = check_line_sq_col(x0, y0, x1, y1, bx0, by0, bx1, by1)
                    if col == "x_col" then
                        local sx = sgn(x1 - x0)
                        if sx == 1 and fget(m_spr, 1) then
                            l[2][1] = wall_l - 1
                            l[1][1] = wall_l - 1
                        end
                        if sx == -1 and fget(m_spr, 2) then
                            l[2][1] = wall_l + 9
                            l[1][1] = wall_l + 9
                        end
                    else
                        if sgn(y1 - y0) == 1 then
                            l[2][2] = wall_t - 1
                            l[1][2] = wall_t - 1
                            l[1][1] += (x1 - x0) * ((grabbed_chain == chain_i) and 0.75 or 0.5)
                        else
                            l[2][2] = wall_t + 9
                            l[1][2] = wall_t + 9
                        end
                    end
                else
                    if fget(m_spr, 1) and sgn(x1 - x0) == 1 then
                        l[2][1] = wall_l - 1
                        l[1][1] = wall_l - 1
                    end
                    if fget(m_spr, 2) and sgn(x1 - x0) == -1 then
                        l[2][1] = wall_l + 9
                        l[1][1] = wall_l + 9
                    end
                    if fget(m_spr, 3) and sgn(y1 - y0) == 1 then
                        l[2][2] = wall_t - 1
                        l[1][2] = wall_t - 1
                        l[1][1] += (x1 - x0) * ((grabbed_chain == chain_i) and 0.75 or 0.5)
                    end
                    if fget(m_spr, 4) and sgn(y1 - y0) == -1 then
                        l[2][2] = wall_t + 9
                        l[1][2] = wall_t + 9
                    end
                end
            end
        end
        -- constrain links
        for n=0, 6 do
            for i=1, #chain - 1 do
                local l = chain[i]
                local nl = chain[i + 1]
                local dx = nl[2][1] - l[2][1]
                local dy = nl[2][2] - l[2][2]
                local d = sqrt(dx * dx + dy * dy)
                if d > link_dist then
                    local pct = 1 - (link_dist / d)
                    local xadj = pct * dx / 2
                    local yadj = pct * dy / 2
                    if grabbed_chain == chain_i and i ~= 1 and dragging_chain and i + 1 == grabbed_link then
                        l[2][1] += xadj * 2
                        l[2][2] += yadj * 2
                    end
                    
                    if i == 1 or (grabbed_chain == chain_i and dragging_chain and i == grabbed_link) then
                        nl[2][1] -= xadj * 2
                        nl[2][2] -= yadj * 2
                    else
                        l[2][1] += xadj
                        l[2][2] += yadj
                        nl[2][1] -= xadj
                        nl[2][2] -= yadj
                    end
                    if i ~= 1 and grabbed_chain == chain_i and dragging_chain and i == grabbed_link then
                        l[2][2] += (ppos[2] - l[2][2]) * 0.25
                    end
                end
            end
        end
        for i=1, #chain - 1 do
            ::next_link::
            if i ~= #chain do
                local l = chain[i]
                local nl = chain[i + 1]
                if not apply_below_corner_bump(l, nl) then
                    apply_below_corner_bump(nl, l)
                end
            end
        end
    end
end

function apply_below_corner_bump(l, nl)
    local below_map_x = flr(l[2][1] / 8)
    local below_map_y = flr(l[2][2] / 8) + 1
    local below_wall_l = below_map_x * 8
    local below_wall_t = below_map_y * 8
    local below_tile = mget(below_map_x + map_x_offset, below_map_y + map_y_offset)
    if not fget(below_tile, 5) then
        return false
    end
    if not mid(nl[2][2], below_wall_t, below_wall_t + 8) == nl[2][2] then
        return false
    end
    local dx, dy = nl[2][1] - l[2][1], nl[2][2] - l[2][2]
    local constr_dy = below_wall_t - l[2][2]
    if constr_dy > dy then
        return false
    end
    local fact = abs(constr_dy) / abs(dy)
    local new_x = l[2][1] + fact * dx
    if mid(below_wall_l, new_x, below_wall_l + 8) == new_x then
        local dir = sgn(nl[2][1] - l[2][1])
        local x_off = 8
        if dir == -1 then
            x_off = 0
        end
        local constr_dx = below_wall_l + x_off - l[2][1]
        local len = sqrt(dx * dx + dy * dy)
        local constr_len = sqrt(constr_dx * constr_dx + constr_dy * constr_dy)
        local fact = min(len / constr_len, 12)
        local offset_x = l[2][1] + constr_dx * fact
        local offset_y = l[2][2] + constr_dy * fact
        nl[2][1] = offset_x
        nl[2][2] = offset_y
        nl[1][1] = offset_x
        nl[1][2] = offset_y
        return true
    end
    return false
end
