interface ImageProps {
	src: string;
	alt?: string;
	width?: number | string;
	height?: number | string;
	link?: string;
	className?: string;
}

export default function Image({ src, alt = '', width, height, link = '', className = '' }: ImageProps) {
	const generateResizing = () => {
		if (height !== undefined && width !== undefined) {
			return `|${width}x${height}px`;
		} else if (width !== undefined) {
			return `|${width}px`;
		} else if (height !== undefined) {
			return `|x${height}px`;
		} else {
			return '';
		}
	};
	const size = generateResizing();
	const wikiCode = `[[File:${src}${size}|link=${link}|alt=${alt}|class=${className}]]`;
	return wikiCode;
};
