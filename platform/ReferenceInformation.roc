ReferenceInformation := [].{
	ReferenceId : Str

	ReferenceKind(customKind) := [Documentation, BusinessLogic, CodeStandard, UxDesign, CustomKind(customKind)]

	ReferenceSource := [Url(Str), FilePath(Str), Inline]

	ReferenceContent(customContent) := [Text(Str), Markdown(Str), CustomContent(customContent)]

	ReferenceItem(customKind, customContent) := {
		id : ReferenceId,
		title : Str,
		kind : ReferenceKind(customKind),
		source : ReferenceSource,
		content : ReferenceContent(customContent),
		tags : List(Str),
	}

	ReferenceQuery := {
		query : Str,
		tags : List(Str),
		limit : U64,
	}

	ReferenceQueryResponse(customKind, customContent) := {
		query : ReferenceQuery,
		results : List(ReferenceItem(customKind, customContent)),
	}
}
