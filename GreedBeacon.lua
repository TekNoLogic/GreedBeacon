

local colorneed, colorgreed = "|cffff0000", "|cffffff00"
local coloredwords = {Greed = colorgreed.."Greed", Need = colorneed.."Need"}
local rolls = {}


local function FindRoll(link, player, hasselected)
	for i,roll in ipairs(rolls) do
		if roll._link == link and not roll._winner and (not roll[player] or hasselected) then return roll end
	end
	local newroll = {_link = link}
	table.insert(rolls, newroll)
	return newroll
end


local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_LOOT")
f:SetScript("OnEvent", function(self, event, msg)
	local rolltype, rollval, link, player = msg:match("(.+) Roll . (%d+) for (.+) by (.+)")
	if player then
		local roll = FindRoll(link, player, true)
		roll[player] = (rolltype == "Need" and colorneed or colorgreed)..rollval
		roll._type = rolltype
		return
	end

	local player, selection, link = msg:match("(.*) has?v?e? selected (.+) for: (.+)")
	if player then
		player = player == "You" and UnitName("player") or player
		FindRoll(link, player)[player] = coloredwords[selection]
		return
	end

	local player, link = msg:match("(.*) won: (.+)")
	if player then
		player = player == "You" and UnitName("player") or player
		for i,roll in ipairs(rolls) do
			if roll._link == link and roll[player] and not roll._printed then
				roll._printed = true
				roll._winner = player
				ChatFrame6:AddMessage(string.format("%s|Hgreedbeacon:%d|h[%s roll]|h|r %s won %s ", roll._type == "Need" and colorneed or colorgreed, i, roll._type or "???", player, link))
				return
			end
		end
		ChatFrame6:AddMessage("GB NO MATCH: "..msg)
		return
	end
end)


ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", function(msg)
	if msg:match("(.*) won: (.+)")
		or msg:match(" has?v?e? selected .+ for: ")
		or msg:match(" Roll . %d+ for .+ by ")
		or (msg:match(" passed on: ") and not msg:match("Everyone passed on: ")) then return true end
end)


local orig2 = SetItemRef
function SetItemRef(link, text, button)
	local id = link:match("greedbeacon:(%d+)")
	if id then
		ShowUIPanel(ItemRefTooltip)
		if not ItemRefTooltip:IsShown() then ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE") end

		local i = tonumber(id)
		local val = rolls[i]
		ItemRefTooltip:ClearLines()
		ItemRefTooltip:AddLine(coloredwords[val._type].." roll|r - "..val._link)
		ItemRefTooltip:AddDoubleLine("Winner:", "|cffffffff"..val._winner)
		for i,v in pairs(val) do if string.sub(i, 1, 1) ~= "_" then ItemRefTooltip:AddDoubleLine(i, v) end end
		ItemRefTooltip:Show()
	else return orig2(link, text, button) end
end


--~ local oe = f:GetScript("OnEvent")
--~ local function e(event, a1)
--~ 	oe(f, event, a1)
--~ 	this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 = ChatFrame1, event, a1, nil, nil, ""
--~ 	ChatFrame_MessageEventHandler(event)
--~ end

--~ local name, link = GetItemInfo(6948)
--~ e("CHAT_MSG_LOOT", "Bob has selected Greed for: "..link)
--~ e("CHAT_MSG_LOOT", "Joe has selected Need for: "..link)
--~ e("CHAT_MSG_LOOT", "Mary has selected Need for: "..link)
--~ e("CHAT_MSG_LOOT", "Jane passed on: "..link)
--~ e("CHAT_MSG_LOOT", "Need Roll - 56 for "..link.." by Joe")
--~ e("CHAT_MSG_LOOT", "Need Roll - 5 for "..link.." by Mary")
--~ e("CHAT_MSG_LOOT", "Joe won: "..link)
