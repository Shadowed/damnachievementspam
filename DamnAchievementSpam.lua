local achievements = {["GUILD_ACHIEVEMENT"] = {}, ["ACHIEVEMENT"] = {}}
local timeouts = {["GUILD_ACHIEVEMENT"] = {}, ["ACHIEVEMENT"] = {}}
local chats = {["GUILD_ACHIEVEMENT"] = {}, ["ACHIEVEMENT"] = {}}
local TOTAL_TIMEOUTS = 0
local spamCategories = {[168] = true, [95] = true}
local specialFilters = {1400, 456, 1402, 3259, 3117}
local frame = CreateFrame("Frame")
frame:Hide()

local L = {
	["%s have earned the achievement %s!"] = "%s have earned the achievement %s!",
	["%s has earned the achievement %s!"] = "%s has earned the achievement %s!",
}

-- Timer so we know if we need to output all the achievements
frame:SetScript("OnUpdate", function(self, elapsed)
	if( TOTAL_TIMEOUTS <= 0 ) then
		TOTAL_TIMEOUTS = 0
		self:Hide()
		return
	end
	
	for type, list in pairs(timeouts) do
		for id, timeout in pairs(list) do
			timeouts[type][id] = timeouts[type][id] - elapsed

			-- Timed out, list everyone who got this
			if( timeouts[type][id] <= 0 ) then
				local players
				local info = ChatTypeInfo[type]
				for frame in pairs(chats[type]) do
					-- Use the plural since more than one got it
					if( #(achievements[type][id]) > 1 ) then
						-- Embed the player meta data without brackets
						if( not players ) then
							for pID, player in pairs(achievements[type][id]) do
								achievements[type][id][pID] = string.format("|Hplayer:%s|h%s|h", player, player)
							end
							
							players = table.concat(achievements[type][id], ", ")
						end
						
						frame:AddMessage(string.format(L["%s have earned the achievement %s!"], players, GetAchievementLink(id)), info.r, info.g, info.b)
					
					-- Use singular + embed brackets into it
					else
						frame:AddMessage(string.format(L["%s has earned the achievement %s!"], string.format("|Hplayer:%s|h[%s]|h", achievements[type][id][1], achievements[type][id][1]), GetAchievementLink(id)), info.r, info.g, info.b)
					end
				end

				TOTAL_TIMEOUTS = TOTAL_TIMEOUTS - 1
				timeouts[type][id] = nil

				for i=#(achievements[type][id]), 1, -1 do table.remove(achievements[type][id], i) end
				for k in pairs(chats[type]) do chats[type][k] = nil end
			end
		end
	end
end)

-- Do we need to filter them?
local orig_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler
function ChatFrame_MessageEventHandler(self, event, ...)
	-- Not an achievement, don't care about it
	if( event ~= "CHAT_MSG_GUILD_ACHIEVEMENT" and event ~= "CHAT_MSG_ACHIEVEMENT" ) then
		return orig_ChatFrame_MessageEventHandler(self, event, ...)
	end
	
	local msg, author = select(1, ...)
	local achievementID = string.match(msg, "|Hachievement:([0-9]+):(.+)|h")
	achievementID = tonumber(achievementID)
	
	local categoryID = GetAchievementCategory(achievementID)
	if( spamCategories[categoryID] or spamCategories[select(2, GetCategoryInfo(categoryID))] or specialFilters[achievementID] ) then
		local type = string.sub(event, 10)
		chats[type][self] = true
		
		-- Add this person to the list as having gotten it
		achievements[type][achievementID] = achievements[type][achievementID] or {}
		
		local found = false
		for _, name in pairs(achievements[type][achievementID]) do
			if( name == author ) then
				found = true
				break
			end
		end
		if( not found ) then
			table.insert(achievements[type][achievementID], author)
		end

		-- Set the total number of timers we're running
		if( not timeouts[type][achievementID] ) then
			TOTAL_TIMEOUTS = TOTAL_TIMEOUTS + 1
		end
		
		-- Start this to run in 0.50 seconds or so if we haven't
		timeouts[type][achievementID] = timeouts[type][achievementID] or 0.50
		
		-- Annnd start the countdown
		frame:Show()
		
		-- Now block the new one from showing
		return true
	end
		
	return orig_ChatFrame_MessageEventHandler(self, event, msg, select(2, ...))
end