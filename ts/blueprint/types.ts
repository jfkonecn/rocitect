export type BlueprintFunction = {
	id: string;
	name: string;
	description: string;
	x: number;
	y: number;
	tone: "source" | "transform" | "sink";
};

export type BlueprintConnection = {
	from: string;
	to: string;
	label: string;
};
