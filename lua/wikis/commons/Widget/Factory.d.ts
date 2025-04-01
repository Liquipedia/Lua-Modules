/* eslint-disable @typescript-eslint/no-unsafe-function-type */

declare namespace WidgetFactory {
	/* Has to add self, see https://github.com/TypeScriptToLua/TypeScriptToLua/issues/1391 */
	function createElement( type: string | Function | object, props?: object, ...children: React.ReactNode[]): React.ReactElement;

	namespace JSX {
		// eslint-disable-next-line @typescript-eslint/no-empty-object-type
		interface IntrinsicElements extends React.JSX.IntrinsicElements {
			/* TODO: Remove elements that don't exist in our environment */
		}
	}
}
