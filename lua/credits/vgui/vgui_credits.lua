local modelTypes = {
	[ "weapon" ] = true,
	[ "upgradedWeapon" ] = true,
	[ "ammo" ] = true
}

local PANEL = {}

function PANEL:Init()
	self.Header = self:Add( "EditablePanel" )
	self.Header:SetTall( 32 )
	self.Header:Dock( TOP )

	self.Header.Paint = function( this, w, h )
		draw.RoundedBoxEx( 3, 0, 0, w, h, Color( 11, 17, 21 ), false, true, false, true )

		surface.SetFont( ExUI:GetFont( 18 ) )

		local x = self.Header.purchase:GetWide() + 2
		local text = ( LocalPlayer():GetCredits() .. " Credits" ):Comma()
		local textWidth = surface.GetTextSize( text ) + 8

		lib.DrawRect( x, 0, textWidth, h, color_white, 1 )
		lib.DrawLine( x, 0, x, h, Color( 32, 32, 32 ) )
		lib.DrawLine( x + textWidth, 0, x + textWidth, h, Color( 32, 32, 32 ) )

		draw.SimpleText( text, ExUI:GetFont( 17 ), x + 4, h / 2, color_white, nil, TEXT_ALIGN_CENTER )
	end

	self.Header.PerformLayout = function( this, w, h )
		if ( this:GetChildren()[ 2 ] ) then
			this:GetChildren()[ 2 ]:SetPos( w - 32, 0 )
		end
	end

	self.Header.purchase = self.Header:Add( "DButton" )
	self.Header.purchase:SetSize( 100, 32)
	self.Header.purchase:Dock( LEFT )
	self.Header.purchase:SetText( "" )

	self.Header.purchase.Paint = function( this, w, h )
		lib.DrawRect( 0, 0, w, h, this:IsHovered() and Color( 79, 149, 84) or Color( 69, 139, 74) )
		lib.DrawLine( 0, 0, 0, h, color_white, 1 )
		lib.DrawLine( w, 0, w, h, color_white, 1 )
		draw.SimpleText( "Buy Credits", ExUI:GetFont( 17 ), w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	self.Header.purchase.DoClick = function( this )
		gui.OpenURL( credits.config.get( "storeURL" ) )
	end

	self.Header.purchase:SetupSoundEvents()

	self:Dock( FILL )

	net.Start( "credits.requestCredits" )
	net.SendToServer()

	if ( credits.packages and LocalPlayer().credits.transactions ) then
		self:Load()
	else
		self.loadScreen = self:Add( "Panel" )
		self.loadScreen:Dock( FILL )

		local lerp = 1
		local goal = 2
		local image

		urlImage.new( "https://emoji.gg/assets/emoji/3893-flushed-clown.png", "creditEmoji", function( imageObj )
			imageObj:setSaving( true )
			image = imageObj.material
		end )

		self.loadScreen.Paint = function( this, w, h )
			if ( image ) then
				if ( goal == 2 and lerp >= 1.9 ) then
					goal = 1
				elseif ( goal == 1 and lerp <= 1.05 ) then
					goal = 2
				end

				lerp = Lerp( FrameTime() * 2, lerp, goal )

				local size = 50 * lerp
				local sizeD = size / 2

				lib.DrawRotatedMaterial( w / 2, h / 2, size, size, color_white, image, 0 )
			end
		end

		net.Start( "credits.requestData" )
		net.SendToServer()
	end
end

function PANEL:LayoutDescription()
	if ( self.package and self.package.description and self.pckgView and self.pckgView.bodyText ) then
		local wrapper = {}
		local roll = {}
		local width = 0

		surface.SetFont( ExUI:GetFont( 18 ) )

		for k, v in ipairs( string.Explode( "\n", self.package.description ) ) do
			for k, v in ipairs( string.Explode( " ", v ) ) do
				local vWide = surface.GetTextSize( v .. " " )

				if ( width + vWide > self.pckgView.bodyText:GetWide() - 8 ) then
					table.insert( wrapper, table.concat( roll, " " ) )
					
					roll = {}
					width = 0
				else
					table.insert( roll, v )

					width = width + vWide
				end
			end

			if ( roll[ 1 ] ) then
				table.insert( wrapper, table.concat( roll, " " ) )

				roll = {}
				width = 0
			end
		end

		PrintTable( wrapper )

		self.package.wrappedDescription = wrapper
	end
end

function PANEL:Load()
	if ( IsValid( self.loadScreen ) ) then
		self.loadScreen:Remove()
	end

	self.pckgCategories = {}
	self.pckgContent = self:Add( "EScrollPanel" )
	self.pckgContent:Dock( LEFT )
	self.pckgContent.VBar:SetWide( 3 )
	self.pckgContent.VBar.btnUp.Paint = pass
	self.pckgContent.VBar.btnDown.Paint = pass

	self.pckgContent.Paint = function( this, w, h )
		lib.DrawRect( 0, 0, w, h, color_black, 40 )
	end

	self.pckgView = self:Add( "Panel" )
	self.pckgView:Dock( FILL )

	self.pckgView.header = self.pckgView:Add( "Panel" )
	self.pckgView.header:SetTall( 32 )
	self.pckgView.header:Dock( TOP )
	self.pckgView.header:DockMargin( 8, 8, 8, 8 )
	self.pckgView.header:SetCursor( "hand" )
	self.pckgView.header.Paint = function( this, w, h )
		lib.DrawRect( 0, 0, w, h, Color( 32, 32, 32 ) )
		draw.SimpleText( self.package and self.package.name or "click on something bozo", ExUI:GetFont( 20 ), w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	self.pckgView.bodyText = self.pckgView:Add( "Panel" )
	self.pckgView.bodyText:Dock( FILL )
	self.pckgView.bodyText:DockMargin( 4, 4, 4, 4 )

	self.pckgView.bodyText.Paint = function( this, w, h )
		if ( self.package and self.package.wrappedDescription ) then
			for k, v in ipairs( self.package.wrappedDescription ) do
				draw.SimpleText( v, ExUI:GetFont( 18 ), w / 2, ( k - 1 ) * 18, color_white, TEXT_ALIGN_CENTER, 0 )
			end
		end
	end

	self.pckgView.purchase = self.pckgView:Add( "DButton" )
	self.pckgView.purchase:SetTall( 32 )
	self.pckgView.purchase:Dock( BOTTOM )
	self.pckgView.purchase:DockMargin( 8, 8, 8, 8 )
	self.pckgView.purchase:SetText( "" )

	self.pckgView.purchase.Paint = function( this, w, h )
		if ( self.package ) then
			local affordable = self.packagePnl:Price() <= LocalPlayer():GetCredits()

			lib.DrawRect( 0, 0, w, h, self.packagePnl:PackageOwned() and Color( 100, 100, 100 ) or ( affordable and Color( 69, 139, 74) or Color( 121, 42, 42 ) ) )

			if ( this:IsHovered() ) then
				lib.DrawRect( 0, 0, w, h, color_white, 10 )
			end

			draw.SimpleText( self.packagePnl:PackageOwned() and "Already Owned" or ( affordable and "Purchase" or "You can't afford this" ), ExUI:GetFont( 20 ), w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	end

	self.pckgView.purchase.lastClick = 0

	self.pckgView.purchase.DoClick = function( this )
		if ( self.pckgView.purchase.lastClick <= CurTime() - 2 ) then
			self.pckgView.purchase.lastClick = CurTime()
			
			if ( not self.packagePnl:PackageOwned() and LocalPlayer():GetCredits() >= self.packagePnl:Price() ) then
				Derma_Query( "Are you sure you want to buy " .. self.package.name .. " for " .. self.packagePnl:Price() .. " credits?", "Confirm Purchase", "Yes", function()
					if ( IsValid( self ) ) then
						net.Start( "credits.playerTransaction" )
							net.WriteString( self.package.uniqueid )
						net.SendToServer()
					end
				end, "No", pass )
			end
		end
	end

	self.pckgView.purchase:SetupSoundEvents()

	self:PopulatePackages()
end

function PANEL:PerformLayout( w, h )
	if ( self.pckgContent ) then
		self.pckgContent:SetWide( w / 1.7 )
		self:LayoutDescription()
	end
end

function PANEL:CreateCategory( name, collapsed )
    local category = vgui.Create( "exf4_category", self.pckgContent )
    category:Dock( TOP )
	category:DockMargin( 0, 0, 0, 10 )
	category:SetColumns( 3 )
    category.Collapsed = collapsed
    category:SetData( name, "Packages" )

    return category
end

function PANEL:PopulatePackages( filter )
	for k, v in pairs( self.pckgCategories ) do
		v:Remove()
	end

	self.pckgCategories = {}

	for k in SortedPairsByValue( credits.config.get( "categories" ) ) do
		self.pckgCategories[ k ] = self:CreateCategory( k, false )
	end

	for k, v in pairs( credits.packages ) do
		if ( not ( v.disabled == 1 ) ) then
			local pckg = self.pckgCategories[ v.category ]:Add( "ex.credits.pckg" )
			pckg:SetData( v )
		end
	end

	for k, v in pairs( self.pckgCategories ) do
		if ( #v:GetChildren() - 1 < 1 ) then
			v:Remove()
		end
	end

	self.transactionCategory = self:CreateCategory( "Owned Packages", false )

	for k, v in pairs( LocalPlayer():GetCreditTransactions() ) do
		local package = credits.getPackage( v.package )

		if ( package ) then
			local trans = self.transactionCategory:Add( "ex.credits.pckg" )
			trans:SetData( package )
			trans:SetTransaction( v )
		end
	end
end

function PANEL:SetPackage( panel )
	self.package = panel.package
	self.packagePnl = panel

	self:LayoutDescription()

	if ( self.pckgView.bodyModel ) then
		self.pckgView.bodyModel:Remove()
	end

	if ( self.package.vars.model or modelTypes[ self.package.type ] ) then
		local model = self.package.vars.model

		if ( not model and ( self.package.type == "weapon" or self.package.type == "upgradedWeapon" ) ) then
			local weapon = weapons.Get( self.package.vars.weapon )

			if ( weapon ) then
				if ( weapon.WorldModel and weapon.WorldModel:Trim() ~= "" ) then
					model = weapon.WorldModel
				end
			end
		end

		if ( not model and self.package.type == "ammo" ) then
			local ammoID = game.GetAmmoID( self.package.vars.ammoType )

			for k, v in ipairs( GAMEMODE.AmmoTypes ) do
				if ( v.id == ammoID ) then
					model = v.model
					
					break
				end
			end
		end

		if ( model ) then
			self.pckgView.bodyModel = self.pckgView:Add( "DModelPanel" )
			self.pckgView.bodyModel:Dock( FILL )
			self.pckgView.bodyModel:SetModel( model )

			if ( self.package.vars.material ) then
				self.pckgView.bodyModel.Entity:SetMaterial( self.package.vars.material )
			end

			local mn, mx = self.pckgView.bodyModel.Entity:GetRenderBounds()
			local size = 0
			size = math.max( size, math.abs( mn.x ) + math.abs( mx.x ) )
			size = math.max( size, math.abs(mn.y ) + math.abs( mx.y ) )
			size = math.max( size, math.abs( mn.z ) + math.abs( mx.z ) )

			self.pckgView.bodyModel:SetCamPos( Vector( size - 45, size + 30, size ) )
			self.pckgView.bodyModel:SetLookAt( ( mn + mx ) * 0.5 )
			self.pckgView.bodyModel:SetMouseInputEnabled( false )
			self.pckgView.bodyModel:SetFOV( 50 )
		end
	end
end

vgui.Register( "ex.credits.main", PANEL, "Panel" )

local PCKG = {}

function PCKG:Init()
	self:SetTall( 150 )
	self:SetText( "" )
	self:SetupSoundEvents()
	self.p_Font = ExUI:GetFont( 20 )
	self.p_lastFontSize = 20
end

function PCKG:Paint( w, h )
	lib.DrawRect( 0, 0, w, h, self:IsHovered() and Color( 25, 33, 38 ) or Color( 20, 28, 33 ) )
	lib.DrawRect( 0, 0, w, 28, Color( 10, 18, 23, 160 ) )

	if ( self.package ) then
		draw.SimpleText( self.package.name, self.p_Font, w / 2, 14, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		if ( self.image ) then
			local dW, dH

			if ( istable( self.package.image ) ) then
				dW = ( self.package.image.width == "100%" ) and w or self.package.image.width
				dH = ( self.package.image.height == "100%" ) and h - 56 or self.package.image.height
			end

			lib.DrawMaterial( w / 2 - ( dW and dW / 2 or 32 ), h / 2 - ( dH and dH / 2 or 32 ), dW or 64, dH or 64, color_white, self.image.material)
		end

		if ( not self.transaction ) then
			local price = self:Price()

			lib.DrawRect( 0, h - 28, w, 28, self:PackageOwned() and Color( 100, 100, 100 ) or ( LocalPlayer():GetCredits() >= price and Color( 69, 139, 74) or Color( 121, 42, 42) ) )
			local textWidth = draw.SimpleText( self:PackageOwned() and "Already Owned" or price > 0 and string.Comma( price ) .. " Credits" or "FREE", ExUI:GetFont( 18 ), w / 2, h - 14, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			if ( not self:PackageOwned() and price < self.package.credits ) then
				local tW = draw.SimpleText( math.Round( ( 1 - self:Price() / self.package.credits ) * 100 ) .. "% OFF", ExUI:GetFont( 14 ), 4, h - 14, Color( 255, 255, 255, 180 ), nil, TEXT_ALIGN_CENTER )
			end
		else
			local disabled = self.transaction.disabled == 1
			local activated = self.transaction.vars.runOnce and self.transaction.activated == 1
			local expired = credits.isExpired( self.transaction )

			lib.DrawRect( 0, h - 28, w, 28, ( disabled or activated or expired ) and Color( 100, 100, 100 ) or Color( 69, 139, 74 ) )
			draw.SimpleText( disabled and "Disabled" or activated and "Activated" or expired and "Expired" or "Active", ExUI:GetFont( 18 ), w / 2, h - 14, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	end
end

function PCKG:DoClick()
	if ( self.package ) then
		local parent = self:GetParent():GetParent():GetParent():GetParent() -- lol

		if ( parent.SetPackage ) then
			parent:SetPackage( self )
		end
	end
end

function PCKG:PerformLayout( w, h )
	if ( self.package ) then
		-- auto scale down the font
		surface.SetFont( self.p_Font )
		local size = surface.GetTextSize( self.package.name )
	
		if ( size > self:GetWide() - 4 ) then
			while ( size > self:GetWide() - 4 ) do
				self.p_lastFontSize = self.p_lastFontSize - 1
				self.p_Font = ExUI:GetFont( self.p_lastFontSize )

				surface.SetFont( self.p_Font )
				size = surface.GetTextSize( self.package.name )
			end
		end
	end
end

function PCKG:SetData( package )
	self.package = package

	if ( package.image ) then
		urlImage.new( istable( package.image ) and package.image.src or package.image, package.uniqueid, function( imageObj )
			imageObj:setSaving( true )

			if ( IsValid( self ) ) then
				self.image = imageObj
			end
		end )
	end

	if ( modelTypes[ package.type ] ) then
		local model = package.vars.model

		if ( not model and ( package.type == "weapon" or package.type == "upgradedWeapon" ) ) then
			local weapon = weapons.Get( package.vars.weapon )

			if ( weapon ) then
				if ( weapon.WorldModel and weapon.WorldModel:Trim() ~= "" ) then
					model = weapon.WorldModel
				end
			end
		end

		if ( not model and package.type == "ammo" ) then
			local ammoID = game.GetAmmoID( package.vars.ammoType )

			for k, v in ipairs( GAMEMODE.AmmoTypes ) do
				if ( v.id == ammoID ) then
					model = v.model
					
					break
				end
			end
		end

		if ( model ) then
			self.model = self:Add( "DModelPanel" )
			self.model:Dock( FILL )
			self.model:SetModel( model )
			self.model:DockMargin( 8, 32, 8, 32 )

			if ( self.model and self.model.Entity ) then
				if ( package.vars.material ) then
					self.model.Entity:SetMaterial( package.vars.material )
				end

				local mn, mx = self.model.Entity:GetRenderBounds()
				local size = 0

				size = math.max( size, math.abs( mn.x ) + math.abs( mx.x ) )
				size = math.max( size, math.abs(mn.y ) + math.abs( mx.y ) )
				size = math.max( size, math.abs( mn.z ) + math.abs( mx.z ) )

				self.model:SetCamPos( Vector( size - 45, size + 30, size ) )
				self.model:SetLookAt( ( mn + mx ) * 0.5 )
				self.model:SetMouseInputEnabled( false )
				self.model:SetFOV( 50 )
			end
		end
	end

	if ( not self.model and not package.image ) then
		self:SetTall( 56 )
	end
end

function PCKG:SetTransaction( transaction )
	self.transaction = transaction
end

function PCKG:Price()
	return credits.getPriceWithPlayer( self.package, LocalPlayer() )
end

function PCKG:PackageOwned()
	if ( self.package.buyOnce == 1 ) then
		local transactions = LocalPlayer():GetCreditTransactions( self.package.uniqueid )

		if ( transactions[ 1 ] ) then
			return true
		end
	end

	return false
end

vgui.Register( "ex.credits.pckg", PCKG, "DButton" )