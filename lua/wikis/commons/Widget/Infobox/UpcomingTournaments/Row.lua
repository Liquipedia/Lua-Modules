---
-- @Liquipedia
-- page=Module:Widget/Infobox/UpcomingTournaments/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')

local Widget = Lua.import('Module:Widget')
local DateRange = Lua.import('Module:Widget/Misc/DateRange')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span
local Tr = HtmlWidgets.Tr
local Td = HtmlWidgets.Td
local TournamentTitle = Lua.import('Module:Widget/Tournament/Title')

---@class UpcomingTournamentsRowParameters
---@field tournament StandardTournament?
---@field options table?

---@class UpcomingTournamentsRow: Widget
---@operator call(UpcomingTournamentsRowParameters): UpcomingTournamentsRow
---@field props UpcomingTournamentsRowParameters
local UpcomingTournamentsRow = Class.new(Widget)

---@return Widget?
function UpcomingTournamentsRow:render()
	local tournament = self.props.tournament
	if not tournament then return end
	local status = tournament.status
	if status == 'cancelled' or status == 'delayed' then
		return
	end

	---@return Widget
	local function getCountdown()
		local startDateTimestamp = DateExt.readTimestamp(tournament.startDate.timestamp)
		local ongoing = DateExt.getCurrentTimestamp() > startDateTimestamp
		return Span{
			classes = {'match-countdown'},
			children = ongoing and Span{
				classes = {'timer-object-countdown-live'},
				children = 'ONGOING!'
			} or Countdown.create{timestamp = startDateTimestamp, rawcountdown = true}
		}
	end

	return HtmlWidgets.Table{
		classes = {'wikitable', 'wikitable-striped', 'infobox_matches_content'},
		children = {
			Tr{children = Td{
				classes = Array.extend(
					'versus',
					tournament:isHighlighted(self.props.options) and 'tournament-highlighted-bg' or nil
				),
				css = {['text-align'] = 'center'},
				children = TournamentTitle{tournament = tournament}
			}},
			Tr{children = Td{
				classes = {'match-filler'},
				children = {
					getCountdown(),
					Div{
						css = {
							width = '100px',
							float = 'right',
							['white-space'] = 'nowrap'
						},
						children = Div{
							classes = {'tournament-span'},
							children = DateRange{
								startDate = tournament.startDate,
								endDate = tournament.endDate,
							}
						}
					}
				}
			}}
		}
	}
end

return UpcomingTournamentsRow
