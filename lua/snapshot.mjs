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

	const browser = await chromium.launch({
		args: ['--disable-web-security']
	});
	const page = await browser.newPage({ viewport: VIEWPORT });

	// The template pulls stylesheets and fonts over the network. If one of them
	// does not arrive the page still renders, just unstyled, and we would
	// happily screenshot that and treat it as the truth. Collect anything that
	// failed so we can bail out instead.
	const missingResources = new Map();
	const isRequired = (resourceType) => ['stylesheet', 'script', 'font'].includes(resourceType);
	const recordMissing = (url, reason) => {
		if (!missingResources.has(url)) {
			missingResources.set(url, reason);
		}
	};

	page.on('requestfailed', (request) => {
		if (isRequired(request.resourceType())) {
			const failure = request.failure();
			recordMissing(request.url(), failure ? failure.errorText : 'request failed');
		}
	});
	page.on('response', (response) => {
		// 3xx is fine, the redirect target gets its own response event
		if (isRequired(response.request().resourceType()) && response.status() >= 400) {
			recordMissing(response.url(), `HTTP ${response.status()}`);
		}
	});

	await page.goto(`file://${htmlPath}`, {waitUntil: "networkidle"});
	const lightScreenshotBuffer = await page.screenshot({ animations: 'disabled' });

	await page.locator('html').evaluate(element => {element.classList.add('theme--dark'); element.classList.remove('theme--light');});
	const darkScreenshotBuffer = await page.screenshot({ animations: 'disabled' });

	await browser.close();

	// Combine both screenshots into one
	let pngLight = PNG.sync.read(lightScreenshotBuffer);
	let pngDark = PNG.sync.read(darkScreenshotBuffer);

	const {width: lightWidth, height: lightHeight} = pngLight;
	const {width: darkWidth, height: darkHeight} = pngDark;

	const combined = new PNG({width: Math.max(lightWidth, darkWidth), height: lightHeight + darkHeight});

	PNG.bitblt(pngLight, combined, 0, 0, lightWidth, lightHeight, 0, 0);
	PNG.bitblt(pngDark, combined, 0, 0, darkWidth, darkHeight, 0, lightHeight);

	if (missingResources.size > 0) {
		console.error(`Error: '${testName}' rendered without resources it needs, refusing to use the result.`);
		missingResources.forEach((reason, url) => console.error(`  - ${url} (${reason})`));
		process.exit(1);
	}

	const writeReference = () => {
		mkdirSync(SNAPSHOT_DIR, { recursive: true });
		writeFileSync(referencePath, PNG.sync.write(combined));
	};

	if (!existsSync(referencePath)) {
		writeReference();
		process.exit(0);
	}

	// Compare with existing snapshot
	const referenceImage = PNG.sync.read(readFileSync(referencePath));
	const { width, height } = referenceImage;
	const sameSize = width === combined.width && height === combined.height;

	const diffImage = new PNG({ width, height });

	// pixelmatch throws on differently sized images, and a size change is a mismatch anyway
	const mismatchedPixels = sameSize ? pixelmatch(
		referenceImage.data,
		combined.data,
		diffImage.data,
		width,
		height,
		PIXELMATCH_OPTIONS
	) : Infinity;

	if (mismatchedPixels === 0) {
		// Leave the reference untouched even when updating. CI runners with different CPUs
		// anti-alias rounded corners a shade apart, and rewriting on that noise makes the
		// snapshots flip back and forth between PRs.
		process.exit(0);
	}

	if (shouldUpdate) {
		writeReference();
		process.exit(0);
	}

	// Failure, let's save the diff and the new failed image for manual inspection
	mkdirSync(SNAPSHOT_DIFF_DIR, { recursive: true });

	if (sameSize) {
		writeFileSync(join(SNAPSHOT_DIFF_DIR, `${testName}-diff.png`), PNG.sync.write(diffImage));
	}
	writeFileSync(join(SNAPSHOT_DIFF_DIR, `${testName}-new.png`), PNG.sync.write(combined));

	process.exit(1);
})();
