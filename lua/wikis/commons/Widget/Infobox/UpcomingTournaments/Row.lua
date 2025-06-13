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
local FnUtil = Lua.import('Module:FnUtil')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local LeagueIcon = Lua.import('Module:LeagueIcon')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local Span = HtmlWidgets.Span
local Tr = HtmlWidgets.Tr
local Td = HtmlWidgets.Td

---@class UpcomingTournamentsRowParameters
---@field data placement
---@field options table?

---@class UpcomingTournamentsRow: Widget
---@operator call(UpcomingTournamentsRowParameters): UpcomingTournamentsRow
---@field props UpcomingTournamentsRowParameters
local UpcomingTournamentsRow = Class.new(Widget)

---@return Widget?
function UpcomingTournamentsRow:render()
	local data = self.props.data
	if not data then return end
	local status = (data.extradata or {}).status
	if status == 'cancelled' or status == 'delayed' then return end

	return HtmlWidgets.Table{
		classes = {'wikitable', 'wikitable-striped', 'infobox_matches_content'},
		children = {
			Tr{
				children = Td{
					classes = Array.extend(
						'versus',
						self:_isHighlighted() and 'tournament-highlighted-bg' or nil
					),
					css = {['text-align'] = 'center'},
					children = {
						LeagueIcon.display{
							icon = data.icon,
							iconDark = data.icondark,
							link = data.pagename
						},
						' ',
						Link{
							link = data.pagename,
							children = data.tournament
						}
					}
				}
			},
			Tr{
				children = Td{
					classes = {'match-filler'},
					children = {
						self:_getCountdown(),
						Div{
							css = {
								width = '100px',
								float = 'right',
								['white-space'] = 'nowrap'
							},
							children = Div{
								classes = {'tournament-span'},
								children = self:_getTournamentSpan()
							}
						}
					}
				}
			}
		}
	}
end

---@private
---@return boolean
function UpcomingTournamentsRow:_isHighlighted()
	return HighlightConditions.tournament(self.props.data, self.props.options)
end

---@private
---@return Widget
function UpcomingTournamentsRow:_getCountdown()
	local data = self.props.data
	local startDateTimestamp = DateExt.readTimestamp(data.startdate)
	local ongoing = DateExt.getCurrentTimestamp() > startDateTimestamp
	return Span{
		classes = {'match-countdown'},
		children = ongoing and Span{
			classes = {'timer-object-countdown-live'},
			children = 'ONGOING!'
		} or Countdown._create{timestamp = startDateTimestamp, rawcountdown = true}
	}
end

---@private
---@return string|string[]
function UpcomingTournamentsRow:_getTournamentSpan()
	local data = self.props.data
	local startDateTimestamp = DateExt.readTimestamp(data.startdate)
	assert(startDateTimestamp)
	local endDateTimestamp = DateExt.readTimestamp(data.date)
	assert(endDateTimestamp)
	local getMonth = FnUtil.curry(DateExt.formatTimestamp, 'M')
	if startDateTimestamp == endDateTimestamp then
		return DateExt.formatTimestamp('M d', startDateTimestamp)
	end
	return {
		DateExt.formatTimestamp('M d', startDateTimestamp),
		' - ',
		DateExt.formatTimestamp(
			getMonth(startDateTimestamp) == getMonth(endDateTimestamp) and 'd' or 'M d',
			endDateTimestamp
		)
	}
end

return UpcomingTournamentsRow
