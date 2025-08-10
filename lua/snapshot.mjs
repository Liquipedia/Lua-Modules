import { existsSync, mkdirSync, writeFileSync, readFileSync } from 'fs';
import { resolve, join, dirname } from 'path';
import { chromium } from 'playwright';
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const SNAPSHOT_DIR = resolve(__dirname, 'spec', 'snapshots');
const SNAPSHOT_DIFF_DIR = resolve(__dirname, 'output');
const VIEWPORT = { width: 1280, height: 720 };
const PIXELMATCH_OPTIONS = { threshold: 0.1 };

(async () => {
	const testName = process.argv[2];
	const htmlPath = process.argv[3];
	const shouldUpdate = process.argv.includes('--update-snapshots');

	if (!testName || !htmlPath || !existsSync(htmlPath)) {
		console.error('Error: Invalid arguments or HTML file not found.');
		process.exit(1);
	}


	const referencePath = join(SNAPSHOT_DIR, `${testName}.png`);

	const browser = await chromium.launch();
	const page = await browser.newPage({ viewport: VIEWPORT });
	await page.goto(`file://${htmlPath.replace(/\\/g, '/')}`);
	const newScreenshotBuffer = await page.screenshot({ animations: 'disabled' });
	await browser.close();

	if (shouldUpdate || !existsSync(referencePath)) {
		// Update snapshot, either forced or previous snapshot doesn't exist yet
		mkdirSync(SNAPSHOT_DIR, { recursive: true });
		writeFileSync(referencePath, newScreenshotBuffer);
		process.exit(0);
	} else {
		// Compare with existing snapshot
		const referenceImage = PNG.sync.read(readFileSync(referencePath));
		const newImage = PNG.sync.read(newScreenshotBuffer);
		const { width, height } = referenceImage;

		const diffImage = new PNG({ width, height });

		const mismatchedPixels = pixelmatch(
			referenceImage.data,
			newImage.data,
			diffImage.data,
			width,
			height,
			PIXELMATCH_OPTIONS
		);

		if (mismatchedPixels === 0) {
			process.exit(0);
		} else {
			// Failure, let's save the diff and the new failed image for manual inspection
			mkdirSync(SNAPSHOT_DIFF_DIR, { recursive: true });

			writeFileSync(join(SNAPSHOT_DIFF_DIR, `${testName}-diff.png`), PNG.sync.write(diffImage));
			writeFileSync(join(SNAPSHOT_DIFF_DIR, `${testName}-new.png`), newScreenshotBuffer);

			process.exit(1);
		}
	}
})();