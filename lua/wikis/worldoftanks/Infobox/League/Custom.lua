---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Tier = require('Module:Tier/Custom')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class WorldoftanksLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		return {
			Cell{name = 'Number of teams', content = {args.team_number}},
			Cell{name = 'Number of players', content = {args.player_number}},
		}
	elseif id == 'gamesettings' then
		Array.appendWith(widgets,
			Cell{name = 'Patch', content = {caller:_createPatchCell()}},
			Cell{name = 'Game', content = {Game.name{game = args.game}}}
		)
	elseif id == 'customcontent' then
		if String.isNotEmpty(args.map1) then
			local maps = Array.map(self.caller:getAllArgsForBase(args, 'map'), function(map)
				return tostring(self.caller:_createNoWrappingSpan(PageLink.makeInternalLink(map)))
			end)
			table.insert(widgets, Title{children = 'Maps'})
			table.insert(widgets, Center{children = {table.concat(maps, '&nbsp;• ')}})
		end
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(self:getAllArgsForBase(args, 'map'), ';')
	return lpdbData
end

---@return string?
function CustomLeague:_createPatchCell()
	local data = self.data
	if Logic.isEmpty(data.patch) then return end

	local displayPatch = function(patch)
		return PageLink.makeInternalLink({}, patch, 'Patch ' .. patch)
	end

	if data.endPatch == data.patch then
		return displayPatch(data.patch)
	end

	return displayPatch(data.patch) .. ' &ndash; ' .. displayPatch(data.endPatch)
end

---@param args table
---@return table
function CustomLeague:getWikiCategories(args)
	if not Game.name{game = args.game} then
		return {'Tournaments without game version'}
	end
	return {Game.name{game = args.game} .. ' Competitions'}
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

---@param args table
---@return string?
function CustomLeague:createLiquipediaTierDisplay(args)
	local tierDisplay = Tier.display(
		args.liquipediatier,
		args.liquipediatiertype,
		{link = true, game = Game.name{game = args.game}}
	)

	if String.isEmpty(tierDisplay) then
		return
	end

	return tierDisplay .. self:appendLiquipediatierDisplay(args)
end

return CustomLeague
