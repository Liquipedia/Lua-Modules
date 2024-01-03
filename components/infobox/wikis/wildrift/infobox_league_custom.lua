---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League/temp', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class WildriftLeagueInfobox: InfoboxLeagueTemp
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
		return {Cell{name = 'Patch', content = {self.caller:_getPatchVersion()}}}
	elseif id == 'customcontent' then
		if args.player_number then
			table.insert(widgets, Title{name = 'Players'})
			table.insert(widgets, Cell{name = 'Number of players', content = {args.player_number}})
		end

		--teams section
		if args.team_number or (not String.isEmpty(args.team1)) then
			table.insert(widgets, Title{name = 'Teams'})
		end
		table.insert(widgets, Cell{name = 'Number of teams', content = {args.team_number}})
	end
	return widgets
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.publishertier = Logic.readBool(args.riotpremier) and 'true' or nil
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	if args.team_number or (not String.isEmpty(args.team1)) then
		Variables.varDefine('is_team_tournament', 1)
	end

	--Legacy Vars:
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_riot_premier', args.riotpremier)
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.riotpremier)
end

function CustomLeague:_getPatchVersion()
	if String.isEmpty(self.args.patch) then return nil end
	local content = Page.makeInternalLink(self.args.patch, 'Patch ' .. self.args.patch)
	if not String.isEmpty(self.args.epatch) then
		content = content .. '&nbsp;&ndash;&nbsp;'
			.. Page.makeInternalLink(self.args.epatch, 'Patch ' .. self.args.epatch)
	end

	return content
end

return CustomLeague
