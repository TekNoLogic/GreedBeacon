

local colorneed, colorgreed = "|cffff0000", "|cffffff00"
local coloredwords = {Greed = colorgreed.."Greed", Need = colorneed.."Need"}
local rolls = {}


local function FindRoll(link, player, hasselected, hasrolled)
	for i,roll in ipairs(rolls) do
		if roll._link == link and not roll._winner and (not roll[player] or hasselected) then return roll, i end
	end
	local newroll = {_link = link}
	table.insert(rolls, newroll)
	return newroll, #rolls
end


local function FindUnprintedRoll(link, player)
	for i,roll in ipairs(rolls) do
		if roll._link == link and roll[player] and (roll._printed or 0) < 7 then
			roll._printed = (roll._printed or 0) + 1
			return roll, i
		end
	end
end


local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_LOOT")
f:SetScript("OnEvent", function(self, event, msg)
	local rolltype, rollval, link, player = msg:match("(.+) Roll %- (%d+) for (.+) by (.+)")
	if player then
		local roll, i = FindRoll(link, player, true)
		roll[player] = (rolltype == "Need" and colorneed or colorgreed)..rollval
		roll._type = rolltype
		return
	end

	local player, selection, link = msg:match("(.*) has selected (.+) for: (.+)")
	if player then
		FindRoll(link, player)[player] = coloredwords[selection]
		return
	end

	local player, link = msg:match("(.*) won: (.+)")
	if player then
		local roll, i = FindRoll(link, player, true, true)
		roll._winner = player
	end
end)


local orig1 = ChatFrame_MessageEventHandler
function ChatFrame_MessageEventHandler(event, ...)
	if event == "CHAT_MSG_LOOT" then
--~ 		if arg1:match(" has selected .+ for: ") or (arg1:match(" passed on: ") and not arg1:match("Everyone passed on: ")) then return end

		local player, link = arg1:match("(.*) won: (.+)")
		if player then
			local roll, i = FindUnprintedRoll(link, player, true, true)
			arg1 = string.format("%s|Hgreedbeacon:%d|h[%s roll]|h|r %s won %s ", roll._type == "Need" and colorneed or colorgreed, 1, roll._type, player, link)
		end
	end
	return orig1(event, ...)
end


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
