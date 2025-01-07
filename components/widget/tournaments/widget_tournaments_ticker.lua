---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Tournaments/Ticker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local Link = Lua.import('Module:Widget/Basic/Link')

---@class TournamentsTickerWidget: Widget
---@operator call(table): TournamentsTickerWidget

local TournamentsTickerWidget = Class.new(Widget)

---@return Widget
function TournamentsTickerWidget:render()
	local getDateString = function()
		local startdateParsed = DateExt.parseIsoDate(tournament.startdate)
		local enddateParsed = DateExt.parseIsoDate(tournament.sortdate)
		local startString = startdateParsed and os.date('%b %d', startdateParsed) or 'TBD'
		local endString = enddateParsed and os.date('%b %d', enddateParsed) or 'TBD'

		if startString == endString then
			endString = ''
		elseif endString ~= 'TBD' and os.date('%m', startdateParsed) == os.date('%m', enddateParsed) then
			endString = os.date('%d', enddateParsed)
		end
		return startString .. (endString ~= '' and ' - ' .. endString or '')
	end

	local tierPill = function (tournament)
		local liquipediatier, liquipediatiertype = Tier.parseFromQueryData(tournament)
		if String.isEmpty(liquipediatier) then
			liquipediatier = DEFAULT_TIER
		end

		local tier = Tier.toName(liquipediatier)
		local tierShort, tierTypeShort = Tier.toShortName(liquipediatier, liquipediatiertype)

		local tierNode, tierTypeNode
		if String.isNotEmpty(tierTypeShort) then
			tierNode = HtmlWidgets.Div{
				classes = {'tournament-badge__chip', 'chip--' .. COLOR_CLASSES[liquipediatier]},
				children = tierShort, -- TODO: Remove later (adds tiertype)
			}
			tierTypeNode = HtmlWidgets.Div{
				classes = {'tournament-badge__text'},
				children = tierTypeShort,
			}
		else
			tierNode = HtmlWidgets.Div{
				classes = {'tournament-badge__text'},
				children = tier,
			}
		end

		return HtmlWidgets.Div{
			classes = {'tournament-badge', 'badge--' .. Logic.emptyOr(
				String.isNotEmpty(liquipediatiertype)
					and (COLOR_CLASSES[liquipediatiertype or ''] or COLOR_CLASSES.default)
					or nil,
				COLOR_CLASSES[liquipediatier or ''],
				COLOR_CLASSES['default']
			)},
			children = {tierNode, tierTypeNode},
		}
	end

	local createTournament = function(tournament)
		local wrap = HtmlWidgets.Div{
			css = {
				display = 'flex',
				gap = '5px',
				['margin-top'] = '0.3em',
				['margin-left'] = '10px',
			},
			children = {
				tierPill(tournament),
				HtmlWidgets.Span{
					classes = {'tournaments-list-name'},
					css = {
						['flex-grow'] = '1',
						['padding-left'] = '25px',
					},
					children = {
						icon,
						Link{
							link = tournament.pagename,
							children = tournament.tickername,
						},
					},
				},
				HtmlWidgets.Small{
					classes = {'tournaments-list-dates'},
					css = {
						['flex-shrink'] = '0',
					},
					children = Link{children = getDateString(tournament), link = tournament.pagename},
				},
			},
		}

		for _, groupName in pairs(filterCategories) do
			wrap = mw.html.create('div')
					 :node(wrap)
					 :attr('data-filter-group', 'filterbuttons-' .. groupName)
					 :attr('data-filter-category', tournament[groupName])
			if tournament.featured then
				wrap:attr('data-curated', '')
			end
		end

		return HtmlWidgets.Li{children = wrap}
	end

	local createSubList = function(name, tournaments)
		local list = HtmlWidgets.Ul{
			classes = {'tournaments-list-type-list'},
			children = Array.map(tournaments, function(tournament)
				return createTournament(tournament, filterCategories)
			end),
		}

		return HtmlWidgets.Li{
			attributes = {
				['data-filter-hideable-group'] = '',
				['data-filter-effect'] = 'fade',
			},
			children = {
				HtmlWidgets.Span{
					classes = {'tournaments-list-heading'},
					children = {name},
				},
				HtmlWidgets.Div{
					children = {list},
				}
			},
		}
	end

	local fallbackElement = HtmlWidgets.Div{
		attributes = {
			['data-filter-hideable-group-fallback'] = '',
		},
		children = {
			HtmlWidgets.Center{
				css = {
					['margin'] = '1.5rem 0',
					['font-style'] = 'italic',
				},
				content = 'No tournaments found for your selected filters!',
			}
		}
	}

	return HtmlWidgets.Div{
		children = {
			HtmlWidgets.Ul{
				classes = {'tournaments-list'},
				attributes = {
					['data-filter-hideable-group'] = '',
					['data-filter-effect'] = 'fade',
				},
				children = {
					createSubList('Upcoming', self.props.upcoming),
					createSubList('Ongoing', self.props.ongoing),
					createSubList('Completed', self.props.completed),
					fallbackElement
				}
			}
		},
	}
end

return TournamentsTickerWidget
