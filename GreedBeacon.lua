
local L = setmetatable(GetLocale() == "deDE" and {
	["(.*) won: (.+)"] = "(.*) gewinnt: (.+)",
	["%s|Hgreedbeacon:%d|h[%s roll]|h|r %s won %s "] = "%s|Hgreedbeacon:%d|h[%s roll]|h|r %s gewinnt: %s",
	["(.*) has?v?e? selected (.+) for: (.+)"] = "(.+) hab?t f\195\188r (.+) '(.+)' ausgew\195\164hlt",
	["(.+) Roll . (%d+) for (.+) by (.+)"] = "Wurf f\195\188r (.*): (%d+) f\195\188r (.*) von (.*)",
	[" passed on: "] = " w\195\188rfelt nicht f\195\188r: ",
	[" automatically passed on: "] = " passt automatisch bei ",
	["You passed on: "] = "Ihr habt gepasst bei: ",
	["Everyone passed on: "] = "Alle haben gepasst bei: ",
	["Greed"] = GREED,
	["Need"] = NEED,
} or GetLocale() == "ruRU" and {
	["(.*) won: (.+)"] = "(.*) \208\178\209\139\208\184\208\179\209\128\209\139\208\178\208\176\208\181\209\130: (.+)",
	["%s|Hgreedbeacon:%d|h[%s roll]|h|r %s won %s "] = "%s|Hgreedbeacon:%d|h[%s roll]|h|r %s \208\178\209\139\208\184\208\179\209\128\209\139\208\178\208\176\208\181\209\130: %s",
	["(.*) has?v?e? selected (.+) for: (.+)"] = "\208\160\208\176\208\183\209\139\208\179\209\128\209\139\208\178\208\176\208\181\209\130\209\129\209\143 \208\191\209\128\208\181\208\180\208\188\208\181\209\130: (.+). (.*) \208\179\208\190\208\178\208\190\209\128\208\184\209\130: (.+)",
	["(.+) Roll . (%d+) for (.+) by (.+)"] = "\208\160\208\181\208\183\209\131\208\187\209\140\209\130\208\176\209\130 \208\177\209\128\208\190\209\129\208\186\208\176 (.*) \208\183\208\176 \208\191\209\128\208\181\208\180\208\188\208\181\209\130 (.*): (%d+)",
	[" passed on: "] = " \208\190\209\130\208\186\208\176\208\183\209\139\208\178\208\176\208\181\209\130\209\129\209\143 \208\190\209\130 \208\191\209\128\208\181\208\180\208\188\208\181\209\130\208\176: ",
	[" automatically passed on: "] = " \208\191\208\190\209\129\208\186\208\190\208\187\209\140\208\186\209\131 \208\189\208\181 \208\188\208\190\208\182\208\181\209\130 \208\181\208\179\208\190 \208\183\208\176\208\177\209\128\208\176\209\130\209\140.",
	["You passed on: "] = "\208\146\209\139 \208\190\209\130\208\186\208\176\208\183\208\176\208\187\208\184\209\129\209\140 \208\190\209\130 \208\191\209\128\208\181\208\180\208\188\208\181\209\130\208\176: ",
	["Everyone passed on: "] = ": \208\191\209\128\208\181\208\180\208\188\208\181\209\130 \208\189\208\184\208\186\208\190\208\188\209\131 \208\189\208\181 \208\189\209\131\208\182\208\181\208\189.",
	["Greed"] = GREED,
	["Need"] = NEED,
} or {}, {__index = function(t,i) return i end})

local colorneed, colorgreed, colorde = "|cffff0000", "|cffffff00", "|cffff00ff"
local rollcolors, coloredwords = {[L.Disenchant] = colorde, [L.Greed] = colorgreed, [L.Need] = colorneed}, {}
for i,v in pairs(rollcolors) do coloredwords[i] = v..i end
local rolls, db = {}

local function Print(...) print("|cFF33FF99GreedBeacon|r:", ...) end

local debugf = tekDebug and tekDebug:GetFrame("GreedBeacon")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end


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
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
	if addon:lower() ~= "greedbeacon" then return end

	GreedBeaconDB = GreedBeaconDB or {}
	db = GreedBeaconDB
	if not db.frame then
		db.frame = "ChatFrame1"
		for i=7,1,-1 do
			local name = "ChatFrame"..i
			for i,v in pairs(_G[name].messageTypeList) do if v == "LOOT" then db.frame = name end end
		end
		Debug("Initializing DB to", db.frame)
	end

	f:UnregisterEvent("ADDON_LOADED")
	f:RegisterEvent("CHAT_MSG_LOOT")
	f:SetScript("OnEvent", function(self, event, msg)
		local rolltype, rollval, link, player = msg:match(L["(.+) Roll . (%d+) for (.+) by (.+)"])
		if player then
			local roll = FindRoll(link, player, true)
			Debug("Roll detected", player, rolltype, rollval, link)
			roll[player] = rollcolors[rolltype]..rollval
			roll._type = rolltype
			return
		end

		local player, selection, link = msg:match(L["(.*) has?v?e? selected (.+) for: (.+)"])
		if player and player ~= "" then
			player = player == YOU and UnitName("player") or player
			Debug("Selection detected", player, selection, link)
			FindRoll(link, player)[player] = coloredwords[selection]
			return
		end

		local player, link = msg:match(L["(.*) won: (.+)"])
		if player then
			player = player == YOU and UnitName("player") or player
			for i,roll in ipairs(rolls) do
				if roll._link == link and roll[player] and not roll._printed then
					local rolltype = roll._type == L.Need and L.Need or L.Greed
					roll._printed = true
					roll._winner = player
					Debug("Roll completed", rolltype or "nil", i, player, link)
					local msg = string.format(L["%s|Hgreedbeacon:%d|h[%s roll]|h|r %s won %s "], rollcolors[rolltype], i, rolltype, player, link)
					_G[db.frame]:AddMessage(msg)
					return
				end
			end
			Print("ERROR: No match found for", msg)
			return
		end
	end)
end)


ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", function(self, event, msg)
	if msg:match(L["(.*) won: (.+)"]) or msg:match(L["(.*) has?v?e? selected (.+) for: (.+)"]) or msg:match(L["(.+) Roll . (%d+) for (.+) by (.+)"])
		or msg:match(L["You passed on: "]) or msg:match(L[" automatically passed on: "]) or (msg:match(L[" passed on: "]) and not msg:match(L["Everyone passed on: "])) then
		Debug("Supressing chat message", msg)
		return true
	end
end)


local orig2 = SetItemRef
function SetItemRef(link, text, button)
	local id = link:match("greedbeacon:(%d+)")
	if id then
		ShowUIPanel(ItemRefTooltip)
		if not ItemRefTooltip:IsShown() then ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE") end

		local roll = rolls[tonumber(id)]
		local rolltype = roll._type == L.Need and coloredwords[L.Need] or coloredwords[L.Greed]
		ItemRefTooltip:ClearLines()
		ItemRefTooltip:AddLine(rolltype.." roll|r - "..roll._link)
		ItemRefTooltip:AddDoubleLine("Winner:", "|cffffffff"..roll._winner)
		for i,v in pairs(roll) do if string.sub(i, 1, 1) ~= "_" then ItemRefTooltip:AddDoubleLine(i, v) end end
		ItemRefTooltip:Show()
	else return orig2(link, text, button) end
end
