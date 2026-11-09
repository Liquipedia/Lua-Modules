--- Triple Comment to Enable our LLS Plugin
describe('ArgSchema', function()
	local ArgSchema = require('Module:ArgSchema')
	local Array = require('Module:Array')

	describe('read', function()
		it('converts the inputs by type', function()
			local values = ArgSchema.read({
				{name = 'title'},
				{name = 'enabled', type = 'boolean'},
				{name = 'count', type = 'nonNegativeInteger'},
				{name = 'factor', type = 'number'},
				{name = 'items', type = 'list', separator = ';'},
				{name = 'data', type = 'json'},
			}, {title = 'A', enabled = 'yes', count = '3', factor = '1.5', items = 'x; y', data = '{"a":1}'})

			assert.are_equal('A', values.title)
			assert.is_true(values.enabled)
			assert.are_equal(3, values.count)
			assert.are_equal(1.5, values.factor)
			assert.are_same({'x', 'y'}, values.items)
			assert.are_same({a = 1}, values.data)
		end)

		it('applies the default without input, but keeps a false input', function()
			local parameters = {{name = 'store', type = 'boolean', default = true}}
			assert.is_true(ArgSchema.read(parameters, {}).store)
			assert.is_true(ArgSchema.read(parameters, {store = ''}).store)
			assert.is_false(ArgSchema.read(parameters, {store = 'false'}).store)
		end)

		it('reads lists without input as a new empty list', function()
			local parameters = {{name = 'items', type = 'list'}}
			local first = ArgSchema.read(parameters, {}).items
			assert.are_same({}, first)
			table.insert(first, 'x')
			assert.are_same({}, ArgSchema.read(parameters, {}).items)
		end)

		it('uses a custom read instead of the type', function()
			local values = ArgSchema.read({{name = 'width', read = function(input) return input .. 'px' end}}, {width = '5'})
			assert.are_equal('5px', values.width)
		end)

		it('errors on invalid inputs, naming the parameter as given', function()
			assert.are_equal(0, ArgSchema.read({{name = 'count', type = 'nonNegativeInteger'}}, {count = '0'}).count)
			for _, input in ipairs({'abc', '-1', '1.5'}) do
				assert.error(function() ArgSchema.read({{name = 'count', type = 'nonNegativeInteger'}}, {count = input}) end)
			end
			assert.error(
				function() ArgSchema.read({{name = 'enabled', type = 'boolean'}}, {enabled = 'maybe'}) end,
				'Invalid enabled input: "maybe" is not a boolean'
			)
			assert.error(
				function() ArgSchema.read({{name = 'r{round}points', type = 'number'}}, {r2points = 'x'}) end,
				'Invalid r2points input: "x" is not a number'
			)
		end)

		it('reads aliases by priority, skipping empty inputs', function()
			local parameters = {{name = 'status', aliases = {'bg'}}}
			assert.are_equal('up', ArgSchema.read(parameters, {status = 'up', bg = 'down'}).status)
			assert.are_equal('down', ArgSchema.read(parameters, {status = '', bg = 'down'}).status)
		end)

		it('reads every numbered variant of an indexed parameter', function()
			local values = ArgSchema.read(
				{{name = 'r{round}status', aliases = {'r{round}bg'}}},
				{r1status = 'up', r2bg = 'down', r3status = 'stay', r3bg = 'up', r4bg = '', rstatus = 'x'}
			)
			assert.are_same({[1] = 'up', [2] = 'down', [3] = 'stay'}, values['r{round}status'])
		end)

		it('reads the unnamed parameters of a name that is only a placeholder', function()
			local values = ArgSchema.read({{name = '{opponent}', type = 'json'}}, {'{"a":1}', {b = 2}, r1 = 'x'})
			assert.are_same({{a = 1}, {b = 2}}, values['{opponent}'])
		end)

		it('reads an alias without the placeholder into the default index', function()
			local parameters = {{name = 'r{round}points', aliases = {'points'}, type = 'number'}}
			assert.are_same({[1] = 1, [3] = 2}, ArgSchema.read(parameters, {r1points = '1', points = '2'}, {defaultIndex = 3})
				['r{round}points'])
			assert.are_same({[3] = 4}, ArgSchema.read(parameters, {r3points = '4', points = '2'}, {defaultIndex = 3})
				['r{round}points'])
			assert.are_same({}, ArgSchema.read(parameters, {points = '2'})['r{round}points'])
		end)

		it('errors when reading a parameter that is not declared', function()
			local values = ArgSchema.read({{name = 'title'}}, {title = 'A', other = 'B'})
			assert.is_nil(ArgSchema.read({{name = 'title'}}, {}).title)
			assert.error(function() return values.other end)
		end)
	end)

	describe('documentation', function()
		local parameters = {
			{name = 'always', description = 'Always'},
			{
				name = 'swissOnly',
				condition = function(context) return context.tableType == 'swiss' end,
				description = function(context) return 'Only for ' .. context.tableType end,
			},
			{name = 'r{round}status', aliases = {'r{round}bg', 'status'}, description = ''},
			{name = 'tabletype', hidden = true, description = ''},
		}

		it('filters the parameters by their condition, leaving out hidden ones', function()
			local names = function(context)
				return Array.map(ArgSchema.applicable(parameters, context), function(parameter)
					return parameter.name
				end)
			end
			assert.are_same({'always', 'swissOnly', 'r{round}status'}, names{tableType = 'swiss'})
			assert.are_same({'always', 'r{round}status'}, names{tableType = 'group'})
		end)

		it('resolves descriptions that depend on the context', function()
			assert.are_equal('Always', ArgSchema.description(parameters[1], {}))
			assert.are_equal('Only for swiss', ArgSchema.description(parameters[2], {tableType = 'swiss'}))
		end)

		it('tells unnamed parameters apart', function()
			assert.is_true(ArgSchema.isUnnamed{name = '{opponent}', description = ''})
			assert.is_false(ArgSchema.isUnnamed(parameters[3]))
		end)

		it('shows indexed names with the first indexes', function()
			assert.are_same(
				{{'r1status', 'r2status'}, {'r1bg', 'r2bg'}, {'status'}},
				ArgSchema.displayNames(parameters[3])
			)
		end)
	end)
end)
