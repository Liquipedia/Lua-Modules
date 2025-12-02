---
-- @Liquipedia
-- page=Module:CountryRepresentation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Opponent = Lua.import('Module:Opponent/Custom')
local Page = Lua.import('Module:Page')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Widgets = Lua.import('Module:Widget/All')
local Td = Widgets.Td
local Th = Widgets.Th
local Tr = Widgets.Tr
local DataTable = Widgets.DataTable

local WidgetUtil = Lua.import('Module:Widget/Util')

---@class CountryRepresentation
---@operator call(table<string, any>): CountryRepresentation
---@field config CountryRepresentationConfig
---@field byCountry table<string, standardPlayer[]>
---@field count integer
local CountryRepresentation = Class.new(function(self, args) self:init(args) end)

---@class CountryRepresentationConfig
---@field tournaments string[]
---@field showNoCountry boolean
---@field staff boolean

---@param frame Frame
---@return Widget
function CountryRepresentation.run(frame)
	local args = Arguments.getArgs(frame)
	return CountryRepresentation(args):fetchAndProcess():create()
end

---@param args table
---@return self
function CountryRepresentation:init(args)
	self.config = {
		showNoCountry = Logic.nilOr(Logic.readBoolOrNil(args.noCountry), true),
		staff = Logic.readBool(args.staff),
		tournaments = Array.map(Array.extractValues(Table.filterByKey(args, function(key)
			return key:sub(1, #'tournament') == 'tournament'
		end)), Page.pageifyLink),
	}

	if Logic.isEmpty(self.config.tournaments) then
		self.config.tournaments = {Page.pageifyLink(mw.title.getCurrentTitle().text)}
	end

	return self
end

---@private
---@return string
function CountryRepresentation:_buildConditions()
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('mode'), Comparator.neq, 'award_individual'),
		ConditionTree(BooleanOperator.any):add(
			Array.map(self.config.tournaments, function(page)
				return ConditionNode(ColumnName('pagename'), Comparator.eq, page)
			end)
		),
	}

	return conditions:toString()
end

---@return self
function CountryRepresentation:fetchAndProcess()
	local queryResult = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = 5000,
		offset = 0,
		conditions = self:_buildConditions(),
		query = 'opponentplayers',
	})

	local count = 0
	---@type table<string, boolean>
	local cache = {}
	---@type table<string, standardPlayer[]>
	local byCountry = {}

	---@param player standardPlayer
	local function handleEntry(player)
		local page = player.pageName
		if Logic.isEmpty(page) or cache[page] then return end
		---@cast page -nil

		local flag = player.flag
		if Logic.isEmpty(flag) and not self.config.showNoCountry then return end

		cache[page] = true
		count = count + 1

		byCountry[flag or ''] = byCountry[flag or ''] or {}
		table.insert(byCountry[flag or ''], player)
	end

	Array.forEach(queryResult, function(placement)
		local players = placement.opponentplayers or {}
		Array.forEach(Array.mapIndexes(function (index)
			return Logic.nilIfEmpty(Opponent.playerFromLpdbStruct(players, index))
		end), handleEntry)
		if not self.config.staff then return end
		Array.forEach(Array.mapIndexes(function (index)
			return Logic.nilIfEmpty(Opponent.staffFromLpdbStruct(players, index))
		end), handleEntry)
	end)

	-- sort the players alphabetically for each country
	for _, tbl in pairs(byCountry) do
		table.sort(tbl, function(player1, player2)
			return string.lower(player1.pageName) < string.lower(player2.pageName)
		end)
	end

	self.byCountry = byCountry
	self.count = count

	return self
end

---@return Widget
function CountryRepresentation:create()
	local cache = {rank = 0, counter = 0, lastCount = 0}
	local rows = {}
	for country, players in Table.iter.spairs(self.byCountry, CountryRepresentation._sortCountries) do
		cache.counter = cache.counter + 1
		if #players ~= cache.lastCount then
			cache.rank = cache.counter
		end
		cache.lastCount = #players
		table.insert(rows, Tr{
			children = {
				Td{css = {['text-align'] = 'right'}, children = {cache.rank}},
				Td{children = {Flags.Icon{flag = country}, '&nbsp;', country}},
				Td{css = {['text-align'] = 'right'}, children = {self:_ratioDisplay(#players)}},
				Td{children = Array.interleave(Array.map(players, function (player)
					return PlayerDisplay.InlinePlayer{player = player, showFlag = false}
				end), ', ')},
			}
		})
	end

	local headerRow = Tr{
		children = {
			Th{classes = {'unsortable'}, children = {'#'}},
			Th{children = {'Country / Region'}},
			Th{children = {'Representation'}},
			Th{classes = {'unsortable'}, children = {'Players'}},
		}
	}

	return DataTable{
		classes = {'sortable'},
		children = WidgetUtil.collect(headerRow, rows),
	}
end

---@private
---@param byCountry table<string, standardPlayer[]>
---@param country1 string
---@param country2 string
---@return boolean
function CountryRepresentation._sortCountries(byCountry, country1, country2)
	if #byCountry[country1] ~= #byCountry[country2] then
		return #byCountry[country1] > #byCountry[country2]
	end
	return country1 < country2
end

---@private
---@param numberOfPlayers integer
---@return string
function CountryRepresentation:_ratioDisplay(numberOfPlayers)
	local percentage = self.count > 0 and MathUtil.formatPercentage(numberOfPlayers / self.count) or '-'
	return numberOfPlayers .. ' / ' .. self.count .. ' (' .. percentage .. ')'
end

return CountryRepresentation
