hook( "F4MenuTabs", "credits", function()
	ExhibitionF4:AddTab( "Credits", {
		Icon = "ui/exhibitionf4/credits",
		Control = "ex.credits.main",
		Color = Color( 212, 175, 55 ),
		Order = 99,
		OnCreate = pass,
		CanView = function( pl ) 
			return true 
		end
	} )
end )