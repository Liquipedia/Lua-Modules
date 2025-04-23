---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Tournament/Label
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local LeagueIcon = require('Module:LeagueIcon')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local Link = Lua.import('Module:Widget/Basic/Link')

---@class TournamentsTickerLabelWidget: Widget
---@operator call(table): TournamentsTickerLabelWidget

local TournamentsTickerTitleWidget = Class.new(Widget)

---@return Widget?
function TournamentsTickerTitleWidget:render()
	local tournament = self.props.tournament
	if not tournament then
		return
	end
	return HtmlWidgets.Fragment{
        children = {
            self.props.displayGameIcon and Game.icon{
                game = tournament.game,
                noLink = true,
                spanClass = 'icon-small',
                size = '50px',
            } or '',
            HtmlWidgets.Div{
                classes = {'tournament-icon'},
                children = {
                    LeagueIcon.display{
                        icon = tournament.icon,
                        iconDark = tournament.iconDark,
                        series = tournament.series,
                        abbreviation = tournament.abbreviation,
                        link = tournament.pageName,
                        options = {noTemplate = true},
                    }
                }
            },
            HtmlWidgets.Div{
                classes = {'tournament-name'},
                children = {
                    Link{
                        link = tournament.pageName,
                        children = tournament.displayName,
                    },
                }
            }
        },
	}
end

return TournamentsTickerTitleWidget
