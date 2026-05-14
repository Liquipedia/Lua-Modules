---
-- @Liquipedia
-- page=Module:Widget/AbilityUpgradeCard
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Buildtime = Lua.import('Module:Buildtime', {loadData = true})
local Faction = Lua.import('Module:Faction')
local Gas = Lua.import('Module:Gas', {loadData = true})
local Hotkey = Lua.import('Module:Hotkey')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Supply = Lua.import('Module:Supply', {loadData = true})

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MINERALS = Image{imageLight = 'Minerals.gif', link = 'Minerals', verticalAlignment = 'baseline'}

local AbilityUpgradeCard = {}
AbilityUpgradeCard.defaultProps = {
	name = 'missing name',
}

---@param props table
---@return VNode
function AbilityUpgradeCard.render(props)
	local cardType = assert(props.cardType,'no "|cardType=" specified')

	local faction = Faction.read(props.faction or props.race)
	props.caster1 = props.caster1 or props.caster
	props.caster1dn = props.caster1dn or props.casterdn

	if cardType == 'Upgrade' and not Logic.readBool(props['no-cat']) then
		mw.ext.TeamLiquidIntegration.add_category('Upgrades')
		if faction then
			mw.ext.TeamLiquidIntegration.add_category(Faction.toName(faction) .. ' Upgrades')
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
						classes = {Faction.bgClass(faction or 't')},
						children = (props.link or Page.exists(props.name))
							and Link{link = props.link or props.name, children = props.name}
							or props.name,
					}
				}
			},
			TableWidgets.TableBody{
				children = TableWidgets.Row{
					children = {
						AbilityUpgradeCard._image(props),
						AbilityUpgradeCard._infos(props, faction, cardType),
					}
				}
			}
		}
	}
end

---@private
---@param props table
---@return VNode
function AbilityUpgradeCard._image(props)
	return TableWidgets.Cell{
		children = Image{
			imageLight = props.image,
			imageDark = props.imageDark,
			size = '62x62px',
		}
	}
end

---@private
---@param props table
---@param faction string?
---@param cardType string
---@return VNode
function AbilityUpgradeCard._infos(props, faction, cardType)
	return TableWidgets.Cell{
		children = {
			AbilityUpgradeCard._renderData(props, faction, cardType),
			Html.Div{
				css = {
					width = '350px',
					['white-space'] = 'normal',
					['font-size'] = '90%',
				},
				children = props.description,
			}
		}
	}
end

---@private
---@param props table
---@param faction string?
---@param cardType string
---@return VNode
function AbilityUpgradeCard._renderData(props, faction, cardType)
	faction = faction or 'default'

	---@param title Renderable
	---@param input Renderable|Renderable[]?
	---@return VNode?
	local makeCell = function(title, input)
		if Logic.isEmpty(input) then return end
		return Html.Div{
			css = {padding = '0.125rem 0.5rem'},
			children = WidgetUtil.collect(
				Html.B{children = title},
				' ',
				input
			)
		}
	end

	return Html.Div{
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
					if not props['caster' .. casterIndex] then return end
					return Link{link = props['caster' .. casterIndex], children = props['caster' .. casterIndex .. 'dn']}
				end), ', ')
			),
			makeCell(MINERALS, props.min),
			makeCell(Gas[faction], props.gas),
			makeCell(Supply[faction], props.supply),
			cardType == 'Upgrade' and makeCell(Buildtime[faction], props.duration) or nil,
			makeCell('Solarite:', props.solarite),
			makeCell(Image{imageLight = 'EnergyIcon.gif', link = 'Energy'}, props.energy),
			makeCell(Link{link = 'Range'}, props.range),
			makeCell(Link{link = 'Cooldown'}, props.cooldown),
			cardType == 'Ability'
				and makeCell(Link{link = 'Game Speed', children = 'Duration'}, props.duration)
				or nil,
			makeCell('Radius:', props['effect-radius']),
			makeCell('Damage:', props.damage),
			makeCell(
				Link{link = 'Hotkeys per Race', children = 'Hotkey'},
				props.hotkey and Hotkey.hotkey{hotkey = props.hotkey} or nil
			),
			makeCell(Image{imageLight = 'Minimap research zerg.png', link = ''}, props.zerg),
			makeCell(Image{imageLight = 'Minimap research protoss.png', link = ''}, props.protoss),
			makeCell(
				'Researched from:',
				props['researched_from']
					and Link{link = props['researched_from'], children = props['alt_researched_from']}
					or nil
			),
			makeCell('Requires:', props.requires)
		),
	}
end

return Component.component(AbilityUpgradeCard.render, AbilityUpgradeCard.defaultProps)
