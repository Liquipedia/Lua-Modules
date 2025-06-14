---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local Game = Lua.import('Module:Game')
local Injector = Lua.import('Module:Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class CounterstrikeInfoboxTeam: InfoboxTeam
---@field gamesList string[]
local CustomTeam = Class.new(Team)
local CustomInjector = Class.new(Injector)

function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	team:setWidgetInjector(CustomInjector(team))

	team.gamesList = Array.filter(Game.listGames({ordered = true}), function (gameIdentifier)
			return team.args[gameIdentifier]
		end)

	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'staff' then
		return {
			Cell{name = 'Founders',	content = {args.founders}},
			Cell{name = 'CEO', content = {args.ceo}},
			Cell{name = 'Gaming Director', content = {args['gaming director']}},
			widgets[4], -- Manager
			widgets[5], -- Captain
			Cell{name = 'In-Game Leader', content = {args.igl}},
			widgets[1], -- Coaches
			Cell{name = 'Analysts', content = {args.analysts}},
		}
	elseif id == 'custom' then
		return {Cell {
			name = 'Games',
			content = Array.map(self.caller.gamesList, function (gameIdentifier)
					return Game.text{game = gameIdentifier}
				end)
		}}
	end
	return widgets
end

---@return string?
function CustomTeam:createBottomContent()
	if not self.args.disbanded and mw.ext.TeamTemplate.teamexists(self.pagename) then
		local teamPage = mw.ext.TeamTemplate.teampage(self.pagename)

		return Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing tournaments of',
			{team = self.args.lpdbname or teamPage}
		)
	end
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.extradata.ismixteam = tostring(String.isNotEmpty(args.mixteam))
	lpdbData.extradata.isnationalteam = tostring(String.isNotEmpty(args.nationalteam))

	return lpdbData
end

---@param args table
---@return string[]
function CustomTeam:getWikiCategories(args)
	local categories = {}

	Array.forEach(self.gamesList, function (gameIdentifier)
			local prefix = Game.abbreviation{game = gameIdentifier} or Game.name{game = gameIdentifier}
			table.insert(categories, prefix .. ' Teams')
		end)

	if Table.isEmpty(self.gamesList) then
		table.insert(categories, 'Gameless Teams')
	end

	if args.teamcardimage then
		table.insert(categories, 'Teams using TeamCardImage')
	end

	if not args.region then
		table.insert(categories, 'Teams without a region')
	end

	if args.nationalteam then
		table.insert(categories, 'National Teams')
	end

	return categories
end

return CustomTeam
