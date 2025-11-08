local CURRENT_PLAYER_DKP = 0


function BidDKP_SetPlayerDKP(dkp)
    CURRENT_PLAYER_DKP = tonumber(dkp);
end 

function BidDKP_GetPlayerName()
    local player  = UnitName("player");
    return player
end

function BidDKP_GetPlayerDKP()
    return CURRENT_PLAYER_DKP
end 

function BidDKP_CanReadNotes()
	local result = CanViewOfficerNote();
    if not result then
        return
    end
	return result
end

function BidDKP_IsInRaid()
	local result = ( GetNumRaidMembers() > 0 )
	return result
end

function BidDKP_GetPlayerDKPFromGuildList(name) 
    local playerInfo = SOTA_GetGuildPlayerInfo(name);
	if not playerInfo then
		return;
	end

    local availableDkp = 1 * (playerInfo[2]);

    return availableDkp
end

function BidDKP_HandlePlayerDKP()
    local name = BidDKP_GetPlayerName()

	local playerDkp

	playerDkp = BidDKP_GetPlayerDKPFromGuildList(name)
	if not playerDkp then 
		playerDkp = BidDKP_GetPlayerDkp(name)
	end 	
	BidDKP_SetPlayerDKP(playerDkp)
end    



function BidDKP_GetGuildPlayerInfo(player)
	player = BidDKP_UCFirst(player);

	for n=1, table.getn(GuildRosterTable), 1 do
		if GuildRosterTable[n][1] == player then
			return GuildRosterTable[n];
		end
	end
	
	return nil;
end


function BidDKP_GetPlayerDkp(playerName)
	local memberCount = GetNumGuildMembers(true);
    local playerDkp = 0
	for n = 1, memberCount do
		local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(n)

		local note = officerNote or "<0>"

		

		local _, _, mainChar = string.find(note, "%[(.-)%]")
		local dkp = 0
		if mainChar and mainChar ~= name then
			mainChar = BidDKP_UCFirst(mainChar)
			dkp = BidDKP_GetPlayerDkpByName(mainChar)
		else
			local _, _, dkpRaw = string.find(note, "<(-?%d*)>")
            if dkpRaw then
                dkp = tonumber(dkpRaw) or 0
            end
		end
		if playerName == name then 
			playerDkp = (1 * dkp) ;
		end
	end
	
	return playerDkp
end

function BidDKP_GetPlayerDkpByName(playerName)
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