--[[
	Damn Achievement Spam, Mayen of Mal'Ganis (US) PvP
]]

local achievements, chatFrames, spamCategories, specialFilters = {}, {}, {[155] = true, [168] = true, [95] = true}, {1400, 456, 1402, 3259, 3117}
local frame = CreateFrame("Frame")
frame:Hide()

local L = {
	["%s have earned the achievement %s!"] = "%s have earned the achievement %s!",
	["|Hplayer:%s|h[%s]|h has earned the achievement %s!"] = "|Hplayer:%s|h[%s]|h has earned the achievement %s!",
}

-- Handles sending a chat message to all frames that have it registered
local function sendMessage(event, msg, r, g, b)
	local info = ChatTypeInfo[string.sub(event, 10)]
	for i=1, 7 do
		chatFrames[i] = chatFrames[i] or getglobal("ChatFrame" .. i)
		if( chatFrames[i] and chatFrames[i]:IsEventRegistered(event) ) then
			chatFrames[i]:AddMessage(msg, info.r, info.g, info.b)
		end
	end
end

local function sortPlayers(a, b)
	return a < b
end

local alreadySent = {}
local function sendAchievement(event, achievementID, players)
	if( not players ) then return end
	
	-- Strip duplicates
	for k in pairs(alreadySent) do alreadySent[k] = nil end
	for i=#(players), 1, -1 do
		if( alreadySent[players[i]] ) then
			table.remove(players, i)
		else
			alreadySent[players[i]] = true
		end
	end
	
	-- More than one person, send it as plural form + don't include brackets
	if( #(players) > 1 ) then
		table.sort(players, sortPlayers)
		for id, player in pairs(players) do
			players[id] = string.format("|Hplayer:%s|h%s|h", player, player)
		end
		
		sendMessage(event, string.format(L["%s have earned the achievement %s!"], table.concat(players, ", "), GetAchievementLink(achievementID)))
	-- Only one person, send it as singular form + include brackets
	elseif( #(players) == 1 ) then
		sendMessage(event, string.format(L["|Hplayer:%s|h[%s]|h has earned the achievement %s!"], players[1], players[1], GetAchievementLink(achievementID)))
	end
end

-- An achievement has finished timing out, and we can output it.
local function achievementReady(id, achievement)
	-- This will move anyone in the same guild as the player to the guilds achievement spam, instead of the area
	-- the only people who will show in the area are those who are unguilded.
	if( achievement.area and achievement.guild ) then
		local playerGuild = GetGuildInfo("player")
		for i=#(achievement.area), 1, -1 do
			local player = achievement.area[i]
			if( UnitExists(player) and playerGuild and playerGuild == GetGuildInfo(player) ) then
				table.insert(achievement.guild, table.remove(achievement.area, i))
			end
		end
	end
	
	sendAchievement("CHAT_MSG_ACHIEVEMENT", id, achievement.area)
	sendAchievement("CHAT_MSG_GUILD_ACHIEVEMENT", id, achievement.guild)
end

-- Watch for spam to time out and be ready to output
frame:SetScript("OnUpdate", function(self, elapsed)
	local found
	for id, achievement in pairs(achievements) do
		-- Found one thats ready to be sent
		if( achievement.timeout <= GetTime() ) then
			achievementReady(id, achievement)
			achievements[id] = nil
		end

		found = true
	end
		
	-- Nothing else to watch
	if( not found ) then
		self:Hide()
	end
end)

-- Queue a player to be sent out for earning an achievement
local function queueAchievementSpam(event, achievementID, player)
	achievements[achievementID] = achievements[achievementID] or {timeout = GetTime() + 0.5}
	achievements[achievementID][event] = achievements[achievementID][event] or {}
		
	table.insert(achievements[achievementID][event], player)
	frame:Show()
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
	
	local categoryID = GetAchievementCategory(achievementID)
	if( spamCategories[categoryID] or spamCategories[select(2, GetCategoryInfo(categoryID))] or specialFilters[achievementID] ) then
		queueAchievementSpam((event == "CHAT_MSG_GUILD_ACHIEVEMENT" and "guild" or "area"), achievementID, author)
		
		-- Now block the new one from showing
		return true
	end
		
	return orig_ChatFrame_MessageEventHandler(self, event, ...)
end

--[[
function test()
local list = [ [
CHAT_MSG_GUILD_ACHIEVEMENT/Frotesz has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Rioht has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Rioht has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Stochastic has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Mork has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Mork has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Duoctane has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Duoctane has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Selece has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Selece has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Silmeriah has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Silmeriah has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Netheris has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Netheris has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Sawney has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Sawney has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Zeln has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Alane has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Alane has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Agamos has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Agamos has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Rafikki has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Rafikki has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Xandrine has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Xandrine has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Kroot has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Kroot has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Hamlet has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Hamlet has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Preliator has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Preliator has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Ramala has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Ramala has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Zenjimaru has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Zenjimaru has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Mayen has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Eejette has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Eejette has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Zorops has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Schalla has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Rhydian has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Rhydian has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Evvi has earned the achievement *first!
CHAT_MSG_GUILD_ACHIEVEMENT/Evvi has earned the achievement *first!
CHAT_MSG_ACHIEVEMENT/Xandrine has earned the achievement *second!
CHAT_MSG_GUILD_ACHIEVEMENT/Xandrine has earned the achievement *second!
CHAT_MSG_ACHIEVEMENT/Kroot has earned the achievement *second!
CHAT_MSG_GUILD_ACHIEVEMENT/Kroot has earned the achievement *second!
CHAT_MSG_ACHIEVEMENT/Hamlet has earned the achievement *second!
CHAT_MSG_GUILD_ACHIEVEMENT/Hamlet has earned the achievement *second!
CHAT_MSG_ACHIEVEMENT/Preliator has earned the achievement *second!
CHAT_MSG_GUILD_ACHIEVEMENT/Preliator has earned the achievement *second!
CHAT_MSG_ACHIEVEMENT/Ramala has earned the achievement *second!
CHAT_MSG_GUILD_ACHIEVEMENT/Ramala has earned the achievement *second!
CHAT_MSG_ACHIEVEMENT/Zenjimaru has earned the achievement *second!
CHAT_MSG_GUILD_ACHIEVEMENT/Zenjimaru has earned the achievement *second!
CHAT_MSG_ACHIEVEMENT/Mayen has earned the achievement *second!
CHAT_MSG_ACHIEVEMENT/Eejette has earned the achievement *second!
CHAT_MSG_GUILD_ACHIEVEMENT/Eejette has earned the achievement *second!
CHAT_MSG_ACHIEVEMENT/Zorops has earned the achievement *second!
CHAT_MSG_GUILD_ACHIEVEMENT/Schalla has earned the achievement *second!
CHAT_MSG_ACHIEVEMENT/Rhydian has earned the achievement *second!
CHAT_MSG_GUILD_ACHIEVEMENT/Rhydian has earned the achievement *second!
CHAT_MSG_ACHIEVEMENT/Evvi has earned the achievement *second!
CHAT_MSG_GUILD_ACHIEVEMENT/Evvi has earned the achievement *second!
] ]
	
	local achievements = {["*first"] = GetAchievementLink(2944), ["*second"] = GetAchievementLink(2954)}
	for _, line in pairs({string.split("\n", list)}) do
		line = string.trim(line)
		local event, text = string.split("/", line)
		if( event and text ) then
			for type, link in pairs(achievements) do
				text = string.gsub(text, type, link)
			end
			
			local author = string.match(text, "(.+) has")
			ChatFrame_MessageEventHandler(ChatFrame1, event, text, author)
		end
	end
end
]]
