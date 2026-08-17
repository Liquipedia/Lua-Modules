---
-- @Liquipedia
-- page=Module:BirthdayList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local String = Lua.import('Module:StringUtils')

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName

local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local BirthdayList = {}

---@return VNode
function BirthdayList.persons()
	return Html.Fragment{
		children = Array.map(BirthdayList._groupByMonth(BirthdayList._queryPersons()), BirthdayList._personsDisplay)
	}
end

---@return VNode
function BirthdayList.teams()
	return Html.Fragment{
		children = Array.map(BirthdayList._groupByMonth(BirthdayList._queryTeams()), BirthdayList._teamsDisplay)
	}
end

---@private
---@param persons {month: integer, person: standardPlayer, date: integer, age: integer, roles: string[]}[]
---@param monthIndex integer
---@return VNode?
function BirthdayList._personsDisplay(persons, monthIndex)
	if Logic.isEmpty(persons) then
		return
	end
	return TableWidgets.Table{
		tableClasses = {'collapsible', 'collapsed'},
		css = {width = '600px'},
		sortable = true,
		columns = {{}, {}, {}},
		children = WidgetUtil.collect(
			TableWidgets.TableHeader{
				children = {
					TableWidgets.Row{
						children = TableWidgets.CellHeader{colspan = 3, children = BirthdayList._monthDisplay(monthIndex)},
					},
					TableWidgets.Row{
						children = {
							TableWidgets.CellHeader{children = 'Date'},
							TableWidgets.CellHeader{children = 'Role'},
							TableWidgets.CellHeader{children = 'Person'},
						},
					},
				}
			},
			TableWidgets.TableBody{children = Array.map(persons, BirthdayList._personsRow)}
		),
	}
end

---@private
---@param teams {month: integer, team: standardOpponent, date: integer, age: integer}[]
---@param monthIndex integer
---@return VNode?
function BirthdayList._teamsDisplay(teams, monthIndex)
	if Logic.isEmpty(teams) then
		return
	end
	return TableWidgets.Table{
		tableClasses = {'collapsible', 'collapsed'},
		css = {width = '600px'},
		sortable = true,
		columns = {{}, {}, {}},
		children = WidgetUtil.collect(
			TableWidgets.TableHeader{
				children = {
					TableWidgets.Row{
						children = TableWidgets.CellHeader{colspan = 2, children = BirthdayList._monthDisplay(monthIndex)},
					},
					TableWidgets.Row{
						children = {
							TableWidgets.CellHeader{children = 'Date'},
							TableWidgets.CellHeader{children = 'Team'},
						},
					},
				}
			},
			TableWidgets.TableBody{children = Array.map(teams, BirthdayList._teamRow)}
		),
	}
end

---@private
---@param monthIndex integer
---@return string
function BirthdayList._monthDisplay(monthIndex)
	return DateExt.formatTimestamp('F', DateExt.readTimestamp{year = 1970, month = monthIndex, day = 1} --[[@as integer]])
end

---@private
---@param person {month: integer, person: standardPlayer, date: integer, age: integer, roles: string[]}
---@return VNode
function BirthdayList._personsRow(person)
	return TableWidgets.Row{
		children = {
			TableWidgets.Cell{children = BirthdayList._dateAndAgeDisplay(person)},
			TableWidgets.Cell{children = Array.interleave(person.roles, Html.Br{})},
			TableWidgets.Cell{children = PlayerDisplay.InlinePlayer{player = person.person}},
		},
	}
end

---@private
---@param team {month: integer, team: standardOpponent, date: integer, age: integer}
---@return VNode
function BirthdayList._teamRow(team)
	return TableWidgets.Row{
		children = {
			TableWidgets.Cell{children = BirthdayList._dateAndAgeDisplay(team)},
			TableWidgets.Cell{children = OpponentDisplay.InlineOpponent{opponent = team.team}},
		},
	}
end

---@private
---@param obj {age:integer, date: integer}
---@return table
function BirthdayList._dateAndAgeDisplay(obj)
	return {
		DateExt.formatTimestamp('M j, Y', obj.date),
		' (age ' .. obj.age .. ')',
	}
end

---@private
---@generic V
---@param list V[]
---@return V[][]
function BirthdayList._groupByMonth(list)
	local _, byMonth = Array.groupBy(list, Operator.property('month'))

	-- fill up with empty table so no months are skipped and we have a proper array
	for i = 1, 12 do
		byMonth[i] = byMonth[i] or {}
	end

	return byMonth
end

---@private
---@return {month: integer, person: standardPlayer, date: integer, age: integer, roles: string[]}[]
function BirthdayList._queryPersons()
	local persons = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = tostring(ConditionNode(ColumnName('birthdate'), Comparator.neq, DateExt.defaultDate)),
		query = 'pagename, id, extradata, birthdate, nationality, deathdate',
		limit = 5000,
	})

	return Array.map(persons, function(person)
		local birthDate = DateExt.readTimestamp(person.birthdate)
		return {
			month = DateExt.getMonthOf(birthDate),
			person = Opponent.readSinglePlayerArgs{
				link = person.pagename,
				name = person.id,
				flag = person.nationality,
				faction = (person.extradata or {}).faction,
			},
			date = birthDate,
			age = DateExt.calculateAge(DateExt.nilIfDefaultTimestamp(person.deathdate), birthDate),
			roles = Array.map((person.extradata or {}).roles or {}, String.upperCaseFirst),
		}
	end)
end

---@private
---@return {month: integer, team: standardOpponent, date: integer, age: integer}[]
function BirthdayList._queryTeams()
	local teams = mw.ext.LiquipediaDB.lpdb('team', {
		conditions = tostring(ConditionNode(ColumnName('createdate'), Comparator.neq, DateExt.defaultDate)),
		query = 'pagename, createdate, disbanddate',
		limit = 5000
	})

	return Array.map(teams, function(team)
		local createDate = DateExt.readTimestamp(team.createdate)
		return {
			month = DateExt.getMonthOf(createDate),
			team = Opponent.readOpponentArgs{
				type = Opponent.team,
				template = team.pagename,
			},
			date = createDate,
			age = DateExt.calculateAge(DateExt.nilIfDefaultTimestamp(team.disbanddate), createDate),
		}
	end)
end

return BirthdayList
