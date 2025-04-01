import { SourceNode } from 'source-map';
import ts from 'typescript';
import * as tstl from 'typescript-to-lua';

class CustomPrinter extends tstl.LuaPrinter {
	printCallExpression( expression: tstl.CallExpression ): SourceNode {
		if ( expression.expression.kind === tstl.SyntaxKind.Identifier &&
				expression.params[ 0 ] &&
				expression.params[ 0 ].kind === tstl.SyntaxKind.StringLiteral ) {

			const identifier = expression.expression as tstl.Identifier;
			const firstParam = expression.params[ 0 ] as tstl.StringLiteral;
			if ( identifier.text == 'require' ) {
				identifier.text = 'Lua.import';
				/* a path looks like "commons/Foo/Bar" and we want to convert that to "Module:Foo/Bar" */
				const moduleName = firstParam.value;
				firstParam.value = 'Module:' + moduleName.slice( Math.max( 0, moduleName.indexOf( '/' ) + 1 ) );
			}
		}
		return super.printCallExpression( expression );
	}
}

const plugin: tstl.Plugin = {
	printer: (
		program: ts.Program,
		emitHost: tstl.EmitHost,
		fileName: string,
		file: tstl.File
	) => new CustomPrinter( emitHost, program, fileName ).print( file ),

	afterPrint(
		program: ts.Program,
		options: tstl.CompilerOptions,
		emitHost: tstl.EmitHost,
		result: tstl.ProcessedFile[]
	) {
		// Add a comment to the start of all created Lua files
		for ( const file of result ) {
			file.code = "local Lua = require('Module:Lua')\n" +
				"local WidgetFactory = Lua.import('Module:Widget/Factory')\n" +
				file.code;
		}
	}
};

export default plugin;
