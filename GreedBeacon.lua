local YOU = "Ihr"; -- "You", the player
local GREED = "Gier";
local NEED = "Bedarf";

--~ local L = setmetatable(GetLocale() == "deDE" and {
local L = setmetatable({
}, {__index = function(t,i) return i end})
--~ } or {}, {__index = function(t,i) return i end})

local colorneed, colorgreed = "|cffff0000", "|cffffff00"
local coloredwords = {Greed = colorgreed.."Greed", Need = colorneed.."Need"}
local rolls = {}

local function Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99GreedBeacon|r:", ...)) end

local function Debug(...) ChatFrame1:AddMessage(string.join(", ", ...)) end


local chatframes = {[ChatFrame1] = false, [ChatFrame2] = false, [ChatFrame3] = false, [ChatFrame4] = false, [ChatFrame5] = false, [ChatFrame6] = false, [ChatFrame7] = false}
for frame in pairs(chatframes) do
	for i,v in pairs(frame.messageTypeList) do
		if v == "LOOT" then
			chatframes[frame] = true
			Debug("Initializing", frame:GetName())
		end
	end
end

local origadd, origrem = ChatFrame_AddMessageGroup, ChatFrame_RemoveMessageGroup
ChatFrame_AddMessageGroup = function(frame, channel, ...)
	if channel == "LOOT" then
		chatframes[frame] = true
		Debug("ChatFrame_AddMessageGroup", frame:GetName())
	end
	return origadd(frame, channel, ...)
end
ChatFrame_RemoveMessageGroup = function(frame, channel, ...)
	if channel == "LOOT" then
		chatframes[frame] = false
		Debug("ChatFrame_RemoveMessageGroup", frame:GetName())
	end
	return origrem(frame, channel, ...)
end


local function FindRoll(link, player, hasselected)
	for i,roll in ipairs(rolls) do
		if roll._link == link and not roll._winner and (not roll[player] or hasselected) then return roll end
	end
	Debug("New roll started", link)
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
		Debug("Roll detected", player, rolltype, rollval, link)
		roll[player] = (rolltype == "Need" and colorneed or colorgreed)..rollval
		roll._type = rolltype
		return
	end

	local player, selection, link = msg:match("(.*) has?v?e? selected (.+) for: (.+)")
	if player then
		player = player == "You" and UnitName("player") or player
		Debug("Selection detected", player, selection, link)
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
				Debug("Roll completed", roll._type or "nil", i, player, link)
				local msg = string.format("%s|Hgreedbeacon:%d|h[%s roll]|h|r %s won %s ", roll._type == "Need" and colorneed or colorgreed, i, roll._type or "???", player, link)
				for frame,val in pairs(chatframes) do if val then frame:AddMessage(msg) end end
				return
			end
		end
		Print("No match found for", msg)
		return
	end
end)


local function filter(msg)
	if msg:match("(.*) won: (.+)") or msg:match(" has?v?e? selected .+ for: ") or msg:match(" Roll . %d+ for .+ by ") or (msg:match(" passed on: ") and not msg:match("Everyone passed on: ")) then
		Debug("Supressing chat message", msg)
		return true
	end
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", filter)


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


-- Debugging event generator
local oe = f:GetScript("OnEvent")
local function e(msg)
	Print(msg)
	oe(f, "CHAT_MSG_LOOT", msg)
	filter(msg)
end

local LOOT_ROLL_ALL_PASSED = "Alle haben gepasst bei: %s";
local LOOT_ROLL_GREED =        "%s hat f\195\188r %s 'Gier' ausgew\195\164hlt";
local LOOT_ROLL_GREED_SELF = "Ihr habt f\195\188r %s 'Gier' ausgew\195\164hlt";
local LOOT_ROLL_NEED =         "%s hat f\195\188r %s 'Bedarf' ausgew\195\164hlt";
local LOOT_ROLL_NEED_SELF =  "Ihr habt f\195\188r %s 'Bedarf' ausgew\195\164hlt";
local LOOT_ROLL_PASSED =      "%s w\195\188rfelt nicht f\195\188r: %s";
local LOOT_ROLL_PASSED_SELF =   "Ihr habt gepasst bei: %s";
local LOOT_ROLL_PASSED_AUTO =        "%1$s passt automatisch bei %2$s, weil er den Gegenstand nicht benutzen kann.";
local LOOT_ROLL_PASSED_AUTO_FEMALE = "%1$s passt automatisch bei %2$s, weil sie den Gegenstand nicht benutzen kann.";
local LOOT_ROLL_PASSED_SELF_AUTO = "Ihr passt automatisch bei %s, weil Ihr den Gegenstand nicht benutzen k\195\182nnt.";
local LOOT_ROLL_ROLLED_GREED =  "Wurf f\195\188r Gier: %d f\195\188r %s von %s"; -- First %s is item, second %s is player name
local LOOT_ROLL_ROLLED_NEED = "Wurf f\195\188r Bedarf: %d f\195\188r %s von %s"; -- First %s is item, second %s is player name
local LOOT_ROLL_WON = "%s gewinnt: %s";
local LOOT_ROLL_WON_NO_SPAM_GREED = "%1$s gewinnt: %3$s |cff818181(Gier - %2$d)|r";
local LOOT_ROLL_WON_NO_SPAM_NEED = "%1$s gewinnt: %3$s |cff818181(Bedarf - %2$d)|r";
local LOOT_ROLL_YOU_WON = "Ihr gewinnt: %s";
local YOU = "Ihr"; -- "You", the player

local _, link = GetItemInfo(6948)
e(string.format(LOOT_ROLL_NEED, "Joe", link))
e(string.format(LOOT_ROLL_NEED_SELF, link))
e(string.format(LOOT_ROLL_GREED, "Bob", link))
e(string.format(LOOT_ROLL_PASSED, "Ike", link))
e(string.format(LOOT_ROLL_ROLLED_NEED, 85, link, "Joe"))
e(string.format(LOOT_ROLL_ROLLED_NEED, 8, link, UnitName("player")))
e(string.format(LOOT_ROLL_WON, "Joe", link))

local _, link = GetItemInfo(33809)
e(string.format(LOOT_ROLL_GREED, "Joe", link))
e(string.format(LOOT_ROLL_GREED_SELF, link))
e(string.format(LOOT_ROLL_GREED, "Bob", link))
e(string.format(LOOT_ROLL_PASSED, "Ike", link))
e(string.format(LOOT_ROLL_ROLLED_GREED, 42, link, "Joe"))
e(string.format(LOOT_ROLL_ROLLED_GREED, 99, link, UnitName("player")))
e(string.format(LOOT_ROLL_ROLLED_GREED, 70, link, "Bob"))
e(string.format(LOOT_ROLL_ROLLED_GREED, 91, link, "Ike"))
e(string.format(LOOT_ROLL_WON, YOU, link))

local _, link = GetItemInfo(11411)
e(string.format(LOOT_ROLL_PASSED_AUTO, "Joe", link))
e(string.format(LOOT_ROLL_PASSED_AUTO_FEMALE, "May", link))
e(string.format(LOOT_ROLL_PASSED_SELF, link))
e(string.format(LOOT_ROLL_ALL_PASSED, link))
