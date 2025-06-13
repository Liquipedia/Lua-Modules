---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local VALID_PUBLISHERTIERS = {'sponsored'}

local SUPERCELL_SPONSORED_ICON = '[[File:Supercell lightmode.png|x18px|link=Supercell'
	.. '|Tournament sponsored by Supercell.|class=show-when-light-mode]][[File:Supercell darkmode.png'
	.. '|x18px|link=Supercell|Tournament sponsored by Supercell.|class=show-when-dark-mode]]'

local ORGANIZER_ICONS = {
	supercell = '[[File:Supercell lightmode.png|x18px|link=Supercell|Supercell|class=show-when-light-mode]]'
		.. '[[File:Supercell darkmode.png|x18px|link=Supercell|Supercell|class=show-when-dark-mode]] ',
	['esports engine'] = '[[File:Esports Engine icon allmode.png|x18px|link=Esports Engine|Esports Engine]] ',
	['esl'] = '[[File:ESL 2019 icon lightmode.png|x18px|link=ESL|ESL|class=show-when-light-mode]]'
		.. '[[File:ESL 2019 icon darkmode.png|x18px|link=ESL|ESL|class=show-when-dark-mode]] ',
	['faceit'] = '[[File:FACEIT icon allmode.png|x18px|link=Esports Engine|Esports Engine]] ',
}

---@class BrawlstarsLeagueInfobox: InfoboxLeague
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

	if id == 'custom' then
		table.insert(widgets, Cell{name = 'Teams', content = {args.team_number}})
	elseif id == 'organizers' then
		local organizers = self.caller:_createOrganizers()
		local title = Table.size(organizers) == 1 and 'Organizer' or 'Organizers'

		return {Cell{name = title, content = organizers}}
	end

	return widgets
end

---@param args table
---@return string
function CustomLeague:appendLiquipediatierDisplay(args)
	return self.data.publishertier and ('&nbsp;' .. SUPERCELL_SPONSORED_ICON) or ''
end

---@param args table
function CustomLeague:customParseArguments(args)
	local publisherTier = (args.publishertier or ''):lower()
	self.data.publishertier = Table.includes(VALID_PUBLISHERTIERS, publisherTier) and publisherTier
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or '')
	Variables.varDefine('tournament_tier', args.liquipediatier or '')
	Variables.varDefine('tournament_prizepool', args.prizepool or '')

	--Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
end

---@param organizer string?
---@return string
function CustomLeague._organizerIcon(organizer)
	return ORGANIZER_ICONS[string.lower(organizer or '')] or ''
end

---@return string[]
function CustomLeague:_createOrganizers()
	local args = self.args
	if not args.organizer then
		return {}
	end

	local organizers = {
		CustomLeague._organizerIcon(args.organizer) .. self:createLink(
			args.organizer, args['organizer-name'], args['organizer-link'], args.organizerref),
	}

	local index = 2
	while not String.isEmpty(args['organizer' .. index]) do
		table.insert(
			organizers,
			CustomLeague._organizerIcon(args['organizer' .. index]) .. self:createLink(
				args['organizer' .. index],
				args['organizer' .. index .. '-name'],
				args['organizer' .. index .. '-link'],
				args['organizerref' .. index])
		)
		index = index + 1
	end

	return organizers
end

return CustomLeague
