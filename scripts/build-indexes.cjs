const { build } = require("esbuild");
const { copyFile, mkdir, readdir, rm, writeFile } = require("node:fs/promises");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const sourceDirectory = path.join(root, "ts");
const vendorJsDirectory = path.join(root, "vendor", "js");
const outputDirectory = path.join(root, "dist");
const development = process.argv.includes("--dev");

async function findEntries(directory) {
	const entries = [];
	const children = await readdir(directory, { withFileTypes: true });

	for (const child of children) {
		const childPath = path.join(directory, child.name);
		if (child.isDirectory()) {
			entries.push(...(await findEntries(childPath)));
		} else if (
			child.isFile() &&
			(child.name === "index.ts" || child.name === "index.css")
		) {
			entries.push(childPath);
		}
	}

	return entries;
}

function entryName(entry) {
	const folder = path.dirname(path.relative(sourceDirectory, entry));
	return folder === "" ? "index" : folder.split(path.sep).join("-");
}

async function copyVendorJavaScript(manifest) {
	let files;
	try {
		files = await readdir(vendorJsDirectory, { withFileTypes: true });
	} catch (error) {
		if (error.code === "ENOENT") return;
		throw error;
	}

	for (const file of files) {
		if (!file.isFile()) continue;
		if (!file.name.endsWith(".js") && !file.name.endsWith(".js.map")) continue;

		await copyFile(
			path.join(vendorJsDirectory, file.name),
			path.join(outputDirectory, file.name),
		);

		if (file.name.endsWith(".js")) {
			const name = `vendor-${path.basename(file.name, ".js")}`;
			manifest[name] = `/assets/${file.name}`;
		}
	}
}

async function main() {
	await mkdir(sourceDirectory, { recursive: true });
	await rm(outputDirectory, { recursive: true, force: true });
	await mkdir(outputDirectory, { recursive: true });

	const entries = await findEntries(sourceDirectory);
	const entryPoints = {};
	for (const entry of entries.sort()) {
		const name = entryName(entry);
		if (entryPoints[name]) {
			throw new Error(
				`Multiple index.ts files resolve to the artifact name "${name}".`,
			);
		}
		entryPoints[name] = entry;
	}

	const manifest = {};
	if (entries.length > 0) {
		const result = await build({
			bundle: true,
			entryNames: "[name]-[hash]",
			entryPoints,
			format: "esm",
			metafile: true,
			minify: !development,
			outdir: outputDirectory,
			platform: "browser",
			sourcemap: development ? "linked" : false,
			target: "es2022",
		});

		for (const [output, metadata] of Object.entries(result.metafile.outputs)) {
			if (!metadata.entryPoint) continue;

			const name = entryName(path.resolve(root, metadata.entryPoint));
			const filename = path.relative(
				outputDirectory,
				path.resolve(root, output),
			);
			manifest[name] = `/assets/${filename.split(path.sep).join("/")}`;
		}
	}
	await copyVendorJavaScript(manifest);

	const sortedManifest = Object.fromEntries(
		Object.entries(manifest).sort(([left], [right]) =>
			left.localeCompare(right),
		),
	);
	await writeFile(
		path.join(outputDirectory, "manifest.json"),
		`${JSON.stringify(sortedManifest, null, "\t")}\n`,
	);
}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
