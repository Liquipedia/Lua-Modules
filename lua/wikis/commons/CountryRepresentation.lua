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
local ConditionUtil = Condition.Util

local TableWidgets = Lua.import('Module:Widget/Table2/All')
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
---@field player boolean
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
		player = Logic.nilOr(Logic.readBoolOrNil(args.player), true),
		staff = Logic.readBool(args.staff),
		tournaments = Array.map(Array.extractValues(Table.filterByKey(args, function(key)
			return key:sub(1, #'tournament') == 'tournament'
		end)), Page.pageifyLink),
	}

	assert(self.config.player or self.config.staff, 'Invalid config: at least one of |player= or |staff= must be true')

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
		ConditionUtil.anyOf(ColumnName('pagename'), self.config.tournaments)
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
		if self.config.player then
			Array.forEach(Array.mapIndexes(function (index)
				return Logic.nilIfEmpty(Opponent.playerFromLpdbStruct(players, index))
			end), handleEntry)
		end
		if self.config.staff then
			Array.forEach(Array.mapIndexes(function (index)
				return Logic.nilIfEmpty(Opponent.staffFromLpdbStruct(players, index))
			end), handleEntry)
		end
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
		table.insert(rows, TableWidgets.Row{children = {
			TableWidgets.Cell{children = {cache.rank}},
			TableWidgets.Cell{children = {Flags.Icon{flag = country}, '&nbsp;', country}},
			TableWidgets.Cell{
				attributes = {['data-sort-value'] = #players},
				children = self:_ratioDisplay(#players)
			},
			TableWidgets.Cell{
				nowrap = false,
				children = Array.interleave(Array.map(players, function (player)
					return PlayerDisplay.InlinePlayer{player = player, showFlag = false}
				end), ', ')
			},
		}})
	end

	local headerRow = TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = {
			TableWidgets.CellHeader{children = {'#'}},
			TableWidgets.CellHeader{children = {'Country / Region'}},
			TableWidgets.CellHeader{children = {'Representation'}},
			TableWidgets.CellHeader{children = Array.interleave(WidgetUtil.collect(
				self.config.player and 'Players' or nil,
				self.config.staff and 'Staff' or nil
			), ' & ')},
		}}
	}}

	return TableWidgets.Table{
		sortable = true,
		columns = {
			{
				align = 'right',
				unsortable = true,
			},
			{align = 'left'},
			{
				align = 'right',
				sortType = 'number',
			},
			{
				align = 'left',
				minWidth = '15rem',
				unsortable = true,
			},
		},
		children = {
			headerRow,
			TableWidgets.TableBody{children = rows}
		},
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
