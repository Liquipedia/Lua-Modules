local Lua = require('Module:Lua')

local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Tabs = Lua.import('Module:Tabs')
local Variables = Lua.import('Module:Variables')

local ResultsTable = Lua.import('Module:ResultsTable/Custom')
local BroadcasterTable = Lua.import('Module:BroadcastTalentTable')

local PlayerAchievementsTableWrapper = {}

---@param frame Frame
---@return Widget
function PlayerAchievementsTableWrapper.run(frame)
	local awards = Json.parseIfTable(Variables.varDefault('awardAchievements'))

	local hasBroadCastsSubPage = Page.exists(mw.title.getCurrentTitle().prefixedText .. '/Broadcasts')

	if Logic.isEmpty(awards) and not hasBroadCastsSubPage then
		return ResultsTable.results(frame)
	end

	local tabArgs = {
		name1 = 'Player Achievements',
		content1 = ResultsTable.results(frame)
	}

	local tabIndex = 1
	if Logic.isNotEmpty(awards) then
		frame.args.awards = 1
		frame.args.resultsSubPage = 'Awards'
		tabIndex = tabIndex + 1
		tabArgs['name' .. tabIndex] = 'Awards'
		tabArgs['content' .. tabIndex] = ResultsTable.awards(frame)
	end

	if hasBroadCastsSubPage then
		tabIndex = tabIndex + 1

		local broadcastAchievements = BroadcasterTable.run{
			achievements = 1,
			aboutAchievementsLink = 'Template:Broadcast talent achievements table/doc',
			useTickerNames = true,
		}

		tabArgs['name' .. tabIndex] = broadcastAchievements and 'Talent Achievements' or nil
		tabArgs['content' .. tabIndex] = broadcastAchievements
	end

	return Tabs.dynamic(tabArgs)
end

return PlayerAchievementsTableWrapper
