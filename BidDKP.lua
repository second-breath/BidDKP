-- Global variables for tracking spec and bid values

local SELECTED_SPEC = nil
local CURRENT_MS_BID_DKP = 0
local CURRENT_OS_BID_DKP = 0
local CURRENT_SENDER = nil
local SOTA_TITLE = "SotA"
local BidDKP_TITLE = "BidDKP"
local ALLOW_OFF_SPEC_ROLL = true
local CURRENT_ROLL = {}

local AUCTION_STATE = 0
local DKP_AUCTION_STATE = 10
local ROLL_AUCTION_STATE = 20

-- Define bid increments/actions
local BidDKP_ROLL_CFG = {
    msRoll    = { min = 1, max = 100,    },
    osRoll    = { min = 1, max = 99,     },
    transmog  = { min = 1, max = 50,     },
}

function BidDKP_GetAuctionState() 
    return AUCTION_STATE
end

function BidDKP_SetAuctionState(state)
    local newState = tonumber(state)
    if not newState then return end

    AUCTION_STATE = newState
end

-- Create frame and register events to listen for
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("CHAT_MSG_RAID")
f:RegisterEvent("CHAT_MSG_RAID_LEADER")
f:RegisterEvent("CHAT_MSG_RAID_WARNING")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LOGIN")


