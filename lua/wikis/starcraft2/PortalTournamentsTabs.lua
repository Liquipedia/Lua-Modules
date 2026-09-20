---
-- @Liquipedia
-- page=Module:PortalTournamentsTabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Tabs = Lua.import('Module:Tabs')
local Tier = Lua.import('Module:Tier/Custom')

local QueryLink = Lua.import('Module:Widget/QueryLink')

local NOW = DateExt.toYmdInUtc(DateExt.getCurrentTimestamp() + DateExt.daysToSeconds(1))
local PAST = DateExt.toYmdInUtc(DateExt.getCurrentTimestamp() - DateExt.daysToSeconds(183))

local PortalTournamentsTabs = {}

---@return Renderable?
function PortalTournamentsTabs.run()
	---@type table<string, Renderable>
	local tabArgs = {
		name1 = 'Introduction',
		link1 = 'Portal:Tournaments',
		name2 = 'Recent Results',
		link2 = 'Recent Tournament Results'
	}

	local tabCounter = 2
	local tiers = {}
	for tier in Tier.iterate('tiers') do
		table.insert(tiers, tier)
	end

	Array.forEach(tiers, function(tier)
		if Logic.isEmpty(tier) then
			return
		end

		tabCounter = tabCounter + 1

		local isNotMisc = (tonumber(tier) ~= -1)

		tabArgs['name' .. tabCounter] = QueryLink{
			legacyForm = 'Portal Tournaments',
			form = 'Portal Tournaments/LH',
			display = Tier.toName(tier) --[[@as string]],
			template = 'TournamentsList',
			queryArgs = {
				tier = tier,
				game = 'lotv',
				noLis = 'true',
				excludeTiertype1 = isNotMisc and 'Qualifier' or nil,
				excludeTiertype2 = isNotMisc and 'Charity' or nil,
				enddate = NOW,
				startdate = isNotMisc and PAST or nil,
			},
		}
	end)

	tabCounter = tabCounter + 1
	tabArgs['name' .. tabCounter] = '2v2 - Archon'
	tabArgs['link' .. tabCounter] = '2v2 - Archon Tournaments'

	tabCounter = tabCounter + 1
	tabArgs['name' .. tabCounter] = 'Female Only'
	tabArgs['link' .. tabCounter] = 'Female Tournaments'

	return Tabs.static(tabArgs)
end

return PortalTournamentsTabs
