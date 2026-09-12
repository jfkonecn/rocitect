import { escapeHtml } from "./html";

export class BlueprintFunctionNode extends HTMLElement {
	static observedAttributes = ["name", "description", "tone"];

	connectedCallback() {
		if (!this.hasAttribute("tabindex")) this.tabIndex = 0;
		if (!this.hasAttribute("role")) this.setAttribute("role", "button");
		this.render();
	}

	attributeChangedCallback() {
		this.render();
	}

	private render() {
		const name = this.getAttribute("name") ?? "Function";
		const description = this.getAttribute("description") ?? "";
		const tone = this.getAttribute("tone") ?? "transform";

		const shadowRoot = this.shadowRoot ?? this.attachShadow({ mode: "open" });
		shadowRoot.innerHTML = `
			<style>
				:host {
					cursor: pointer;
					display: block;
					width: min(15rem, 35vw);
					min-width: 10rem;
				}

				:host(:focus-visible) .card {
					outline: 3px solid #2563eb;
					outline-offset: 3px;
				}

				.card {
					position: relative;
					padding: 0.9rem;
					border: 1px solid color-mix(in srgb, var(--accent) 45%, transparent);
					border-radius: 1rem;
					background: linear-gradient(145deg, color-mix(in srgb, var(--accent) 14%, #ffffff), #ffffff 70%);
					box-shadow: 0 1rem 2.5rem rgb(15 23 42 / 12%);
					color: #102033;
				}

				.card::before {
					position: absolute;
					top: 0.9rem;
					left: -0.45rem;
					width: 0.75rem;
					height: 0.75rem;
					border: 2px solid #ffffff;
					border-radius: 999px;
					background: var(--accent);
					content: "";
				}

				.card::after {
					position: absolute;
					right: -0.45rem;
					bottom: 0.9rem;
					width: 0.75rem;
					height: 0.75rem;
					border: 2px solid #ffffff;
					border-radius: 999px;
					background: var(--accent);
					content: "";
				}

				.tone-source { --accent: #0ea5e9; }
				.tone-transform { --accent: #7c3aed; }
				.tone-sink { --accent: #059669; }

				.kind {
					display: inline-flex;
					margin-bottom: 0.45rem;
					padding: 0.15rem 0.45rem;
					border-radius: 999px;
					background: color-mix(in srgb, var(--accent) 15%, transparent);
					color: color-mix(in srgb, var(--accent) 70%, #0f172a);
					font: 700 0.68rem/1.2 system-ui, sans-serif;
					letter-spacing: 0.08em;
					text-transform: uppercase;
				}

				h3 {
					margin: 0;
					font: 750 1rem/1.15 system-ui, sans-serif;
				}

				p {
					margin: 0.35rem 0 0;
					color: #526173;
					font: 0.78rem/1.35 system-ui, sans-serif;
				}
			</style>
			<article class="card tone-${escapeHtml(tone)}">
				<span class="kind">${escapeHtml(tone)}</span>
				<h3>${escapeHtml(name)}</h3>
				<p>${escapeHtml(description)}</p>
			</article>
		`;
	}
}
