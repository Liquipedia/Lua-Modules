--- Triple Comment to Enable our LLS Plugin
describe('Standings documentation', function()
	local ArgSchema = require('Module:ArgSchema')
	local ArgSchemaDocumentation = require('Module:ArgSchema/Documentation')
	local StandingsParameters = require('Module:Standings/Parameters')

	local originalPreprocess

	before_each(function()
		originalPreprocess = mw.frame.preprocess
		mw.frame.preprocess = function(_, text) return text end
	end)

	after_each(function()
		mw.frame.preprocess = originalPreprocess
	end)

	---@param section string
	---@param tableType string
	---@return string
	local function render(section, tableType)
		return tostring(ArgSchemaDocumentation.parameters{
			schema = 'Standings/Parameters',
			section = section,
			tabletype = tableType,
		})
	end

	it('describes every parameter in every context', function()
		for _, section in ipairs({'header', 'round', 'opponent'}) do
			for _, tableType in ipairs({'swiss', 'group', 'ffa'}) do
				local context = {tabletype = tableType}
				for _, parameter in ipairs(ArgSchema.applicable(StandingsParameters[section], context)) do
					local description = ArgSchema.description(parameter, context)
					assert.is_true(type(description) == 'string' and description ~= '', parameter.name)
				end
			end
		end
	end)

	it('lists the parameters of the table type with their defaults', function()
		local swiss = render('header', 'swiss')
		assert.is_truthy(swiss:find('&#124;import&#61;true', 1, true))
		assert.is_truthy(swiss:find('&#124;placements&#61;', 1, true))
		assert.is_falsy(swiss:find('&#124;p1&#61;', 1, true))
		assert.is_truthy(swiss:find('win=1, draw=0.5, loss=0', 1, true))

		local group = render('header', 'group')
		assert.is_falsy(group:find('&#124;placements&#61;', 1, true))
		assert.is_truthy(group:find('win=3, draw=1, loss=0', 1, true))

		assert.is_truthy(render('header', 'ffa'):find('&#124;p1&#61;', 1, true))
		assert.is_truthy(swiss:find('&#124;overtime&#61;false', 1, true))
		assert.is_truthy(swiss:find('&#124;matchgroups&#61;', 1, true))
		assert.is_truthy(swiss:find(
			'<dt><code class="nowrap">&#124;&#123;&#123;TeamOpponent&#124;...&#125;&#125;</code></dt>', 1, true
		))
		assert.is_falsy(swiss:find('&#124;1&#61;', 1, true))
		assert.is_falsy(swiss:find('tabletype', 1, true))
	end)

	it('lists indexed parameters with their aliases', function()
		assert.is_truthy(render('opponent', 'swiss'):find(
			'&#124;r1points&#61;</code>, <code class="nowrap">&#124;r2points&#61;</code>, …, '
				.. '<code class="nowrap">&#124;points&#61;</code>',
			1, true
		))
	end)
end)
