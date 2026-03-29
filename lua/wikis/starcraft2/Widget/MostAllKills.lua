local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')

---@class MostAllKills: Widget
---@operator call(table): MostAllKills
local MostAllKills = Class.new(Widget)

---@return Html
function MostAllKills:render()
	return TableWidgets.Table{
		sortable = false,
		tableClasses = {'prizepooltable', 'collapsed'},
		tableAttributes = {
			['data-cutafter'] = 5,
			['data-opentext'] = 'Show more',
			['data-closetext'] = 'Show less',
		},
		columns = {
			{align = 'left'},
			{align = 'center'},
		},
		children = {
			TableWidgets.TableHeader{
				children = TableWidgets.Row{
					children = {
						TableWidgets.CellHeader{children = 'Player'},
						TableWidgets.CellHeader{children = 'All-kills'},
					}
				}
			},
			TableWidgets.TableBody{children = self:_rows()}
		},
	}
end

---@return Widget[]
function MostAllKills:_rows()
	local allKillList = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::allkills]]',
		order = 'information desc, date desc, pagename asc',
		query = 'information, pagename',
		limit = 5000,
        })

	return Array.map(allKillList, function(allKillInfo)
		return TableWidgets.Row{
			children = {
				TableWidgets.Cell{children = self:_player(allKillInfo.pagename)},
				TableWidgets.Cell{children = allKillInfo.information},
			}
		}
	end)
end

---@param pageName string
---@return Widget
function MostAllKills:_player(pageName)
	local playerInfo = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. pageName .. ']]',
		query = 'extradata, nationality, id',
		limit = '1',
        })[1] or {}

	return OpponentDisplay.BlockOpponent{opponent = Opponent.readOpponentArgs{
		name = playerInfo.id or pageName,
		faction = (playerInfo.extradata or {}).faction,
		flag = playerInfo.nationality,
		link = pageName,
		type = Opponent.solo,
	}}
end

return MostAllKills