-- Event handler function
function f_OnEvent()
	if (event == "ADDON_LOADED") then
        -- Show the minimap button when the addon is loaded
        if arg1 == BidDKP_TITLE then
            BidDKP_MinimapButtonFrame:Show()
            BidDKP_InitializeConfigSettings()
        end
	elseif (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") then
		-- Handle chat messages from raid and raid leader
		BidDKP_HandleRaidChatMessage(event, arg1, arg2, arg3, arg4)
    elseif (event == "CHAT_MSG_RAID_WARNING") then
		-- Handle raid warning messages
		BidDKP_HandleWarningRaidChatMessage(event, arg1, arg2, arg3, arg4)
    elseif ( event == "CHAT_MSG_SYSTEM" )  then 
        BidDKP_HandleSystemMessage(event, arg1, arg2, arg3, arg4)
    end
end

function BidDKP_DisableAllsBtn()
    getglobal("BidDKPFrameButton1"):Disable()
    getglobal("BidDKPFrameButton2"):Disable()
    getglobal("BidDKPFrameButton3"):Disable()
    getglobal("BidDKPFrameButton4"):Disable()
    getglobal("BidDKPFrameButton5"):Disable()
    getglobal("BidDKPFrameButton6"):Disable()
    getglobal("BidDKPFrameButton7"):Disable()
    getglobal("BidDKPFrameButton8"):Disable()
    getglobal("BidDKPFrameButton9"):Disable()
    getglobal("BidDKPFrameButton10"):Disable()
    getglobal("BidDKPFrameExtraButton1"):Disable()
    getglobal("BidDKPFrameExtraButton2"):Disable()
end

function BidDKP_EnableAllRollsBtn()
    getglobal("BidDKPFrameButton8"):Enable()
    getglobal("BidDKPFrameButton9"):Enable()
    getglobal("BidDKPFrameButton10"):Enable()
end

function BidDKP_DisableAllRollsBtn() 
    getglobal("BidDKPFrameButton8"):Disable()
    getglobal("BidDKPFrameButton9"):Disable()
    getglobal("BidDKPFrameButton10"):Disable()
end

function BidDKP_EnableAllDkpBtn() 
    getglobal("BidDKPFrameButton1"):Enable()
    getglobal("BidDKPFrameButton2"):Enable()
    getglobal("BidDKPFrameButton3"):Enable()
    getglobal("BidDKPFrameButton4"):Enable()
    getglobal("BidDKPFrameButton5"):Enable()
    getglobal("BidDKPFrameButton6"):Enable()
    getglobal("BidDKPFrameButton7"):Enable()
    getglobal("BidDKPFrameExtraButton1"):Enable()
    getglobal("BidDKPFrameExtraButton2"):Enable()
    getglobal("BidDKPFrameButton10"):Enable()
end

-- Displays a red warning message in the chat
function BidDKP_EchoWarning(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd700[Bid DKP] |r" .. "|cffff0000" .. message .. "|r")
end

-- Set selected spec to main
function BidDKP_OnSetMainSpec()
    SELECTED_SPEC = "ms"
end

-- Set selected spec to off
function BidDKP_OnSetOffSpec()
    SELECTED_SPEC = "os"
end

-- Clear selected spec
function BidDKP_OnClearSpec()
    SELECTED_SPEC = nil
end

-- Set the current main spec bid DKP and update UI input
function BidDKP_SetCurrentMainSpecBidDKP(dkp)
    if not dkp then return end
    CURRENT_MS_BID_DKP = tonumber(dkp)
    getglobal("BidDKPFrameInputBox"):SetText(tostring(CURRENT_MS_BID_DKP))
end

-- Set the current off spec bid DKP and update UI input
function BidDKP_SetCurrentOffSpecBidDKP(dkp)
    CURRENT_OS_BID_DKP = tonumber(dkp)
    getglobal("BidDKPFrameInputBox"):SetText(tostring(CURRENT_OS_BID_DKP))
end

-- Enable or disable offspec bidding
function BidDKP_CanRollOffspec(isOff)
    ALLOW_OFF_SPEC_ROLL = isOff
end

function BidDKP_SetCurrentSender(sender) 
    CURRENT_SENDER = sender
end 

function BidDKP_OnClearCurrentSender()
    CURRENT_SENDER = nil
end    

function IsSelfBidOwner()
    return BidDKP_GetCurrentPlayerName() == CURRENT_SENDER
end


-- Update the label that shows the current bidder and DKP
function BidDKP_UpdateLastBidder(sender, dkp)
    local frame = BidDKPFrame
    if frame and frame.lastBidderLabel then
        local displayText = string.format("Current bid: %s (%s DKP)", tostring(sender), tostring(dkp))
        frame.lastBidderLabel:SetText(displayText)
    end
end

function BidDKP_UpdateLastRoll(sender, typeRoll, rollValue)
    local frame = BidDKPFrame
    if frame and frame.LastRollLabel then
        local displayText = string.format("Max roll: %s (%s) %s roll", tostring(sender), tostring(typeRoll),tostring(rollValue))
        frame.LastRollLabel:SetText(displayText)
    end
end

-- Capitalize the first letter of a string
function BidDKP_UCFirst(msg)
	if not msg then return "" end
	local f = string.sub(msg, 1, 1)
	local r = string.sub(msg, 2)
	return string.upper(f) .. string.lower(r)
end

-- Process raid chat messages and check for bids
function BidDKP_HandleRaidChatMessage(event, message, sender)
	if not message or message == "" then return end

	local _, _, command = string.find(message, "(%a+)")
    local _, _, _, passWord, highestWord, lastBidder, dkp = string.find(
        message,
        "^(%a+)%s+(passed);%s+(highest)%s+bid%s+is%s+now%s+by%s+(%a+)%s+for%s+(%d+)%s+DKP$"
    )


    if passWord == "passed" and highestWord == "highest" and lastBidder and dkp then
        BidDKP_HandlePlayerBid(lastBidder, "pass " .. dkp)
    end

	if not command then return end

	cmd = string.lower(command)

	if cmd == "bid" or cmd == "os" or cmd == "ms" then
		BidDKP_HandlePlayerBid(sender, message)
	end
end

-- Parse player bid messages and apply them
function BidDKP_HandlePlayerBid(sender, message)
	local cmd, arg
	local spacepos = string.find(message, "%s")
	if spacepos then
		_, _, cmd, arg = string.find(string.lower(message), "(%S+)%s+(.+)")
	else
		return
	end	

    if arg == 'max' then
        arg = BidDKP_GetGuildDKPForPlayer(sender)
    end 

    if CURRENT_MS_BID_DKP and tonumber(CURRENT_MS_BID_DKP) >= tonumber(arg) then
        return
    end

    BidDKP_SetCurrentSender(sender)

    if cmd == 'ms' then 
        if ALLOW_OFF_SPEC_ROLL then BidDKP_CanRollOffspec(false) end    
        BidDKP_SetCurrentMainSpecBidDKP(arg)
        BidDKP_UpdateLastBidder(sender, arg)
        return
    elseif cmd == 'os' then
        BidDKP_SetCurrentOffSpecBidDKP(arg)
        BidDKP_UpdateLastBidder(sender, arg)
        return
    elseif cmd == "pass" then
        BidDKP_SetCurrentMainSpecBidDKP(arg)
        BidDKP_SetCurrentOffSpecBidDKP(arg)
        BidDKP_UpdateLastBidder(sender, arg)
        return
    end
end


-- Parse special formatted raid warning messages (start, cancel, end auction)
function BidDKP_HandleWarningRaidChatMessage(event, message)
	if not message or message == "" then return end

	local _, _, auctionOpen, openWord, item = string.find(message, "^%[SotA%]%s+(%a+)%s+(%a+)%s+for%s+(.+)$")
	if auctionOpen == "Auction" and openWord == "open" then
        BidDkp_ClearAuctionDisplay()
        BidDKP_InitBidDKP()
        BidDKP_DisableAllsBtn()
        BidDKP_EnableAllDkpBtn()
        BidDKP_SetAuctionState(DKP_AUCTION_STATE)
        BidDkp_StartAuction(item)
		return
	end

    local _, _, auctionOpen, openWord, item = string.find(message, "^%[SotA%]%s+(%a+)%s+(%a+)%s+for%s+(.+)$")

	if auctionOpen == "Roll" and openWord == "open" then
        BidDkp_ClearAuctionDisplay()
        BidDKP_InitBidDKP()
        BidDKP_DisableAllsBtn()
        BidDKP_EnableAllRollsBtn()
        BidDKP_SetAuctionState(ROLL_AUCTION_STATE)
        BidDkp_StartAuction(item)
		return
	end

	local _, _, auctionCancel, cancelWord = string.find(message, "^%[SotA%]%s+(%a+)%s+was%s+(%a+)$")
	if auctionCancel == "Auction" and cancelWord == "Cancelled" then
        BidDkp_ClearAuctionDisplay()
        if BidDKP_isAutoCloseWindow() then 
            BidDKPFrame:Hide()
        end   
		return
	end

	local _, _, auctionOver, overWord = string.find(message, "^%[SotA%]%s+(%a+)%s+for%s+.+%s+is%s+(%a+)$")
	if auctionOver == "Auction" and overWord == "over" then
        BidDkp_ClearAuctionDisplay()
        if BidDKP_isAutoCloseWindow() then 
            BidDKPFrame:Hide()
        end 
		return
	end
end


function BidDKP_HandleSystemMessage(event, message)
    if not message or message == "" then return end

    local _, _, player, roll, minv, maxv = string.find(message, "^([^%s]+) rolls (%d+) %((%d+)%-(%d+)%)$")
    if not player then return end

    roll = tonumber(roll); minv = tonumber(minv); maxv = tonumber(maxv)
    if not (roll and minv and maxv) then return end

    local rtype = BidDKP_TypeFromRange(minv, maxv)
    rtype = BidDKP_NormalizeType(rtype)
    if not rtype then return end

    if BidDKP_GetAuctionState() == DKP_AUCTION_STATE then
        if rtype ~= "tmog" then
            return
        end
    end 

    local candidate = { name = player, type = rtype, rollValue = roll, minv = minv, maxv = maxv }

    if BidDKP_ShouldReplaceRoll(CURRENT_ROLL, candidate) then
        CURRENT_ROLL = candidate
        BidDKP_UpdateLastRoll(CURRENT_ROLL.name, CURRENT_ROLL.type, CURRENT_ROLL.rollValue)
    end
end



-- Clear input box and reset current bid DKP values
function BidDKP_OnClearInputValue()
    getglobal("BidDKPFrameInputBox"):SetText("")
    CURRENT_MS_BID_DKP = 0
    CURRENT_OS_BID_DKP = 0
    CURRENT_ROLL = {}

end

-- Reset the auction UI elements
function BidDkp_ClearAuctionDisplay()
    local frame = getglobal("BidDKPFrame")

    if frame.itemButton and frame.itemButton.text then
        frame.itemButton.text:SetText("")
        frame.itemButton.link = nil
    end

    if frame.itemIcon then
        frame.itemIcon:SetTexture(nil)
        frame.itemIcon:Hide()
    end

    if frame.lastBidderLabel then 
        frame.lastBidderLabel:SetText("")
    end 

    if frame.LastRollLabel then 
        frame.LastRollLabel:SetText("")
    end 

    getglobal("BidDKPFrameExtraButton1"):Enable()
    getglobal("BidDKPFrameExtraButton2"):Enable()

    BidDKP_OnClearCurrentSender()
    BidDKP_CanRollOffspec(true)
    BidDKP_OnClearSpec()
    BidDKP_OnClearInputValue()
    BidDKP_SetAuctionState(AUCTION_STATE)

end

-- Extract DKP value from the input field
function BidDKP_GetDKPFromInput() 
	local input = getglobal("BidDKPFrameInputBox"):GetText()
	local startPos, endPos = string.find(input, "%d+")
	local dkpStr

	if startPos then
		dkpStr = string.sub(input, startPos, endPos)
	end

	local playerDkp = tonumber(dkpStr)
	if not playerDkp then return end
	return playerDkp
end

-- Send bid message to the raid chat
function BidDKP_OnSendPlayerBidFromRaidChat(bid)
    if not BidDKP_IsPlayerInRaid() then
        BidDKP_EchoWarning("You must be in a raid!")
        return
    end

    if not SELECTED_SPEC then 
        BidDKP_EchoWarning('You must choose main/off spec before bidding.')
        return
    end

    if BidDKP_isPreventSelfOverbid() and IsSelfBidOwner() then
        BidDKP_EchoWarning('Bid submitted successfully. Waiting for the next bidder')
        return
    end    

    if SELECTED_SPEC == "os" and not ALLOW_OFF_SPEC_ROLL then 
        BidDKP_EchoWarning("You cannot OS bid if an MS bid is already made.")
        return
    end 

    local currentBidDKp = (SELECTED_SPEC == "os") and CURRENT_OS_BID_DKP or CURRENT_MS_BID_DKP
    local playerDkp = BidDKP_GetCurrentPlayerDKP()

    if not playerDkp then
        BidDKP_EchoWarning('Loading guild data, please wait...')
        return
    end

    local currentBidValue = math.ceil(currentBidDKp)

    if playerDkp <= currentBidValue and bid ~= "pass" and bid ~= "all" then
        BidDKP_EchoWarning("You don't have enough DKP to bid.")
        return
    end

    local bidActions = {
        ["10"] = function() return currentBidValue + 10 end,
        ["50"] = function() return currentBidValue + 50 end,
        ["100"] = function() return currentBidValue + 100 end,
        ["inputDKP"] = function()
            local inputDkp = BidDKP_GetDKPFromInput()
            if inputDkp then return inputDkp end
        end,
        -- ["all"] = function() return "max" end,
        ["all"] = function() return BidDKP_GetCurrentPlayerDKP() end,
        ["pass"] = function() return "pass" end,
    }

    local action = bidActions[bid]

    if action then
        local value = action()
        if value then
            if value == "pass" then
                if IsSelfBidOwner() then
                    SendChatMessage("pass", "RAID")
                else
                    BidDKP_EchoWarning("You can only pass if you have the latest bid!")
                end
            else
                local message = SELECTED_SPEC .. " " .. tostring(value)
                SendChatMessage(message, "RAID")
            end
        end
    end
end

function BidDKP_HandleRoll(typeRoll, itemLink)
    local cfg = BidDKP_ROLL_CFG[typeRoll]
    if not cfg then
        return
    end
    
    -- perform the actual roll
    if RandomRoll then
        RandomRoll(cfg.min, cfg.max)         
    end
    BidDKP_DisableAllRollsBtn()
end


-- Create a font label to display the current bidder name and DKP
local function BidDKP_GetOrCreateLabel(parentFrame, key, anchorTo, x, y, font, size, template)
    if not parentFrame or not key then return nil end
    local label = parentFrame[key]
    if not label then
        label = parentFrame:CreateFontString(nil, "ARTWORK", template or "GameFontNormal")
        label:SetFont(font or "Fonts\\FRIZQT__.TTF", size or 14)
        label:SetText("")
        parentFrame[key] = label
    end
    if anchorTo then
        label:ClearAllPoints()
        label:SetPoint("TOP", anchorTo, "BOTTOM", x or 0, y or -8)
    end
    return label
end

-- Start auction UI and show item info
function BidDkp_StartAuction(itemLink)
    local _, _, itemId = string.find(itemLink, "item:(%d+):")
    if not itemId then
        BidDKP_EchoWarning("Item was not found: " .. itemLink)
        return
    end

    local itemName, itemLinkFull, itemQuality, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
    if not itemName then
        BidDKP_EchoWarning("Item data is not loaded yet.")
        return
    end


    local frame = getglobal("BidDKPFrame")
    local headerTexture = getglobal(frame:GetName().."HeaderTexture")

    -- Create item icon if not exists
    if not frame.itemIcon then
        frame.itemIcon = frame:CreateTexture(nil, "ARTWORK")
        frame.itemIcon:SetWidth(32)
        frame.itemIcon:SetHeight(32)
        frame.itemIcon:SetPoint("BOTTOM", headerTexture, "BOTTOM", -90, -15)
    end
    frame.itemIcon:SetTexture(itemTexture)
    frame.itemIcon:Show()

    -- Create clickable item button if not exists
    if not frame.itemButton then
        frame.itemButton = CreateFrame("Button", nil, frame)
        frame.itemButton:SetWidth(150)
        frame.itemButton:SetHeight(16)
        frame.itemButton:SetPoint("LEFT", frame.itemIcon, "RIGHT", 5, 0)

        local text = frame.itemButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        text:SetAllPoints()
        text:SetFont("Fonts\\FRIZQT__.TTF", 14)
        text:SetJustifyH("LEFT")
        frame.itemButton.text = text

        -- Tooltip for the item
        frame.itemButton:SetScript("OnEnter", function()
            if frame.itemButton.link then
                GameTooltip:SetOwner(frame.itemButton, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(frame.itemButton.link)
                GameTooltip:Show()
            end
        end)

        frame.itemButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    frame.itemButton.link = itemLinkFull
    frame.itemButton.text:SetText(itemLink)

    local r, g, b = GetItemQualityColor(itemQuality or 1)
    frame.itemButton.text:SetTextColor(r, g, b, 1)
    
end

-- Trigger DKP bidding UI
function BidDKP_OnClickBidDKP() 
    BidDKP_InitBidDKP()
end

-- Initialize the DKP UI and label
function BidDKP_InitBidDKP()
    if not BidDKPFrame then return end
    BidDKPFrame:Show()
    if BidDKP_UpdateCurrentPlayerDKP then BidDKP_UpdateCurrentPlayerDKP() end

    local anchor1 = getglobal("BidDKPFrameExtraButton1")
    local anchor2 = getglobal("BidDKPFrameButton9")

    if anchor1 then
        BidDKP_GetOrCreateLabel(BidDKPFrame, "lastBidderLabel", anchor1, 30, -8, "Fonts\\FRIZQT__.TTF", 14, "GameFontNormal")
    end

    if anchor2 then
        BidDKP_GetOrCreateLabel(BidDKPFrame, "LastRollLabel", anchor2, 0, 50, "Fonts\\FRIZQT__.TTF", 14, "GameFontNormal")
    end
end


-- Register the main event handler
f:SetScript("OnEvent", f_OnEvent)