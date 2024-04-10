---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Widget = require('Module:Infobox/Widget/All')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}
local TlpdSquad = Class.new(Squad)

---@return self
function TlpdSquad:header()
	table.insert(self.children, Widget.TableRowNew{
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

---@param args table
---@return self
function ExtendedSquadRow:elo(args)
	table.insert(self.children,
		Widget.TableCellNew{content = {mw.html.create('td'):wikitext(args.eloCurrent and (args.eloCurrent .. ' pts') or '-')}}
	)
	table.insert(self.children,
		Widget.TableCellNew{content = {mw.html.create('td'):wikitext(args.eloPeak and (args.eloPeak .. ' pts') or '-')}}
	)

	return self
end

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local tlpd = Logic.readBool(frame.args.tlpd)
	local SquadClass = tlpd and TlpdSquad or Squad

	return SquadUtils.defaultRunManual(frame, SquadClass, function(player, squadType)
		local row = ExtendedSquadRow()

		local faction = CustomSquad._queryTLPD(player.id, 'race') or player.race
		local id = CustomSquad._queryTLPD(player.id, 'name') or player.id
		local link = player.link or player.altname or id
		local currentTeam = CustomSquad._queryTLPD(player.id, 'team_name')
		local name = CustomSquad._queryTLPD(player.id, 'name_korean') or ''
		local localizedName = CustomSquad._queryTLPD(player.id, 'name_romanized') or player.name or ''
		local elo = CustomSquad._queryTLPD(player.id, 'elo')
		local eloPeak = CustomSquad._queryTLPD(player.id, 'peak_elo')

		row:status(squadType)
		row:id{
			id,
			race = faction,
			link = link,
			team = currentTeam,
			flag = player.flag,
			captain = player.captain,
			role = player.role,
			date = player.leavedate or player.inactivedate,
		}
		row:name{name = name .. ' ' .. localizedName}

		if tlpd then
			row:elo{eloCurrent = elo, eloPeak = eloPeak}
		else
			row:role{role = player.role}
			row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

			if squadType == SquadUtils.SquadType.FORMER then
				row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
				row:newteam{
					newteam = player.newteam,
					newteamrole = player.newteamrole,
					newteamdate = player.newteamdate,
					leavedate = player.leavedate
				}
			elseif squadType == SquadUtils.SquadType.INACTIVE then
				row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
			end
		end

		return row:create(SquadUtils.defaultObjectName(player, squadType))
	end
	)
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
