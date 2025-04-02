chain_lens = {
    [1] = {
        8
    },
    [2] = {
        10 
    },
    [3] = {
        13
    },
    [4] = {
        10, 6 
    },
    [5] = {
        12
    },
    [6] = {
        10,28
    },
    [7] = { -- snake level
        46
    },
    [8] = {0}
}

rev_tracks = {
    [1] = {
        true
    },
    [2] = {
        false
    },
    [3] = {
        false, false
    },
    [4] = {
        false, false
    },
    [5] = {
        true
    },
    [6] = {
        true, true
    },
    [7] = {
        false, false
    },
    [8] = {
        false, false
    }
}

function get_player_pos()
    local map_x = 16 * (lvl - 1)
    local map_y = 0
    for xi = map_x, map_x + 15 do
        for yi = map_y, map_y + 15 do
            if mget(xi, yi) == 9 then
                local x, y = (xi - (lvl - 1) * 16) * 8 + 4, yi * 8 + 4
                ppos[1] = x
                ppos[2] = y
                lppos[1] = x
                lppos[2] = y
                init_player_pos = { x - 4, y - 4 }
            end
        end
    end
end

function get_adj(x, y, excl_x, excl_y)
    local ret = {}
    if x > 0 then
        if not (x - 1 == excl_x and y == excl_y) then
            add(ret, {x-1, y})
        end
    end
    if x < 127 then
        if not (x + 1 == excl_x and y == excl_y) then
            add(ret, {x+1, y})
        end
    end
    if y > 0 then
        if not (x == excl_x and y - 1 == excl_y) then
            add(ret, {x, y-1})
        end
    end
    if y < 127 then
        if not (x == excl_x and y + 1 == excl_y) then
            add(ret, {x, y+1})
        end
    end
    return ret
end

function generate_chain(idx, x, y)
    add(junctions, {x - 4, y - 4})
    local chain = {}
    local chain_len = chain_lens[lvl][idx]
    for j=0, chain_len - 1  do
        local y = lvl == 3 and 4 or y + j * link_dist + 1
        add(chain, {{x - 1, y}, {x - 1, y}})
    end
    chains[idx] = chain
end

function get_junctions(x, y)
    local ret = {{(x - map_x_offset) * 8, (y - map_y_offset) * 8}}
    -- local nxt = {x, y}
    local adj = get_adj(x, y, x, y)
    local last_x, last_y = x, y
    ::next_loop::
    for a in all(adj) do
        local tile = mget(a[1], a[2])
        if mid(32, 38, tile) == tile then
            if tile == 38 then
                add(ret, {(a[1] - map_x_offset) * 8, (a[2] - map_y_offset) * 8})
            end
            adj = get_adj(a[1], a[2], last_x, last_y)
            last_x, last_y = a[1], a[2]
            goto next_loop
        end
    end
    return ret
end

function detect_track()
    local map_x = 16 * (lvl - 1)
    local map_y = 0
    for xi = map_x, map_x + 15 do
        for yi = map_y, map_y + 15 do
            if mget(xi, yi) == 26 then
                -- printh("got blue")
                generate_chain(1, (xi - map_x_offset) * 8 + 4, (yi - map_y_offset) * 8 + 4)
                tracks[1] = get_junctions(xi, yi)
                
            end
            if mget(xi, yi) == 27 then
                generate_chain(2, (xi - map_x_offset) * 8 + 4, (yi - map_y_offset) * 8 + 4)
                tracks[2] = get_junctions(xi, yi)
                -- printh("got green")
            end
            if mget(xi, yi) == 28 then
                generate_chain(3, (xi - map_x_offset) * 8 + 4, (yi - map_y_offset) * 8 + 4)
                tracks[3] = get_junctions(xi, yi)
                -- printh("got red")
            end
        end
    end
end
