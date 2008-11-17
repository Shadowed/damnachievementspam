local DA = {}
local filterList = {}
local achievements = {["GUILD_ACHIEVEMENT"] = {}, ["ACHIEVEMENT"] = {}}
local timeouts = {["GUILD_ACHIEVEMENT"] = {}, ["ACHIEVEMENT"] = {}}
local chats = {["GUILD_ACHIEVEMENT"] = {}, ["ACHIEVEMENT"] = {}}
local TOTAL_TIMEOUTS = 0
local frame

local L = {
	["%s have earned the achievement %s!"] = "%s have earned the achievement %s!",
}

-- Scan list of achievement ids
local function scanAchievements(category, parentCategory)
	for i=1, (GetCategoryNumAchievements(category)) do
		local id = GetAchievementInfo(category, i)
		filterList[id] = true
		
		-- We save them for achievements like badges where you have single/25/50/blah/blah/blah
		-- it's not perfect, but it works decently
		DamnAchievementSpamDB[id] = true
	end
	
	-- Scan children of this category
	if( not parentCategory ) then
		for _, id in pairs(GetCategoryList()) do
			if( select(2, GetCategoryInfo(id)) == category ) then
				scanAchievements(id, category)		
			end
		end
	end
end

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
	
	-- Are we filtering this achievement?
	if( achievementID and filterList[achievementID] ) then
		local type = string.sub(event, 10)
		chats[type][self] = true
		
		-- Add this person to the list as having gotten it
		achievements[type][achievementID] = achievements[type][achievementID] or {}
		table.insert(achievements[type][achievementID], string.format("|Hplayer:%s|h%s|h", author, author))
		
		-- Start this to run in 0.50 seconds or so if we haven't
		if( not timeouts[type][achievementID] ) then
			TOTAL_TIMEOUTS = TOTAL_TIMEOUTS + 0.50
		end
		
		timeouts[type][achievementID] = timeouts[type][achievementID] or 0.50
		
		-- Annnd start the countdown
		frame:Show()
		
		-- Now block the new one from showing
		return true
	end
		
	return orig_ChatFrame_MessageEventHandler(self, event, msg, select(2, ...))
end


frame = CreateFrame("Frame")
frame:Hide()

-- Timer so we know if we need to output all the achievements
frame:SetScript("OnUpdate", function(self, elapsed)
	if( TOTAL_TIMEOUTS == 0 ) then
		self:Hide()
		return
	end
	
	for type, list in pairs(timeouts) do
		for id, timeout in pairs(list) do
			timeouts[type][id] = timeouts[type][id] - elapsed

			-- Timed out, list everyone who got this
			if( timeouts[type][id] <= 0 ) then
				local info = ChatTypeInfo[type]
				for frame in pairs(chats[type]) do
					frame:AddMessage(string.format(L["%s have earned the achievement %s!"], table.concat(achievements[type][id], ", "), GetAchievementLink(id)), info.r, info.g, info.b)
				end

				TOTAL_TIMEOUTS = TOTAL_TIMEOUTS - 1
				timeouts[type][id] = nil

				for i=#(achievements[type][id]), 1, -1 do table.remove(achievements[type][id], i) end
				for k in pairs(chats[type]) do chats[type][k] = nil end
			end
		end
	end
end)

-- Cache list of achievementID's to watch
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event)
	self:UnregisterAllEvents()
	
	-- Set the filter to our saved list first
	DamnAchievementSpamDB = DamnAchievementSpamDB or {}
	filterList = DamnAchievementSpamDB

	-- Scan Dungeons & raids
	scanAchievements(168)
	
	-- Scan Player vs Player
	scanAchievements(95)
end)