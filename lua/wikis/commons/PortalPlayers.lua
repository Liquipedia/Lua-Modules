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
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate') ---@module 'commons.TeamTemplate'

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local TeamInline = Lua.import('Module:Widget/TeamDisplay/Inline')

local DEFAULT_PLAYER_TYPE = 'Players'
local NONBREAKING_SPACE = '&nbsp;'
local NON_PLAYER_HEADER = Abbreviation.make('Staff', 'Coaches, Managers, Analysts and more')
	.. ' & ' .. Abbreviation.make('Talents', 'Commentators, Observers, Hosts and more')
local BACKGROUND_CLASSES = {
	inactive = 'sapphire-bg',
	retired = 'bg-neutral',
	banned = 'cinnabar-bg',
	['passed away'] = 'gigas-bg',
}

local STATUS_INACTIVE = 'Inactive'

--- @class PortalPlayers
---@operator call(portalPlayerArgs): PortalPlayers
local PortalPlayers = Class.new(function(self, args) self:init(args) end)

---@class portalPlayerArgs
---@field region string?
---@field countries string?
---@field playerType string?
---@field game string?
---@field width string?
---@field status string?
---@field queryOnlyByRegion boolean
---@field showLocalizedName boolean
---@field additionalConditions string?

---Init function for PortalPlayers
---@param args portalPlayerArgs
---@return self
function PortalPlayers:init(args)
	self.args = args
	self.showLocalizedName = Logic.readBool(args.showLocalizedName)
	self.queryOnlyByRegion = Logic.readBool(args.queryOnlyByRegion)
	self.playerType = args.playerType or DEFAULT_PLAYER_TYPE
	self.width = args.width or '720px'

	return self
end

---Create function for PortalPlayers
---@return Html
function PortalPlayers:create()
	local wrapper = mw.html.create('div'):css('overflow-x', 'auto')

	for country, playerData in Table.iter.spairs(self:_getPlayers()) do
		local flag = Flags.Icon({ flag = country, shouldLink = true })

		wrapper:tag('h3')
			:tag('span')
				:addClass('mw-headline')
				:attr('id', country)
				:wikitext(flag .. NONBREAKING_SPACE .. country)

		wrapper
			:node(self:buildCountryTable{
				players = playerData.players,
				flag = flag,
				isPlayer = true,
			})
			:node(self:buildCountryTable{
				players = playerData.nonPlayers,
				flag = flag,
			})
	end

	return wrapper
end

---Retrieves the "player" data
---@return {[string]: {players: table[]?, nonPlayers: table[]?}}
function PortalPlayers:_getPlayers()
	local games = String.isNotEmpty(self.args.game) and
		Array.map(Array.map(mw.text.split(self.args.game, ',', true), String.trim), function (game)
			return '[[extradata_maingame::' .. game .. ']]'
		end)
	local gameConditions = games and ('(' .. table.concat(games, ' OR ') .. ')') or ''

	local countries, regionConditions = PortalPlayers._getCountries(self.args.region, self.args.countries, gameConditions)

	local conditions
	if self.queryOnlyByRegion then
		conditions = regionConditions
	else
		conditions = Array.map(countries, function(country)
			return '[[nationality::' .. country .. ']]'
		end) or {}
	end

	local conditionString = Table.isNotEmpty(conditions) and ('(' .. table.concat(conditions, ' OR ') .. ')') or ''

	local addConidition = function(currentConditions, additionalCondition)
		if String.isNotEmpty(currentConditions) then
			return currentConditions .. ' AND ' .. additionalCondition
		end
		return additionalCondition
	end

	if String.isNotEmpty(gameConditions) then
		conditionString = addConidition(conditionString, gameConditions)
	end

	if String.isNotEmpty(self.args.status) then
		conditionString = addConidition(conditionString, '[[status::' .. self.args.status .. ']]')
	end

	if String.isNotEmpty(self.args.additionalConditions) then
		conditionString = addConidition(conditionString, self.args.additionalConditions)
	end

	local players = mw.ext.LiquipediaDB.lpdb('player', {
		query = 'pagename, id, name, team, status, type, extradata, links, nationality, localizedname, birthdate, deathdate',
		order = 'id asc',
		conditions = conditionString,
		limit = 5000,
	})

	return PortalPlayers._groupPlayerData(players)
end

