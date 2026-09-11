local Input = game:GetService("UserInputService")
-- Keep touch laptops on the desktop layout. Mobile density is orientation independent.
local Compact = Input.TouchEnabled and not Input.KeyboardEnabled

return {
	Compact = Compact,
	TabHeight = Compact and 26 or 38,
	Window = {
		SidebarInset = Compact and 4 or 14,
		ContentInsetX = Compact and 6 or 24,
		ContentInsetTop = Compact and 6 or 70,
		ContentInsetBottom = Compact and 6 or 18,
	},

	Page = {
		ItemGap = Compact and 2 or 5,
		PaddingLeft = 2,
		PaddingRight = Compact and 5 or 18,
		PaddingTop = 2,
		PaddingBottom = 2,
	},

	Card = {
		Radius = 8,
		LeftInset = Compact and 8 or 16,
		TopInset = Compact and 5 or 12,
		BottomInset = Compact and 5 or 14,
		TrailingInset = Compact and 8 or 16,
		ParticleInset = 3,
		ControlGap = 12,
		DefaultLabelRightReserve = 42,
		ToggleLabelRightReserve = 76,
		ControlLabelRightReserve = 176,
		SwatchLabelRightReserve = 56,
	},

	Dropdown = {
		ChevronInset = 12,
	},
}
