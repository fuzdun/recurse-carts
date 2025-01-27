chains = { }
link_dist = 3
grav = 0.04
chain_spd = .4
chain_len = 30

function update_chains()
    for chain in all(chains) do
        -- move based on input
        if btn(5) then
            if btn(1) then
                chain[1][2][1] += chain_spd
            end
            if btn(0) then
                chain[1][2][1] -= chain_spd
            end
        end
        if grabbed_chain != 0 then
            chains[grabbed_chain][grabbed_link][1][1] += swing_vel
        end
        -- apply velocity + gravity
        for i=2, #chain do
            local link = chain[i]
            local dx = link[2][1] - link[1][1]
            link[1][1] = link[2][1]
            link[2][1] += dx
            local dy = link[2][2] - link[1][2] + grav
            link[1][2] = link[2][2]
            link[2][2] += dy
        end
        -- handle collisions
        for i=1, #chain do
            local l = chain[i]
            local map_x = flr(l[2][1] / 8)
            local map_y = flr(l[2][2] / 8)
            local wall_l = map_x * 8
            local wall_t = map_y * 8
            local m_spr = mget(map_x, map_y)
            if fget(m_spr, 0) then
                local x0, y0, x1, y1 = l[1][1], l[1][2], l[2][1], l[2][2]
                if fget(m_spr, 5) then
                    local bx0, by0, bx1, by1 = wall_l, wall_t, wall_l + 8, wall_t + 8
                    local col = check_line_sq_col(x0, y0, x1, y1, bx0, by0, bx1, by1)
                    if col[1] == "x_col" then
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
                            l[1][1] += (x1 - x0) * .5
                        else
                            l[2][2] = wall_t + 9
                            l[1][2] = wall_t + 9
                        end
                    end
                else
                    if fget(m_spr, 1) then
                        l[2][1] = wall_l - 1
                        l[1][1] = wall_l - 1
                    end
                    if fget(m_spr, 2) then
                        l[2][1] = wall_l + 9
                        l[1][1] = wall_l + 9
                    end
                    if fget(m_spr, 3) then
                        l[2][2] = wall_t - 1
                        l[1][2] = wall_t - 1
                        l[1][1] += (x1 - x0) * 0.5
                    end
                    if fget(m_spr, 4) then
                        l[2][2] = wall_t + 9
                        l[1][2] = wall_t + 9
                    end
                end
            end
        end
        -- constrain links
        for n=0, 7 do
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
                    if i == 1 then
                        nl[2][1] -= xadj * 2
                        nl[2][2] -= yadj * 2
                    else
                        l[2][1] += xadj
                        l[2][2] += yadj
                        nl[2][1] -= xadj
                        nl[2][2] -= yadj
                    end
                end
            end
            for i=1, #chain - 1 do
                ::next_link::
                if i ~= #chain do
                    local l = chain[i]
                    local nl = chain[i + 1]
                    apply_below_corner_bump(l, nl)
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
    local below_tile = mget(below_map_x, below_map_y)
    if not fget(below_tile, 5) then
        return
    end
    if not mid(nl[2][2], below_wall_t, below_wall_t + 8) == nl[2][2] then
        return
    end
    local dx, dy = nl[2][1] - l[2][1], nl[2][2] - l[2][2]
    local constr_dy = below_wall_t - l[2][2]
    if constr_dy > dy then
        return
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
    end
end
