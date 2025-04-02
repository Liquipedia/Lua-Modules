import { SourceNode } from 'source-map';
import ts from 'typescript';
import * as tstl from 'typescript-to-lua';

const LUA_FOLDER = '/lua/wikis/';
const LUA_IMPORTS = `local Lua = require('Module:Lua')\nlocal WidgetFactory = Lua.import('Module:Widget/Factory')\n`;

class CustomPrinter extends tstl.LuaPrinter {
	printCallExpression(expression: tstl.CallExpression): SourceNode {
		if (
			expression.expression.kind === tstl.SyntaxKind.Identifier &&
			expression.params[0] &&
			expression.params[0].kind === tstl.SyntaxKind.StringLiteral
		) {
			const identifier = expression.expression as tstl.Identifier;
			const firstParam = expression.params[0] as tstl.StringLiteral;
			if (identifier.text == 'require') {
				identifier.text = 'Lua.import';
				/* a path looks like "commons/Foo/Bar" and we want to convert that to "Module:Foo/Bar" */
				const moduleName = firstParam.value;
				firstParam.value =
					'Module:' + moduleName.slice(Math.max(0, moduleName.indexOf('/') + 1));
			}
		}
		return super.printCallExpression(expression);
	}
}

const plugin: tstl.Plugin = {
	printer: (program: ts.Program, emitHost: tstl.EmitHost, fileName: string, file: tstl.File) =>
		new CustomPrinter(emitHost, program, fileName).print(file),

	afterPrint(
		program: ts.Program,
		options: tstl.CompilerOptions,
		emitHost: tstl.EmitHost,
		result: tstl.ProcessedFile[]
	) {
		for (const file of result) {
			const relativePath = file.fileName.substring(
				file.fileName.indexOf(LUA_FOLDER) + LUA_FOLDER.length
			);
			const [wiki, ...moduleParts] = relativePath.split('/');
			const moduleName = moduleParts.join('/').replace('.tsx', '').replace('.ts', '');

			const LUA_MAGIC = `---
-- @Liquipedia
-- wiki=${wiki}
-- page=Module:${moduleName}
--
-- Source can be found at https://github.com/Liquipedia/Lua-Modules/blob/main${LUA_FOLDER}${relativePath}
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--`;
			file.code = `${LUA_MAGIC}\n${LUA_IMPORTS}\n${file.code}`;
		}
	},
};

export default plugin;
