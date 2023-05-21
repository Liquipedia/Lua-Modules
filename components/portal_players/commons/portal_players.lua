---
-- @Liquipedia
-- wiki=commons
-- page=Module:PortalPlayers
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local Links = require('Module:Links')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')

local NONBREAKING_SPACE = '&nbsp;'
local NON_PLAYER_HEADER = Abbreviation.make('Staff', 'Coaches, Managers, Analysts and more')
	.. Abbreviation.make('Talents', 'Commentators, Observers, Hosts and more')
local BACKGROUND_CLASSES = {
	inactive = 'sapphire-bg',
	retired = 'bg-neutral',
	banned = 'cinnabar-bg',
}

local PortalPlayers = {}

---Entry Point. Builds the player portal
---@param args {region: string?, countries: string?, queryOnlyByRegion: boolean?, playerType: string?, query: string?}
---@return Html
function PortalPlayers.run(args)
	local wrapper = mw.html.create('div'):css('overflow-x', 'auto')

	for country, playerData in Table.iter.spairs(PortalPlayers._getPlayers(args)) do
		local flag = Flags.Icon({flag = country, shouldLink = true})

		wrapper:tag('h3')
			:tag('span')
				:addClass('mw-headline')
				:attr('id', country)
				:wikitext(flag .. NONBREAKING_SPACE .. country)

		wrapper
			:node(PortalPlayers.buildCountryTable(playerData.players, flag, args.playerType or 'Players'))
			:node(PortalPlayers.buildCountryTable(playerData.nonPlayers, flag))
	end

	return wrapper
end

---Retrieves the "player" data
---@param args {region: string?, countries: string?, queryOnlyByRegion: boolean?, playerType: string?, query: string?}
---@return {[string]: {players: table[], nonPlayers: table[]}}
function PortalPlayers._getPlayers(args)
	local countries, regionConditions = PortalPlayers._getCountries(args.region, args.countries)

	local conditions
	if Logic.readBool(args.queryOnlyByRegion) then
		conditions = regionConditions
	else
		conditions = Array.map(countries, function (country)
			return '[[nationality::' .. country .. ']]'
		end) or {}
	end

	local players = mw.ext.LiquipediaDB.lpdb('player', {
		query = args.query or 'pagename, id, name, team, status, type, extradata, links, nationality',
		order = 'id asc',
		conditions = table.concat(conditions, ' OR '),
		limit = 5000,
	})

	return PortalPlayers._groupPlayerData(players)
end

---Retrieves the country list.
---@param regionsInput string?
---@param countriesInput string?
---@return string[]
function PortalPlayers._getCountries(regionsInput, countriesInput)
	local regionConditions = String.isNotEmpty(regionsInput) and
		Array.map(Array.map(mw.text.split(regionsInput, ',', true), String.trim), function (region)
			return '[[region::' .. region .. ']]'
		end) or {}

	if String.isNotEmpty(countriesInput) then
		local countries = Array.map(mw.text.split(countriesInput, ',', true), String.trim)
		if Table.isNotEmpty(countries) then
			return countries, regionConditions
		end
	end

	local queryData = mw.ext.LiquipediaDB.lpdb('player', {
		query = 'nationality',
		groupby = 'nationality asc',
		order = 'nationality asc',
		conditions = table.concat(regionConditions, ' OR '),
		limit = 5000,
	})

	return Array.map(queryData, function(item) return item.nationality end), regionConditions
end

---Groups the "player" data by country and wether they are players or not
---@players table[]
---@return {[string]: {players: table[], nonPlayers: table[]}}
function PortalPlayers._groupPlayerData(players)
	local _, groupedByCountry = Array.groupBy(players, function(player) return player.nationality end)

	return Table.map(groupedByCountry, function(country, countryPlayerData)
		local groupedData
		_, groupedData = Array.groupBy(countryPlayerData, function(player)
			return Logic.nilOr(
				Logic.readBoolOrNil((player.extradata or {}).isplayer),
				(player.type or ''):lower() == 'player'
			) and 'players' or 'nonPlayers'
		end)

		return country, groupedData
	end)
end

---Builds the table display for a given set of players
---@param playerData table[]?
---@param flag string
---@param playerType string?
---@return Html?
function PortalPlayers.buildCountryTable(playerData, flag, playerType)
	if Table.isEmpty(playerData) then
		return nil
	end

	local tbl = mw.html.create('table')
		:addClass('wikitable collapsible smwtable')
		:addClass(String.isEmpty(playerType) and 'collapsed' or nil)
		:css('width', '720px')
		:css('text-align', 'left')
		:node(PortalPlayers.header(flag, playerType))

	local isPlayer = String.isNotEmpty(playerType)

	for _, player in ipairs(playerData) do
		tbl:node(PortalPlayers.row(flag, player, isPlayer))
	end

	return tbl
end

---Builds the header for the table
---@param flag string
---@param playerType string?
---@return Html
function PortalPlayers.header(flag, playerType)
	local teamText = String.isNotEmpty(playerType) and ' Team' or ' Team and Role'

	local header = mw.html.create('tr')
		:tag('th')
			:attr('colspan','4')
			:css('padding-left', '1em')
			:wikitext(flag .. ' ' .. (playerType or NON_PLAYER_HEADER))
			:done()

	local subHeader = mw.html.create('tr')
		:tag('th'):css('width', '175px'):wikitext(' ID'):done()
		:tag('th'):css('width', '175px'):wikitext(' Real Name'):done()
		:tag('th'):css('width', '250px'):wikitext(teamText):done()
		:tag('th'):css('width', '120px'):wikitext(' Links'):done()

	return mw.html.create()
		:node(header)
		:node(subHeader)
end

---Builds a table row
---@param flag string
---@param player table
---@param isPlayer boolean
---@return Html
function PortalPlayers.row(flag, player, isPlayer)
	local row = mw.html.create('tr')
		:addClass(BACKGROUND_CLASSES[(player.status or ''):lower()])

	row:tag('td'):wikitext(' ' .. flag .. NONBREAKING_SPACE .. Page.makeInternalLink({}, player.id, player.pagename))
	row:tag('td'):wikitext(' ' .. player.name)

	local role = not isPlayer and mw.language.getContentLanguage():ucfirst((player.extradata or {}).role or '')
	local teamText = mw.ext.TeamTemplate.teamexists(player.team) and Team.team(nil, player.team) or ''
	if role and String.isEmpty(teamText) then
		teamText = role
	elseif role then
		teamText = teamText .. ' (' .. role .. ')'
	end
	row:tag('td'):wikitext(' ' .. teamText)

	local links = Array.extractValues(Table.map(player.links or {}, function(key, link)
		return key, ' [' .. link .. ' ' .. Links.makeIcon(Links.removeAppendedNumber(key), 25) .. ']'
	end) or {}, Table.iter.spairs)

	row:tag('td')
		:addClass('plainlinks')
		:css('line-height', '25px')
		:css('padding', '1px 2px 1px 2px')
		:css('max-width', '112px')
		:wikitext(table.concat(links))

	return row
end

return Class.export(PortalPlayers)
