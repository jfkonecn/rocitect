class BlueprintComponent extends HTMLElement {
	connectedCallback() {
		if (this.shadowRoot) return;

		this.attachShadow({ mode: "open" }).innerHTML = `
        <style>
          p { color: royalblue; font-family: system-ui; }
        </style>
        <p>Hello, world!</p>
      `;
	}
}

customElements.define("rocitect-blueprint", BlueprintComponent);
