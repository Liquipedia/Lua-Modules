---
-- @Liquipedia
-- page=Module:PortalPlayers
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local Links = Lua.import('Module:Links')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DEFAULT_PLAYER_TYPE = 'Players'
local NONBREAKING_SPACE = '&nbsp;'
local NON_PLAYER_HEADER = Abbreviation.make{text = 'Staff', title = 'Coaches, Managers, Analysts and more'}
	.. ' & ' .. Abbreviation.make{text = 'Talents', title = 'Commentators, Observers, Hosts and more'}
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
---@return VNode
function PortalPlayers:create()
	local countries = {}
	for country, playerData in Table.iter.spairs(self:_getPlayers()) do
		table.insert(countries, {country = country, playerData = playerData})
	end

	return Html.Div{
		css = {['overflow-x'] = 'auto'},
		children = Array.map(countries, function(entry)
			local flag = Flags.Icon{flag = entry.country, shouldLink = true}

			return WidgetUtil.collect(
				Html.H3{
					children = Html.Span{
						classes = {'mw-headline'},
						attributes = {id = entry.country},
						children = flag .. NONBREAKING_SPACE .. entry.country,
					},
				},
				self:buildCountryTable{
					players = entry.playerData.players,
					flag = flag,
					isPlayer = true,
				},
				self:buildCountryTable{
					players = entry.playerData.nonPlayers,
					flag = flag,
				}
			)
		end),
	}
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
		conditions = Array.map(countries, function (country)
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
		conditionString = addConidition(conditionString, '[[status::'.. self.args.status .. ']]')
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
		Array.map(Array.map(mw.text.split(regionsInput --[[@as string]], ',', true), String.trim), function (region)
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

---@return table[]
function PortalPlayers:columns()
	return {
		{width = '175px'},
		{width = '175px'},
		{width = '250px'},
		{width = '140px'},
	}
end

---Builds the table display for a given set of players
---@param args {players: table[]?, flag: string, isPlayer: boolean?}
---@return VNode?
function PortalPlayers:buildCountryTable(args)
	local playerData = Table.extract(args, 'players') --[[@as table?]]
	if Table.isEmpty(playerData) then
		return nil
	end
	---@cast playerData -nil

	local isPlayer = args.isPlayer

	return TableWidgets.Table{
		css = {width = self.width},
		tableClasses = {'collapsible', not isPlayer and 'collapsed' or nil},
		columns = self:columns(),
		children = {
			self:header(args),
			TableWidgets.TableBody{
				children = Array.map(playerData, function(player)
					return self:row(player, isPlayer)
				end),
			},
		},
	}
end

---Builds the header for the table
---@param args {flag: string, isPlayer: boolean?}
---@return VNode
function PortalPlayers:header(args)
	local teamText = args.isPlayer and ' Team' or ' Team and Role'

	return TableWidgets.TableHeader{
		children = {
			TableWidgets.Row{
				children = TableWidgets.CellHeader{
					colspan = 4,
					css = {
						['padding-left'] = '1em',
					},
					children = args.flag .. ' ' .. (args.isPlayer and self.playerType or NON_PLAYER_HEADER),
				},
			},
			TableWidgets.Row{
				children = {
					TableWidgets.CellHeader{children = 'ID'},
					TableWidgets.CellHeader{children = 'Real Name'},
					TableWidgets.CellHeader{children = teamText},
					TableWidgets.CellHeader{children = 'Links'},
				},
			},
		},
	}
end

---Builds a table row
---@param player table
---@param isPlayer boolean?
---@return VNode
function PortalPlayers:row(player, isPlayer)
	local role = not isPlayer and mw.language.getContentLanguage():ucfirst((player.extradata or {}).role or '') or ''
	local teamText = TeamTemplate.exists(player.team) and tostring(OpponentDisplay.InlineTeamContainer{
		template = player.team, displayType = 'standard'
	}) or ''
	if String.isNotEmpty(role) and String.isEmpty(teamText) then
		teamText = role
	elseif String.isNotEmpty(role) then
		teamText = teamText .. ' (' .. role .. ')'
	end

	local links = Array.extractValues(Table.map(player.links or {}, function(key, link)
		return key, ' [' .. link .. ' ' .. Links.makeIcon(Links.removeAppendedNumber(key), 25) .. ']'
	end) or {}, Table.iter.spairs)

	return TableWidgets.Row{
		classes = WidgetUtil.collect(PortalPlayers._getStatusBackground(player.status, (player.extradata or {}).banned)),
		children = {
			TableWidgets.Cell{
				children = OpponentDisplay.BlockOpponent{opponent = PortalPlayers.toOpponent(player)},
			},
			TableWidgets.Cell{
				nowrap = false,
				children = {
					player.name,
					self.showLocalizedName and (' (' .. player.localizedname .. ')') or ''
				}
			},
			TableWidgets.Cell{
				nowrap = false,
				children = teamText,
			},
			TableWidgets.Cell{
				nowrap = false,
				classes = {'plainlinks'},
				css = {
					['line-height'] = '25px',
					['padding'] = '1px 2px 1px 2px',
				},
				children = links,
			},
		},
	}
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
