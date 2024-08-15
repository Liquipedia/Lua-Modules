---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class OverwatchLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local BLIZZARD_TIERS = {
	owl = 'Overwatch League',
	owc = 'Overwatch Contenders',
	owcs = 'Overwatch Champions Series',
	owwc = 'Overwatch World Cup',
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.publishertier = self:_validPublisherTier(args.blizzardtier) and args.blizzardtier:lower()
end

---@param date string
---@return string
function compareDates(date1, date2)
    return date1 > date2
end

function getGame(args)
    local endDate = Variables.varDefault('tournament_enddate')
    if String.isNotEmpty(args.game) then
        return args.game
    else
        if compareDates(endDate, '2022-10-04') then
            return 'overwatch2'
        else
            return 'overwatch'
        end
    end
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
		Cell{name = 'Teams', content = {args.team_number}},
		Cell{name = 'Game', content = {Game.text{game = args.game}}},
		Cell{name = 'Players', content = {args.player_number}}
	)
	elseif id == 'customcontent' then
		if String.isNotEmpty(args.map1) then
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = self.caller:_makeBasedListFromArgs('map')})
		end
	elseif id == 'liquipediatier' then
		if self.caller:_validPublisherTier(args.blizzardtier) then
			table.insert(widgets,
				Cell{
					name = 'Blizzard Tier',
					content = {'[['..BLIZZARD_TIERS[args.blizzardtier:lower()]..']]'},
					classes = {'valvepremier-highlighted'}
				}
			)
		end
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(League:getAllArgsForBase(args, 'map'), ';')

	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''

	return lpdbData
end

---@param base string
---@return string[]
function CustomLeague:_makeBasedListFromArgs(base)
	local firstArg = self.args[base .. '1']
	local foundArgs = {PageLink.makeInternalLink({}, firstArg)}
	local index = 2

	while String.isNotEmpty(self.args[base .. index]) do
		local currentArg = self.args[base .. index]
		table.insert(foundArgs, '&nbsp;• ' ..
			tostring(self:_createNoWrappingSpan(
				PageLink.makeInternalLink({}, currentArg)
			))
		)
		index = index + 1
	end

	return foundArgs
end

---@param publishertier string?
---@return string?
function CustomLeague:_validPublisherTier(publishertier)
	return BLIZZARD_TIERS[string.lower(publishertier or '')]
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_tier', args.liquipediatier)

	--Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)

	if self:_validPublisherTier(args.blizzardtier) then
		Variables.varDefine('tournament_blizzard_premier', args.blizzardtier:lower())
	end

end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local categories = {}

	if not Game.name{game = args.game} then
		table.insert(categories, 'Tournaments without game version')
	else
		table.insert(categories, Game.name{game = args.game} .. ' Competitions')
	end

	return categories
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
