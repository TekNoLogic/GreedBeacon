local dewdrop = AceLibrary("Dewdrop-2.0")
local tablet = AceLibrary("Tablet-2.0")

local colorneed, colorgreed, colorpass = "|cffff0000", "|cffffff00", "|cffdddddd"
local tokens, rolls, openrolls = {}, {}, 0
local tokensgreenme
local tokensets = {
	greens = {"ahnqirajscarab", "zulgurubcoin"},
	blues  = {"ahnqirajidol20", "ahnqirajidol40", "zulgurubbijou"},
}
local tokenzones = {
	["Ahn'Qiraj"] = true,
	["Ruins of Ahn'Qiraj"] = true,
	["Zul'Gurub"] = true,
}
local _, _, _, qualgreen = GetItemQualityColor(2)
local _, _, _, qualblue = GetItemQualityColor(3)
local tokenformat1 = qualgreen.. "%s/%s ".. qualblue.. "%s/%s|r | "
local tokenformat2 = string.format("%sGreen Tokens: %s|r", qualgreen, "%s/%s")
local tokenformat3 = string.format("%sBlue Tokens: %s|r", qualblue, "%s/%s")
local strings = {
	pass = "passed on: (.+)",
	greed = "has selected Greed for: (.+)",
	need = "has selected Need for: (.+)",

	selfpass = "You passed on: (.+)",
	selfgreed = "You have selected Greed for: (.+)",
	selfneed = "You have selected Need for: (.+)",

	allpass = "Everyone passed on: (.+)",
	won = "(.+) won: (.+)",
	receive = "(.+) receives? loot: (.+).",
}
local rollpairs = {
	[strings.pass]  = "pass",
	[strings.greed] = "greed",
	[strings.need]  = "need",
	[strings.selfpass]  = "pass",
	[strings.selfgreed] = "greed",
	[strings.selfneed]  = "need",
}


FuBar_GreedBeacon = AceLibrary("AceAddon-2.0"):new("AceHook-2.1", "AceEvent-2.0", "AceConsole-2.0", "AceDB-2.0", "AceDebug-2.0", "FuBarPlugin-2.0")
FuBar_GreedBeacon.tooltipHiddenWhenEmpty = true
FuBar_GreedBeacon:RegisterDB("FuBar_GreedBeaconDB")
FuBar_GreedBeacon:RegisterDefaults("profile", {chat = false})

function FuBar_GreedBeacon:OnEnable()
	self:RegisterEvent("CHAT_MSG_LOOT")
 	self:SecureHook("GroupLootFrame_OpenNewFrame")
	self:SecureHook("RollOnLoot")
end


function FuBar_GreedBeacon:RollOnLoot(rollid, roll)
	openrolls = openrolls - 1
end


function FuBar_GreedBeacon:GroupLootFrame_OpenNewFrame(rollid, rollTime)
	openrolls = openrolls + 1
	table.insert(rolls, 1, {id = rollid, link = GetLootRollItemLink(rollid), greed = 0, need = 0, pass = 0})
end

local gii = GetItemInfo
local GetItemInfo = function(id)
	if type(id) == "number" then return gii(id)
	elseif type(id) == "string" then
		local i = tonumber(id)
		if i then return gii(i) end

		local _, _, itemid = string.find(id, "item:(%d+)")
		if itemid then return gii(itemid) end
	end
end


function FuBar_GreedBeacon:FindRollIndex(itemlink, hasWinner, allpass)
	for i,val in ipairs(rolls) do
		if (val.link == itemlink) and ((hasWinner and val.winner) or (hasWinner == false and not val.winner) or (hasWinner == nil)) then
			return i
		end
	end
	if allpass then
		for i,val in ipairs(rolls) do
			if (val.link == itemlink) and val.winner and val.winner == "Pass" then
				return i
			end
		end
	end
end


function FuBar_GreedBeacon:CHAT_MSG_LOOT(msg)
	local itemname, winner = self:ParseLootPickup(msg)
	if itemname and winner then return self:StoreWinner(itemname, winner)
	else
		local itemname, rolltype = self:ParseRollChoice(msg)
		if itemname and rolltype then
			local i = self:FindRollIndex(itemname, false)
			if not i then return end

			rolls[i][rolltype] = rolls[i][rolltype] + 1
			return self:Update()
		end
	end
end


