import { BlueprintComponent } from "./blueprint";
import { BlueprintDataConnection } from "./data-connection";
import { BlueprintFunctionNode } from "./function-node";

if (!customElements.get("rocitect-function-node")) {
	customElements.define("rocitect-function-node", BlueprintFunctionNode);
}

if (!customElements.get("rocitect-data-connection")) {
	customElements.define("rocitect-data-connection", BlueprintDataConnection);
}

if (!customElements.get("rocitect-blueprint")) {
	customElements.define("rocitect-blueprint", BlueprintComponent);
}
