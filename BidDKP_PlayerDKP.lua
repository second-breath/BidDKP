-- === BidDKP DKP Management Functions (Renamed & Documented) ===

local CURRENT_PLAYER_DKP = 0

-- Sets the current player's DKP value (local cache)
function BidDKP_SetCurrentPlayerDKP(dkp)
    CURRENT_PLAYER_DKP = tonumber(dkp)
end

-- Gets the current player's name (from WoW API)
function BidDKP_GetCurrentPlayerName()
    local player = UnitName("player")
    return player
end

-- Gets the locally cached DKP for the current player
function BidDKP_GetCurrentPlayerDKP()
    return CURRENT_PLAYER_DKP
end

-- Checks if the player can read officer notes (guild permissions)
function BidDKP_CanReadOfficerNotes()
    local result = CanViewOfficerNote()
    if not result then return end
    return result
end

-- Returns true if the player is currently in a raid
function BidDKP_IsPlayerInRaid()
    return (GetNumRaidMembers() > 0)
end

-- Retrieves the DKP for a specific player by checking guild officer notes
function BidDKP_GetGuildDKPForPlayer(name)
    local playerInfo = BidDKP_ExtractPlayerDKPFromGuildRoster(name)
    if not playerInfo then return end
    return 1 * playerInfo
end

-- Updates the current player's DKP by retrieving it from the guild roster
function BidDKP_UpdateCurrentPlayerDKP()
    local name = BidDKP_GetCurrentPlayerName()
    local playerDkp = BidDKP_GetGuildDKPForPlayer(name)
    BidDKP_SetCurrentPlayerDKP(playerDkp)
end

-- Extracts DKP from the guild roster for a given player
function BidDKP_ExtractPlayerDKPFromGuildRoster(playerName)
    local memberCount = GetNumGuildMembers(true)
    local playerDkp = 0

    for n = 1, memberCount do
        local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(n)
        local note = officerNote or "<0>"

        local _, _, mainChar = string.find(note, "%[(.-)%]")
        local dkp = 0

        if mainChar and mainChar ~= name then
            mainChar = BidDKP_UCFirst(mainChar)
            dkp = BidDKP_LookupDKPByPlayerName(mainChar)
        else
            local _, _, dkpRaw = string.find(note, "<(-?%d*)>")
            if dkpRaw then
                dkp = tonumber(dkpRaw) or 0
            end
        end

        if playerName == name then
            playerDkp = (1 * dkp)
        end
    end

    return playerDkp
end

-- Looks up DKP by player name (no parsing of main-alt linkage)
function BidDKP_LookupDKPByPlayerName(playerName)
    playerName = BidDKP_UCFirst(playerName)
    local memberCount = GetNumGuildMembers(true)

    for n = 1, memberCount do
        local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(n)
        name = BidDKP_UCFirst(name)

        if playerName == name then
            local note = officerNote or "<0>"
            local _, _, dkp = string.find(note, "<(-?%d*)>")
            return tonumber(dkp) or 0
        end
    end

    return 0
end