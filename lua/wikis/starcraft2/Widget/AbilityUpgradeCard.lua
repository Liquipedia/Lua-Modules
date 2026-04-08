---
-- @Liquipedia
-- page=Module:Widget/AbilityUpgradeCard
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Buildtime = Lua.import('Module:Buildtime', {loadData = true})
local Class = Lua.import('Module:Class')
local Faction = Lua.import('Module:Faction')
local Gas = Lua.import('Module:Gas', {loadData = true})
local Hotkey = Lua.import('Module:Hotkey')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Supply = Lua.import('Module:Supply', {loadData = true})

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MINERALS = Image{imageLight = 'Minerals.gif', link = 'Minerals', verticalAlignment = 'baseline'}

---@class SC2AbilityUpgradeCard: Widget
---@operator call(table): SC2AbilityUpgradeCard
local AbilityUpgradeCard = Class.new(Widget)
AbilityUpgradeCard.defaultProps = {
	name = 'missing name',
}

---@return Widget
function AbilityUpgradeCard:render()
	self.cardType = assert(self.props.cardType,'no "|cardType=" specified')

	self.faction = Faction.read(self.props.faction or self.props.race)
	self.props.caster1 = self.props.caster1 or self.props.caster
	self.props.caster1dn = self.props.caster1dn or self.props.casterdn

	if self.cardType == 'Upgrade' and not Logic.readBool(self.props['no-cat']) then
		mw.ext.TeamLiquidIntegration.add_category('Upgrades')
		if self.faction then
			mw.ext.TeamLiquidIntegration.add_category(Faction.toName(self.faction) .. ' Upgrades')
		end
	end

	return TableWidgets.Table{
		css = {['margin-bottom'] = '0.5rem'},
		columns = {
			{align = 'center', width = '75px'},
			{align = 'left', width = '375px'},
		},
		children = {
			TableWidgets.TableHeader{
				children = TableWidgets.Row{
					children = TableWidgets.CellHeader{
						colspan = 2,
						classes = {Faction.bgClass(self.faction or 't')},
						children = (self.props.link or Page.exists(self.props.name))
							and Link{link = self.props.link or self.props.name, children = self.props.name}
							or self.props.name,
					}
				}
			},
			TableWidgets.TableBody{
				children = TableWidgets.Row{
					children = {
						self:_image(),
						self:_infos(),
					}
				}
			}
		}
	}
end

---@private
---@return Widget
function AbilityUpgradeCard:_image()
	return TableWidgets.Cell{
		children = Image{
			imageLight = self.props.image,
			imageDark = self.props.imageDark,
			size = '62x62px',
		}
	}
end

---@private
---@return Widget
function AbilityUpgradeCard:_infos()
	return TableWidgets.Cell{
		children = {
			self:_renderData(),
			HtmlWidgets.Div{
				css = {
					width = '350px',
					['white-space'] = 'normal',
					['font-size'] = '90%',
				},
				children = self.props.description,
			}
		}
	}
end

---@private
---@return Widget
function AbilityUpgradeCard:_renderData()
	local faction = self.faction or 'default'

	---@param title Renderable
	---@param input Renderable|Renderable[]?
	---@return Widget?
	local makeCell = function(title, input)
		if Logic.isEmpty(input) then return end
		return HtmlWidgets.Div{
			css = {padding = '0.125rem 0.5rem'},
			children = WidgetUtil.collect(
				HtmlWidgets.B{children = title},
				' ',
				input
			)
		}
	end

	return HtmlWidgets.Div{
		css = {
			width = '350px',
			['white-space'] = 'normal',
			['font-size'] = '90%',
			display = 'flex',
			['flex-wrap'] = 'wrap',
			['align-content'] = 'stretch',
		},
		children = WidgetUtil.collect(
			makeCell(
				'Caster:',
				Array.interleave(Array.mapIndexes(function(casterIndex)
					if not self.props['caster' .. casterIndex] then return end
					return Link{link = self.props['caster' .. casterIndex], children = self.props['caster' .. casterIndex .. 'dn']}
				end), ', ')
			),
			makeCell(MINERALS, self.props.min),
			makeCell(Gas[faction], self.props.gas),
			makeCell(Supply[faction], self.props.supply),
			self.cardType == 'Upgrade' and makeCell(Buildtime[faction], self.props.duration) or nil,
			makeCell('Solarite:', self.props.solarite),
			makeCell(Image{imageLight = 'EnergyIcon.gif', link = 'Energy'}, self.props.energy),
			makeCell(Link{link = 'Range'}, self.props.range),
			makeCell(Link{link = 'Cooldown'}, self.props.cooldown),
			self.cardType == 'Ability'
				and makeCell(Link{link = 'Game Speed', children = 'Duration'}, self.props.duration)
				or nil,
			makeCell('Radius:', self.props['effect-radius']),
			makeCell('Damage:', self.props.damage),
			makeCell(
				Link{link = 'Hotkeys per Race', children = 'Hotkey'},
				self.props.hotkey and Hotkey.hotkey{hotkey = self.props.hotkey} or nil
			),
			makeCell(Image{imageLight = 'Minimap research zerg.png', link = ''}, self.props.zerg),
			makeCell(Image{imageLight = 'Minimap research protoss.png', link = ''}, self.props.protoss),
			makeCell(
				'Researched from:',
				self.props['researched_from']
					and Link{link = self.props['researched_from'], children = self.props['alt_researched_from']}
					or nil
			),
			makeCell('Requires:', self.props.requires)
		),
	}
end

return AbilityUpgradeCard