---Retrieves the country list.
---@param regionsInput string?
---@param countriesInput string?
---@param gameConditions string?
---@return string[], string[]
function PortalPlayers._getCountries(regionsInput, countriesInput, gameConditions)
	local regionConditions = String.isNotEmpty(regionsInput) and
		Array.map(Array.map(mw.text.split(regionsInput --[[@as string]], ',', true), String.trim), function(region)
			return '[[region::' .. region .. ']]'
		end) or {}

	if String.isNotEmpty(countriesInput) then
		---@cast countriesInput -nil
		local countries = Array.map(mw.text.split(countriesInput, ',', true), String.trim)
		if Table.isNotEmpty(countries) then
			return countries, regionConditions
		end
	end

	local conditionString = Table.isNotEmpty(regionConditions)
		and ('(' .. table.concat(regionConditions, ' OR ') .. ')') or ''

	if String.isNotEmpty(conditionString) and String.isNotEmpty(gameConditions) then
		conditionString = conditionString .. ' AND ' .. gameConditions
	elseif String.isNotEmpty(gameConditions) then
		---@cast gameConditions -nil
		conditionString = gameConditions
	end

	local queryData = mw.ext.LiquipediaDB.lpdb('player', {
		query = 'nationality',
		groupby = 'nationality asc',
		order = 'nationality asc',
		conditions = conditionString,
		limit = 5000,
	})

	return Array.map(queryData, function(item) return item.nationality end), regionConditions
end

---Groups the "player" data by country and wether they are players or not
---@param players table[]
---@return {[string]: {players: table[]?, nonPlayers: table[]?}}
function PortalPlayers._groupPlayerData(players)
	local _, groupedByCountry = Array.groupBy(players, function(player) return player.nationality --[[@as string]] end)

	return Table.mapValues(groupedByCountry, function(countryPlayerData)
		local groupedData
		_, groupedData = Array.groupBy(countryPlayerData, function(player)
			local extradata = player.extradata or {}
			return Logic.nilOr(
				Logic.readBoolOrNil(extradata.isplayer),
				(player.type or ''):lower() == 'player' or (extradata.role or ''):lower() == 'player'
			) and 'players' or 'nonPlayers'
		end)
		---@cast groupedData {players: table[], nonPlayers: table[]}
		return groupedData
	end)
end

---Builds the table display for a given set of players
---@param args {players: table[]?, flag: string, isPlayer: boolean?}
---@return Html?
function PortalPlayers:buildCountryTable(args)
	local playerData = Table.extract(args, 'players') --[[@as table?]]
	if Table.isEmpty(playerData) then
		return nil
	end
	---@cast playerData -nil

	local isPlayer = args.isPlayer

	local tbl = mw.html.create('table')
		:addClass('wikitable collapsible smwtable')
		:addClass(not isPlayer and 'collapsed' or nil)
		:css('width', self.width)
		:css('text-align', 'left')
		:node(self:header(args))

	for _, player in ipairs(playerData) do
		tbl:node(self:row(player, isPlayer))
	end

	return tbl
end

---Builds the header for the table
---@param args {flag: string, isPlayer: boolean?}
---@return Html
function PortalPlayers:header(args)
	local teamText = args.isPlayer and ' Team' or ' Team and Role'

	local header = mw.html.create('tr')
		:tag('th')
			:attr('colspan', 4)
			:css('padding-left', '1em')
			:wikitext(args.flag .. ' ' .. (args.isPlayer and self.playerType or NON_PLAYER_HEADER))
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
---@param player table
---@param isPlayer boolean?
---@return Html
function PortalPlayers:row(player, isPlayer)
	local row = mw.html.create('tr')
		:addClass(PortalPlayers._getStatusBackground(player.status, (player.extradata or {}).banned))

	row:tag('td'):wikitext(' '):node(OpponentDisplay.BlockOpponent{opponent = PortalPlayers.toOpponent(player)})
	row:tag('td')
		:wikitext(' ' .. player.name)
		:wikitext(self.showLocalizedName and (' (' .. player.localizedname .. ')') or nil)

	local role = not isPlayer and mw.language.getContentLanguage():ucfirst((player.extradata or {}).role or '') or ''
	local teamText = TeamTemplate.exists(player.team) and tostring(TeamInline {
		name = player.team, displayType = 'standard'
	}) or ''
	if String.isNotEmpty(role) and String.isEmpty(teamText) then
		teamText = role
	elseif String.isNotEmpty(role) then
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

---@param status string?
---@param banned string?
---@return string?
function PortalPlayers._getStatusBackground(status, banned)
	if status == STATUS_INACTIVE then
		status = Logic.emptyOr(Logic.readBoolOrNil(banned), Logic.isNotEmpty(banned))
			and 'banned' or status
	end

	return BACKGROUND_CLASSES[(status or ''):lower()]
end

---Converts the queried data int a readable format by OpponnetDisplay
---Overwritable on a per wiki basis
---@param player table
---@return standardOpponent
function PortalPlayers.toOpponent(player)
	return Opponent.readOpponentArgs(Table.merge(player.extradata, {
		type = Opponent.solo,
		link = player.pagename,
		name = player.id,
		flag = player.nationality,
	}))--[[@as standardOpponent]]
end

return PortalPlayers
