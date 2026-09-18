---
-- @Liquipedia
-- page=Module:PlayerAchievementsTableWrapper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local MatchTable = Lua.import('Module:MatchTable/Custom')
local Page = Lua.import('Module:Page')
local Tabs = Lua.import('Module:Tabs')
local Variables = Lua.import('Module:Variables')

local ResultsTable = Lua.import('Module:ResultsTable/Custom')
local BroadcasterTable = Lua.import('Module:BroadcastTalentTable')

local PlayerAchievementsTableWrapper = {}

---@param frame Frame
---@return Renderable?
function PlayerAchievementsTableWrapper.run(frame)
	local currentPage = mw.title.getCurrentTitle().prefixedText

	---@type table<string, Renderable>
	local tabArgs = {
		name1 = 'Player Achievements',
		content1 = ResultsTable.results(frame),
		name2 = 'Recent Results',
		content2 = MatchTable.results{
			tableMode = 'solo',
			player = currentPage,
			showType = true,
			limit = 10,
		},
	}

	local tabIndex = 3
	frame.args.awards = 1
	frame.args.resultsSubPage = 'Awards'
	tabArgs['name' .. tabIndex] = 'Awards'
	tabArgs['content' .. tabIndex] = ResultsTable.awards(frame)

	if Page.exists(currentPage .. '/Broadcasts') then
		tabIndex = tabIndex + 1

		local broadcastAchievements = BroadcasterTable.run{
			achievements = 1,
			useTickerNames = true,
		}

		tabArgs['name' .. tabIndex] = broadcastAchievements and 'Talent Achievements' or nil
		tabArgs['content' .. tabIndex] = broadcastAchievements
	end

	return Tabs.dynamic(tabArgs)
end

return PlayerAchievementsTableWrapper
