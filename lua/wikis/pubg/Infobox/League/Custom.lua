---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class PubgLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local NONE_BREAKING_SPACE = '&nbsp;'
local DASH = '&ndash;'

local MODES = {
	solo = 'Solos[[Category:Solos Mode Tournaments]]',
	duo = 'Duos[[Category:Duos Mode Tournaments]]',
	squad = 'Squads[[Category:Squads Mode Tournaments]]',
	['2v2'] = '2v2 TDM[[Category:2v2 TDM Tournaments]]',
	['4v4'] = '4v4 TDM[[Category:4v4 TDM Tournaments]]',
	['war mode'] = 'War Mode[[Category:War Mode Tournaments]]',
	default = '[[Category:Unknown Mode Tournaments]]',
}
MODES.solos = MODES.solo
MODES.duos = MODES.duo
MODES.squads = MODES.squad
MODES.tdm = MODES['2v2']

local PERSPECTIVES = {
	fpp = {'FPP'},
	tpp = {'TPP'},
	mixed = {'FPP', 'TPP'},
}
PERSPECTIVES.first = PERSPECTIVES.fpp
PERSPECTIVES.third = PERSPECTIVES.tpp

local PLATFORMS = {
	pc = '[[PC]][[Category:PC Competitions]]',
	mobile = '[[Mobile]][[Category:Mobile Competitions]]',
	newstate = '[[New State]][[Category:Mobile Competitions]]',
	pclite = '[[PC LITE]][[Category:PC Competitions]][[Category:PC LITE Competitions]]',
	peace = '[[Peacekeeper Elite|Peace Elite]][[Category:Peacekeeper Elite Competitions]][[Category:Mobile Competitions]]',
	bgmi = '[[Battlegrounds Mobile India|BGMI]]' ..
		'[[Category:Battlegrounds Mobile India Competitions]][[Category:Mobile Competitions]]',
	console = '[[Console]][[Category:Console Competitions]]',
	default = '[[Category:Unknown Platform Competitions]]',
}
PLATFORMS.lite = PLATFORMS.pclite

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

	if id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {Game.name{game = args.game}}},
			Cell{name = 'Game mode', content = {self.caller:_getGameMode(args)}},
			Cell{name = 'Patch', content = {CustomLeague._getPatchVersion(args)}},
			Cell{name = 'Platform', content = {self.caller:_getPlatform(args)}},
		}
	elseif id == 'customcontent' then
		if args.player_number then
			table.insert(widgets, Title{children = 'Players'})
			table.insert(widgets, Cell{name = 'Number of players', content = {args.player_number}})
		end

		--teams section
		if args.team_number then
			table.insert(widgets, Title{children = 'Teams'})
			table.insert(widgets, Cell{name = 'Number of teams', content = {args.team_number}})
		end
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''

	return lpdbData
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy Vars:
	Variables.varDefine('tournament_edate', self.data.endDate)
end

---@param args table
---@return string?
function CustomLeague:_getGameMode(args)
	if String.isEmpty(args.perspective) and String.isEmpty(args.mode) then
		return nil
	end

	local getPerspectives = function(perspectiveInput)
		local perspective = string.lower(perspectiveInput or '')
		-- Clean unnecessary data from the input
		perspective = string.gsub(perspective, ' person', '')
		perspective = string.gsub(perspective, ' perspective', '')
		return PERSPECTIVES[perspective] or {}
	end
	local getPerspectiveDisplay = function(perspective)
		return Template.safeExpand(mw.getCurrentFrame(), 'Abbr/' .. perspective)
	end
	local displayPerspectives = Table.mapValues(getPerspectives(args.perspective), getPerspectiveDisplay)

	local mode = MODES[string.lower(args.mode or '')] or MODES['default']

	return mode .. '&nbsp;' .. table.concat(displayPerspectives, '&nbsp;')
end

---@param args table
---@return string?
function CustomLeague:_getPlatform(args)
	if String.isEmpty(args.platform) then
		return nil
	end

	return PLATFORMS[string.lower(args.platform)] or PLATFORMS.default
end

---@param args table
---@return string?
function CustomLeague._getPatchVersion(args)
	if String.isEmpty(args.patch) then return nil end
	local content = PageLink.makeInternalLink(args.patch, 'Patch ' .. args.patch)
	if String.isNotEmpty(args.epatch) then
		return content .. NONE_BREAKING_SPACE .. DASH .. NONE_BREAKING_SPACE
			.. PageLink.makeInternalLink(args.epatch, 'Patch ' .. args.epatch)
	end

	return content
end

return CustomLeague
