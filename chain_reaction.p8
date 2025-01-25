pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

chains = { }
link_dist = 12
grav = 0.1

function _init()
    for i=0, 2 do
        local x = 24 + 40 * i
        local chain = {}
        for j=0, 10 do
            add(chain, {{x, j * 12}, {x, j * 12}})
        end
        add(chains, chain)
    end
    for c in all(chains[1]) do
        printh("x: " .. c[2][1] .. " y: " .. c[2][2])
    end
    local test_link = chains[2][7][1]
    chains[2][7][1] = {test_link[1] - 2, test_link[2] + 10}
    test_link = chains[1][7][1]
    chains[1][7][1] = {test_link[1] - 2, test_link[2] + 10}
    test_link = chains[3][7][1]
    chains[3][7][1] = {test_link[1] - 5, test_link[2] + 2}
end

function _update60()
    update_chains()
end

function update_chains()
    for chain in all(chains) do
        for i=2, #chain do
            local link = chain[i]
            local dx = link[2][1] - link[1][1]
            link[1][1] = link[2][1]
            link[2][1] += dx
            local dy = link[2][2] - link[1][2] + grav
            link[1][2] = link[2][2]
            link[2][2] += dy
        end
        for n = 0, 2 do
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
        end
    end
end

function _draw()
    cls()
    draw_chains()
end

function draw_chains()
    for c in all(chains) do
        for i=1, #c - 1 do
            local l = c[i][2]
            local nl = c[i + 1][2]
            local diff_x = nl[1] - l[1]
            local diff_y = nl[2] - l[2]
            local dx = diff_x / 4.0
            local dy = diff_y / 4.0
            for j = 0, 4 do
                local xx = l[1] + dx * j
                local yy = l[2] + dy * j
                circ(xx, yy, 1, 6)
            end
            -- pset(l[1], l[2], 8)
        end
        -- local last = c[#c]
        -- pset(last[1], last[2], 8)
    end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
