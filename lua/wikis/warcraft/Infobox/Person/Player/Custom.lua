---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Variables = require('Module:Variables')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local CURRENT_YEAR = tonumber(os.date('%Y'))
local NON_BREAKING_SPACE = '&nbsp;'

---@class WarcraftInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	local args = player.args

	-- Automatic achievements
	args.achievements = Achievements.player{noTemplate = true}

	-- Profiles to links
	args.esl = args.esl or args.eslprofile
	args.nwc3l = args.nwc3l or args.nwc3lprofile

	-- Uppercase first letter in status
	if args.status then
		args.status = mw.getContentLanguage():ucfirst(args.status)
	end

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		local currentYearEarnings = self.caller.earningsPerYear[CURRENT_YEAR] or 0
		if currentYearEarnings == 0 then return widgets end
		local currentYearEarningsDisplay = '$' .. mw.getContentLanguage():formatNum(Math.round(currentYearEarnings))

		table.insert(widgets, Cell{name = 'Approx. Earnings '.. CURRENT_YEAR, content = {currentYearEarningsDisplay}})

	elseif id == 'role' then
		-- WC doesn't show any roles, but rather shows the Race/Faction instead
		return {
			Cell{name = 'Race', content = {Faction.toName(args.race)}}
		}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.faction = Faction.toName(args.race)
	lpdbData.extradata.factionhistorical = Variables.varDefault('racecount') and 'true' or 'false'

	return lpdbData
end

---@param args table
---@return string
function CustomPlayer:nameDisplay(args)
	local factionIcon = Faction.Icon{faction = args.race}

	return (factionIcon and (factionIcon .. NON_BREAKING_SPACE) or '')
		.. (args.id or self.pagename)
end

return CustomPlayer
