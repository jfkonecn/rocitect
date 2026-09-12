export class BlueprintComponent extends HTMLElement {
	connectedCallback() {
		if (this.shadowRoot) return;

		const hasRocitectNodes = this.querySelector(
			"rocitect-function-node, rocitect-data-connection",
		);

		const shadowRoot = this.attachShadow({ mode: "open" });
		shadowRoot.innerHTML = `
			<style>
				:host {
					display: block;
					min-height: 100vh;
					background:
						radial-gradient(circle at 15% 10%, rgb(59 130 246 / 16%), transparent 28rem),
						linear-gradient(135deg, #f8fbff 0%, #eef5ff 48%, #f7f7ff 100%);
					color: #102033;
					font-family: Inter, ui-sans-serif, system-ui, sans-serif;
				}

				.shell {
					display: grid;
					gap: 1.25rem;
					padding: clamp(1rem, 2vw, 2rem);
				}

				header {
					display: flex;
					align-items: end;
					justify-content: space-between;
					gap: 1rem;
				}

				h1,
				p {
					margin: 0;
				}

				h1 {
					font-size: clamp(2rem, 6vw, 5.25rem);
					line-height: 0.9;
					letter-spacing: -0.08em;
				}

				.lede {
					max-width: 34rem;
					color: #475569;
					font-size: clamp(0.95rem, 2vw, 1.15rem);
				}

				.badge {
					flex: none;
					padding: 0.45rem 0.7rem;
					border: 1px solid rgb(37 99 235 / 18%);
					border-radius: 999px;
					background: rgb(255 255 255 / 72%);
					color: #1d4ed8;
					font-size: 0.8rem;
					font-weight: 700;
				}

				.canvas {
					position: relative;
					min-height: clamp(31rem, 68vh, 47rem);
					overflow: hidden;
					border: 1px solid rgb(15 23 42 / 10%);
					border-radius: 1.5rem;
					background:
						linear-gradient(rgb(37 99 235 / 6%) 1px, transparent 1px),
						linear-gradient(90deg, rgb(37 99 235 / 6%) 1px, transparent 1px),
						rgb(255 255 255 / 74%);
					background-size: 2rem 2rem;
					box-shadow: inset 0 1px 0 rgb(255 255 255 / 80%), 0 1.5rem 4rem rgb(15 23 42 / 10%);
				}

				.canvas-grid {
					display: grid;
					grid-template-columns: minmax(0, 1fr) minmax(16rem, 22rem);
					gap: 1rem;
				}

				.details {
					align-self: stretch;
					padding: 1rem;
					border: 1px solid rgb(15 23 42 / 10%);
					border-radius: 1.25rem;
					background: rgb(255 255 255 / 82%);
					box-shadow: 0 1rem 2.5rem rgb(15 23 42 / 9%);
				}

				.details[hidden] {
					display: none;
				}

				.details-kind {
					margin: 0 0 0.35rem;
					color: #2563eb;
					font-size: 0.75rem;
					font-weight: 800;
					letter-spacing: 0.08em;
					text-transform: uppercase;
				}

				.details-title {
					margin: 0;
					font-size: 1.2rem;
					line-height: 1.15;
				}

				.details-id {
					margin: 0.35rem 0 0;
					color: #64748b;
					font: 0.78rem/1.35 ui-monospace, SFMono-Regular, Menlo, monospace;
					word-break: break-word;
				}

				.details-body {
					margin: 0.85rem 0 0;
					max-width: none;
					white-space: pre-wrap;
					color: #334155;
					font-size: 0.9rem;
				}

				.details-link {
					display: inline-flex;
					margin-top: 1rem;
					padding: 0.5rem 0.7rem;
					border-radius: 999px;
					background: #2563eb;
					color: #ffffff;
					font-size: 0.85rem;
					font-weight: 750;
					text-decoration: none;
				}

				::slotted(rocitect-function-node) {
					position: absolute;
					z-index: 2;
				}

				@media (max-width: 720px) {
					header {
						align-items: start;
						flex-direction: column;
					}

					.canvas {
						min-height: 42rem;
					}

					.canvas-grid {
						grid-template-columns: 1fr;
					}

					::slotted(rocitect-function-node) {
						left: 50% !important;
						transform: translateX(-50%);
					}
				}
			</style>
			<section class="shell" aria-labelledby="blueprint-title">
				<header>
					<div>
						<h1 id="blueprint-title">Blueprint</h1>
						<p class="lede">A function map for seeing where data enters, how it changes, and where it leaves the system.</p>
					</div>
					<span class="badge">Function flow canvas</span>
				</header>
				<div class="canvas-grid">
					<div class="canvas" role="img" aria-label="Linked functions with animated data-flow connections">
						${hasRocitectNodes ? "<slot></slot>" : ""}
					</div>
					<aside class="details" hidden>
						<p class="details-kind"></p>
						<h2 class="details-title"></h2>
						<p class="details-id"></p>
						<p class="details-body"></p>
						<a class="details-link" hidden>View unit operations</a>
					</aside>
				</div>
			</section>
		`;

		this.addEventListener("click", (event) => this.showDetails(event));
		this.addEventListener("keydown", (event) => {
			if (event.key !== "Enter" && event.key !== " ") return;
			this.showDetails(event);
		});
	}

	private showDetails(event: MouseEvent | KeyboardEvent) {
		const node = event
			.composedPath()
			.find(
				(item) =>
					item instanceof HTMLElement && item.matches("rocitect-function-node"),
			) as HTMLElement | undefined;

		if (!node) return;
		if (event instanceof KeyboardEvent) event.preventDefault();

		const shadowRoot = this.shadowRoot;
		if (!shadowRoot) return;

		const details = shadowRoot.querySelector<HTMLElement>(".details");
		const kind = shadowRoot.querySelector<HTMLElement>(".details-kind");
		const title = shadowRoot.querySelector<HTMLElement>(".details-title");
		const id = shadowRoot.querySelector<HTMLElement>(".details-id");
		const body = shadowRoot.querySelector<HTMLElement>(".details-body");
		const link = shadowRoot.querySelector<HTMLAnchorElement>(".details-link");
		if (!details || !kind || !title || !id || !body || !link) return;

		details.hidden = false;
		kind.textContent = node.getAttribute("detail-kind") ?? "Blueprint item";
		title.textContent =
			node.getAttribute("detail-title") ??
			node.getAttribute("name") ??
			"Details";
		id.textContent = node.getAttribute("detail-id") ?? "";
		body.textContent =
			node.getAttribute("detail-body") ??
			node.getAttribute("description") ??
			"";

		const href = node.getAttribute("detail-href");
		link.hidden = !href;
		if (href) link.href = href;
	}
}
