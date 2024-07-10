---
-- @Liquipedia
-- wiki=worldoftanks
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
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Infobox/Widget/All')
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

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.publishertier = tostring(Logic.readBool(args.publisherpremier))
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		return {
			Cell{name = 'Number of teams', content = {args.team_number}},
			Cell{name = 'Number of players', content = {args.player_number}},
		}
	elseif id == 'gamesettings' then
		table.insert(widgets, Cell{
			name = 'Patch',
			content = {self.caller:_createPatchCell(args)}
		})
		table.insert(widgets, Cell{
			name = 'Game',
			content = {Game.name{game = args.game}}
		})
	elseif id == 'customcontent' then
		if String.isNotEmpty(args.map1) then
			local maps = Array.map(self.caller:getAllArgsForBase(args, 'map'), function(map)
				return tostring(self.caller:_createNoWrappingSpan(PageLink.makeInternalLink(map)))
			end)
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	end
	return widgets
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	-- Wiki Custom
	Variables.varDefine('patch', args.patch or '')
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(self:getAllArgsForBase(args, 'map'), ';')
	return lpdbData
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.publisherpremier)
end

---@param args table
---@return string?
function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end
	local content

	if String.isEmpty(args.epatch) then
		content = '[[Patch ' .. args.patch .. '|'.. args.patch .. ']]'
	else
		content = '[[Patch ' .. args.patch .. '|'.. args.patch .. ']]' .. ' &ndash; ' ..
		'[[Patch ' .. args.epatch .. '|'.. args.epatch .. ']]'
	end

	return content
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

return CustomLeague
