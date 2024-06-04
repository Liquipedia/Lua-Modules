---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Widget = require('Module:Infobox/Widget/All')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}
local TlpdSquad = Class.new(Squad)

---@return self
function TlpdSquad:header()
	table.insert(self.rows, Widget.TableRowNew{
		classes = {'HeaderRow'},
		cells = {
			Widget.TableCellNew{content = {'ID'}, header = true},
			Widget.TableCellNew{header = true}, -- "Team Icon" (most commmonly used for loans)
			Widget.TableCellNew{content = {'Name'}, header = true},
			Widget.TableCellNew{content = {'ELO'}, header = true},
			Widget.TableCellNew{content = {'ELO Peak'}, header = true},
		}
	})

	return self
end

---@return self
function TlpdSquad:title()
	return self
end

---@class StarcraftSquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@return self
function ExtendedSquadRow:elo()
	local eloCurrent, eloPeak = self.model.extradata.eloCurrent, self.model.extradata.eloPeak
	table.insert(self.children,
		Widget.TableCellNew{content = {eloCurrent and (eloCurrent .. ' pts') or '-'}}
	)
	table.insert(self.children,
		Widget.TableCellNew{content = {eloPeak and (eloPeak .. ' pts') or '-'}}
	)

	return self
end

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local args = Arguments.getArgs(frame)
	local tlpd = Logic.readBool(args.tlpd)
	local SquadClass = tlpd and TlpdSquad or Squad

	return SquadUtils.defaultRunManual(frame, SquadClass, function(person, squadType)
		local inputId = person.id --[[@as number]]
		person.race = CustomSquad._queryTLPD(inputId, 'race') or person.race
		person.id = CustomSquad._queryTLPD(inputId, 'name') or person.id
		person.link = person.link or person.altname or person.id
		person.team = CustomSquad._queryTLPD(inputId, 'team_name')
		person.name = (CustomSquad._queryTLPD(inputId, 'name_korean') or '') .. ' ' ..
			(CustomSquad._queryTLPD(inputId, 'name_romanized') or person.name or '')

		local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {type = squadType}))
		squadPerson.extradata.eloCurrent = CustomSquad._queryTLPD(inputId, 'elo')
		squadPerson.extradata.eloPeak = CustomSquad._queryTLPD(inputId, 'peak_elo')
		SquadUtils.storeSquadPerson(squadPerson)

		local row = ExtendedSquadRow(squadPerson)

		row:id():name()

		if tlpd then
			row:elo()
		else
			row:role()
			row:date('joindate', 'Join Date:&nbsp;')

			if squadType == SquadUtils.SquadType.FORMER then
				row:date('leavedate', 'Leave Date:&nbsp;')
				row:newteam()
			elseif squadType == SquadUtils.SquadType.INACTIVE then
				row:date('inactivedate', 'Inactive Date:&nbsp;')
			end
		end

		return row:create()
	end)
end


---@param id number?
---@param value string
---@return string?
function CustomSquad._queryTLPD(id, value)
	if not Logic.isNumeric(id) then
		return
	end

	return String.nilIfEmpty(mw.getCurrentFrame():callParserFunction{
		name = '#external_info:tlpd_player',
		args = {id, value}
	})
end

return CustomSquad