function FuBar_GreedBeacon:ParseRollChoice(msg)
	for i,v in pairs(rollpairs) do
		local _, _, itemname = string.find(msg, i)
		if itemname then return itemname, v end
	end
end


function FuBar_GreedBeacon:ParseLootPickup(msg)
	if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then return end
	local _, _, itemname = string.find(msg, strings.allpass)
	if itemname then return itemname, "Pass" end

	_, _, playername, itemname = string.find(msg, strings.receive)
	if playername and itemname then
		playername = (playername == "You" and UnitName("player")) or playername
		local _, _, qual = GetItemInfo(itemname)
		if qual and qual >= GetLootThreshold() then return itemname, playername end
	end
end


function FuBar_GreedBeacon:StoreWinner(itemname, winner)
	local i = self:FindRollIndex(itemname, false, true)
	if not i then
		table.insert(rolls, 1, {winner = winner, need = 0, greed = 0, pass = 0, link = itemname})
		return self:Update()
	end

	if PeriodicTable then
		if PeriodicTable:ItemInSet(itemname, tokensets.greens) then
			tokens.greentotal = (tokens.greentotal or 0) + 1
			if winner == UnitName("player") then tokensgreenme = (tokensgreenme or 0) + 1 end
		elseif PeriodicTable:ItemInSet(itemname, tokensets.blues) then
			tokens.bluetotal = (tokens.bluetotal or 0) + 1
			if winner == UnitName("player") then tokens.blueme = (tokens.blueme or 0) + 1 end
		end
	end
	rolls[i].winner = winner

	return self:Update()
end


function FuBar_GreedBeacon:UseTokenData()
	return self.db.profile.showtokentracker and rolls[1] and tokenzones[GetRealZoneText()]
end


function FuBar_GreedBeacon:OnTextUpdate()
	local idx, str

	for i,val in ipairs(rolls) do
		if not idx and not val.winner then idx = i end
	end
	if not idx and rolls[1] then idx = 1 end

	if idx then
		local toks = self:UseTokenData() and string.format(tokenformat1, (tokensgreenme or 0), (tokens.greentotal or 0), (tokens.blueme or 0), (tokens.bluetotal or 0)) or ""
		local val = rolls[idx]
		if val.winner then
			local color = ((val.need > 0) and colorneed or (val.greed > 0) and colorgreed or colorpass)
			str = string.format("%s%s %s%s", toks, self.db.profile.supressitem and "" or val.link, color, val.winner)
		else
			str = string.format("%s%s %s%d %s%d %s%d", toks, self.db.profile.supressitem and "" or val.link, colorneed, val.need, colorgreed, val.greed, colorpass, val.pass)
		end
	end
	self:SetText(str or "No Item")
end


function FuBar_GreedBeacon:OnTooltipUpdate()
	local det = self:IsTooltipDetached()
	if openrolls < 1 and det then return end

	local cat = tablet:AddCategory("columns", 2)
	if self:UseTokenData() then
		local gtoks = string.format(tokenformat2, (tokensgreenme or 0), (tokens.greentotal or 0))
		local btoks = string.format(tokenformat3, (tokens.blueme or 0), (tokens.bluetotal or 0))
		cat:AddLine("text", gtoks, "text2", btoks)
	end

	cat = tablet:AddCategory("columns", 4)
	for _,val in ipairs(rolls) do
		if not det or not val.winner then
			local color = val.winner and ((val.need > 0) and colorneed or (val.greed > 0) and colorgreed or colorpass) or ""
			cat:AddLine("text", val.id or "--", "text2", val.link, "text3", color..(val.winner or ""),
				"text4", string.format("%s%d %s%d %s%d", colorneed, val.need, colorgreed, val.greed, colorpass, val.pass))
		end
	end
end


function FuBar_GreedBeacon:MenuSettings()
	dewdrop:AddLine("text", "Clear list","func", function()
		rolls, tokens = {}, {}
		self:Update()
	end)

	dewdrop:AddLine()

	dewdrop:AddLine("text", "Use token tracker", "func", function() self:ToggleOption("showtokentracker") end, "checked", self.db.profile.showtokentracker)
	dewdrop:AddLine("text", "Show item on bar", "func", function() self:ToggleOption("supressitem") end, "checked", not self.db.profile.supressitem)
end


function FuBar_GreedBeacon:ToggleOption(var)
	self.db.profile[var] = not self.db.profile[var]
	return self:Update()
end

