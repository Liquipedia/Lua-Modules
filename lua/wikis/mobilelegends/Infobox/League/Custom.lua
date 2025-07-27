---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class MobilelegendsLeagueInfobox: InfoboxLeague
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
	local args = self.caller.args

	if id == 'sponsors' then
		table.insert(widgets, Cell{name = 'Official Device', content = {args.device}})
	elseif id == 'gamesettings' then
		return {Cell{name = 'Patch', content = {CustomLeague._getPatchVersion(args)}}}
	elseif id == 'customcontent' then
		if args.player_number then
			table.insert(widgets, Title{children = 'Players'})
			table.insert(widgets, Cell{name = 'Number of players', content = {args.player_number}})
		end

		--teams section
		if args.team_number or (not String.isEmpty(args.team1)) then
			table.insert(widgets, Title{children = 'Teams'})
		end
		table.insert(widgets, Cell{name = 'Number of teams', content = {args.team_number}})
	end
	return widgets
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	if args.team_number or (not String.isEmpty(args.team1)) then
		Variables.varDefine('is_team_tournament', 1)
	end

	--Legacy Vars:
	Variables.varDefine('tournament_edate', self.data.endDate)
end

---@param args table
---@return string?
function CustomLeague._getPatchVersion(args)
	if String.isEmpty(args.patch) then return nil end
	local content = PageLink.makeInternalLink(args.patch, 'Patch ' .. args.patch)
	if not String.isEmpty(args.epatch) then
		content = content .. '&nbsp;&ndash;&nbsp;'
		content = content .. PageLink.makeInternalLink(args.epatch, 'Patch ' .. args.epatch)
	end

	return content
end

return CustomLeague
