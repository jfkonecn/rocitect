import { escapeHtml } from "./html";

export class BlueprintDataConnection extends HTMLElement {
	static observedAttributes = ["x1", "y1", "x2", "y2", "label"];

	connectedCallback() {
		this.render();
	}

	attributeChangedCallback() {
		this.render();
	}

	private render() {
		const x1 = Number(this.getAttribute("x1") ?? 0);
		const y1 = Number(this.getAttribute("y1") ?? 0);
		const x2 = Number(this.getAttribute("x2") ?? 0);
		const y2 = Number(this.getAttribute("y2") ?? 0);
		const label = this.getAttribute("label") ?? "data";
		const controlOffset = Math.max(8, Math.abs(x2 - x1) * 0.28);
		const path = `M ${x1} ${y1} C ${x1 + controlOffset} ${y1}, ${x2 - controlOffset} ${y2}, ${x2} ${y2}`;
		const labelX = (x1 + x2) / 2;
		const labelY = (y1 + y2) / 2 - 3;

		const shadowRoot = this.shadowRoot ?? this.attachShadow({ mode: "open" });
		shadowRoot.innerHTML = `
			<style>
				:host {
					position: absolute;
					inset: 0;
					z-index: 1;
					pointer-events: none;
				}

				svg {
					width: 100%;
					height: 100%;
					overflow: visible;
				}

				.track {
					fill: none;
					stroke: rgb(37 99 235 / 24%);
					stroke-linecap: round;
					stroke-width: 1.8;
				}

				.flow {
					animation: data-flow 1.8s linear infinite;
					fill: none;
					stroke: #2563eb;
					stroke-dasharray: 7 13;
					stroke-linecap: round;
					stroke-width: 2.4;
				}

				text {
					paint-order: stroke;
					stroke: #f8fbff;
					stroke-width: 5px;
					fill: #1d4ed8;
					font: 700 0.17rem system-ui, sans-serif;
					letter-spacing: 0.02em;
				}

				@keyframes data-flow {
					to { stroke-dashoffset: -20; }
				}
			</style>
			<svg viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
				<path class="track" d="${path}"></path>
				<path class="flow" d="${path}"></path>
				<text x="${labelX}" y="${labelY}" text-anchor="middle" vector-effect="non-scaling-stroke">${escapeHtml(label)}</text>
			</svg>
		`;
	}
}
