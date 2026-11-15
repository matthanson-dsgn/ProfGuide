-- ============================================================
-- Finder.lua
-- Finds the nearest trainers for a profession. Trainers are
-- listed by zone, so distance is measured from you to the
-- middle of each trainer's zone: good for picking a town.
-- ============================================================

local addonName, ns = ...

local Finder = {}
ns.Finder = Finder

local zoneIndex -- zone name -> map info, built the first time we need it

-- Climbs from a map to the top of the map tree (the whole world).
local function TopMap(mapID)
    local info = C_Map.GetMapInfo(mapID)
    while info and info.parentMapID and info.parentMapID ~= 0 do
        local parent = C_Map.GetMapInfo(info.parentMapID)
        if not parent then break end
        info = parent
    end
    return info and info.mapID
end

-- Makes a lookup of every map by name, so "Orgrimmar" -> its map.
-- Zones (mapType 3) win over dungeons or small maps with the same name.
local function BuildZoneIndex()
    zoneIndex = {}
    local here = C_Map.GetBestMapForUnit("player")
    local top = here and TopMap(here)
    if not top then return end
    for _, m in ipairs(C_Map.GetMapChildrenInfo(top, nil, true) or {}) do
        local existing = zoneIndex[m.name]
        if not existing or (m.mapType == 3 and existing.mapType ~= 3) then
            zoneIndex[m.name] = m
        end
    end
end

-- Converts a spot on a map (0 to 1 across, 0 to 1 down) into world
-- coordinates in yards, plus which continent it's on.
local function WorldPos(mapID, x, y)
    local continent, pos = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
    if continent and pos then
        local wx, wy = pos:GetXY()
        return continent, wx, wy
    end
end

local function PlayerPos()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local p = C_Map.GetPlayerMapPosition(mapID, "player")
    if not p then return nil, nil, nil, mapID end
    local continent, x, y = WorldPos(mapID, p:GetXY())
    return continent, x, y, mapID
end

-- Distance from you to a zone (its middle): { dist, far, mapID }.
-- dist = 0 means you're in it; far = it's on another continent.
function Finder.ZoneInfo(zone)
    if not zoneIndex then pcall(BuildZoneIndex) end
    local info = {}
    local z = zoneIndex and zoneIndex[zone]
    info.mapID = z and z.mapID
    local ok, continent, px, py, hereID = pcall(PlayerPos)
    if not ok then return info end
    local hereInfo = hereID and C_Map.GetMapInfo(hereID)
    if hereInfo and hereInfo.name == zone then
        info.dist = 0
    elseif z and continent then
        local tc, tx, ty = WorldPos(z.mapID, 0.5, 0.5)
        if tc == continent and tx then
            info.dist = math.sqrt((tx - px) ^ 2 + (ty - py) ^ 2)
        else
            info.far = true
        end
    end
    return info
end

-- Returns up to `limit` trainers for your faction who can train you to
-- at least `needSkill`, nearest first. Each: { name, zone, where, max, dist, far, mapID }
function Finder.Nearest(profName, needSkill, limit)
    local list = ns.Trainers and ns.Trainers[profName]
    if not list then return {} end
    if not zoneIndex then pcall(BuildZoneIndex) end

    local faction = UnitFactionGroup("player")
    local ok, continent, px, py, hereID = pcall(PlayerPos)
    if not ok then continent = nil end
    local hereInfo = hereID and C_Map.GetMapInfo(hereID)
    local hereName = hereInfo and hereInfo.name

    local results = {}
    for _, t in ipairs(list) do
        local name, zone, where, fac, max = t[1], t[2], t[3], t[4], t[5]
        if (fac == "Both" or fac == faction) and max >= needSkill then
            local entry = { name = name, zone = zone, where = where, max = max }
            local z = zoneIndex and zoneIndex[zone]
            entry.mapID = z and z.mapID
            if zone == hereName then
                entry.dist = 0
            elseif z and continent then
                local tc, tx, ty = WorldPos(z.mapID, 0.5, 0.5)
                if tc == continent and tx then
                    entry.dist = math.sqrt((tx - px) ^ 2 + (ty - py) ^ 2)
                else
                    entry.far = true -- on another continent
                end
            end
            table.insert(results, entry)
        end
    end

    -- Nearest first; other continents after; unknown distances last.
    local function rank(e) return e.dist or (e.far and 1e8) or 1e9 end
    table.sort(results, function(a, b) return rank(a) < rank(b) end)
    while #results > (limit or 3) do table.remove(results) end
    return results
end

-- "in this zone", "~1,200 yd" or "another continent".
function Finder.DistanceText(e)
    if e.dist == 0 then return "in this zone" end
    if e.dist then
        local yards = math.floor(e.dist / 50 + 0.5) * 50
        local text = tostring(yards):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        return "~" .. text .. " yd"
    end
    if e.far then return "another continent" end
    return ""
end

-- Opens the world map on a trainer's zone.
function Finder.OpenMap(e)
    if e and e.mapID and OpenWorldMap then
        pcall(OpenWorldMap, e.mapID)
    elseif ToggleWorldMap then
        ToggleWorldMap()
    end
end

-- Which trainers you need: ones who teach your next rank if you're at
-- your cap, otherwise ones who teach recipes at your current rank.
function Finder.NeedSkill(skill, maxSkill)
    if not maxSkill then return 75 end -- not learned yet: any trainer
    if skill and skill >= maxSkill and maxSkill < 300 then return maxSkill + 75 end
    return maxSkill
end

-- /pg trainers: list the nearest five in chat.
function Finder.PrintNearest()
    local prof = ns.ActiveProf()
    local skill, maxSkill = ns.GetSkill(prof)
    local need = Finder.NeedSkill(skill, maxSkill)
    local list = Finder.Nearest(prof.name, need, 5)
    print("|cffffd100ProfGuide Forever: nearest " .. prof.name .. " trainers|r")
    if #list == 0 then
        print("  No trainer found for your faction and rank. Check the step's tip for books or quests.")
    end
    for _, e in ipairs(list) do
        print("  " .. e.name .. " - " .. e.zone .. ", " .. e.where .. "  |cff9d9d9d" .. Finder.DistanceText(e) .. "|r")
    end
    print("|cff9d9d9d  Tip: city guards will mark any trainer on your map.|r")
end
