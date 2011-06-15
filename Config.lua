
---------------------
--      Panel      --
---------------------

if AddonLoader and AddonLoader.RemoveInterfaceOptions then AddonLoader:RemoveInterfaceOptions("GreedBeacon") end

local frame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
frame.name = "GreedBeacon"
frame:Hide()
frame:SetScript("OnShow", function(frame)
	local title, subtitle = LibStub("tekKonfig-Heading").new(frame, "GreedBeacon", "This panel allows you to control which chat frame GreedBeacon outputs to.")


	local chatframedropdown, chatframedropdowntext, chatframedropdowncontainer = LibStub("tekKonfig-Dropdown").new(frame, "Output to", "TOPLEFT", subtitle, "BOTTOMLEFT", -2, -8)
	chatframedropdowntext:SetText(GreedBeaconDB.frame)
	chatframedropdown.tiptext = "Select which chat frame to output to."

	local function OnClick(self)
		UIDropDownMenu_SetSelectedValue(chatframedropdown, self.value)
		chatframedropdowntext:SetText(self.value)
		GreedBeaconDB.frame = self.value
	end
	UIDropDownMenu_Initialize(chatframedropdown, function()
		local selected, info = UIDropDownMenu_GetSelectedValue(chatframedropdown) or GreedBeaconDB.frame, UIDropDownMenu_CreateInfo()

		for i=1,7 do
			info.text = "ChatFrame"..i
			info.value = "ChatFrame"..i
			info.func = OnClick
			info.checked = ("ChatFrame"..i) == selected
			UIDropDownMenu_AddButton(info)
		end
	end)


	local ident = LibStub("tekKonfig-Button").new_small(frame, "TOPLEFT", chatframedropdown, "TOPRIGHT")
	ident:SetText("Identify")
	ident.tiptext = "Identify each chat frame"
	ident:SetScript("OnClick", function(self) for i=1,7 do _G["ChatFrame"..i]:AddMessage("|cFF33FF99GreedBeacon|r: This is ChatFrame"..i) end end)


	frame:SetScript("OnShow", nil)
end)

InterfaceOptions_AddCategory(frame)
LibStub("tekKonfig-AboutPanel").new("GreedBeacon", "GreedBeacon")
