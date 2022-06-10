net.Receive( "credits.sendCredits", function() 
	LocalPlayer().credits = LocalPlayer().credits or {}
	LocalPlayer().credits.amount = net.ReadInt( 32 )
end )

net.Receive( "credits.sendTransaction", function()
	local transaction = net.ReadTable()
	LocalPlayer().credits.transactions[ transaction.id ] = transaction

	if ( ExF4 ) then
		if ( cookie.GetString( "Selected_Tab" ) == "Credits" ) then
			if ( ExF4.Sidebar and ExF4.Sidebar.Panels[ "Credits" ] ) then
				local trans = ExF4.Sidebar.Panels[ "Credits" ].transactionCategory:Add( "ex.credits.pckg" )
				trans:SetData( credits.getPackage( transaction.package ) )
				trans:SetTransaction( transaction )
			end
		end
	end
end )

net.Receive( "credits.updateTransaction", function()
	local transactionid = net.ReadUInt( 32 )
	local key = net.ReadString()
	local value = net.ReadType()

	local transaction = LocalPlayer():GetCreditTransactions()[ transactionid ]

	if ( transaction ) then
		transaction[ key ] = value
	end
end )

net.Receive( "credits.updatePackage", function()
	local packageid = net.ReadString()
	local key = net.ReadString()
	local value = net.ReadType()

	local package = credits.getPackage( packageid )

	if ( package ) then
		package[ key ] = value
	end
end )

-- Currently unused
net.Receive( "credits.playerTransaction", function()
	local pl = net.ReadEntity()
	local package = net.ReadString()

	--[[if ( credits.hudPurchases ) then
		table.insert( credits.hudPurchases, {
			name = pl:Name(),
			packageName = package.name,
			lerp = 0,
			timeOut = CurTime() + 6
		} )
	end]]
end )

net.receiveTableStream( "credits.sendPackages", function( packages )
	LocalPlayer().credits = LocalPlayer().credits or {}

	credits.packages = packages

	if ( LocalPlayer().credits.transactions ) then
		if ( ExF4 ) then
			if ( cookie.GetString( "Selected_Tab" ) == "Credits" ) then
				if ( ExF4.Content and ExF4.Content.loadScreen ) then
					ExF4.Content:Load()
				end
			end
		end
	end
end )

net.receiveTableStream( "credits.sendTransactions", function( transactions )
	LocalPlayer().credits = LocalPlayer().credits or {}

	LocalPlayer().credits.transactions = transactions

	if ( credits.packages ) then
		if ( ExF4 ) then
			if ( cookie.GetString( "Selected_Tab" ) == "Credits" ) then
				if ( ExF4.Sidebar and ExF4.Sidebar.Panels[ "Credits" ] ) then
					ExF4.Sidebar.Panels[ "Credits" ]:Load()
				end
			end
		end
	end
end )

hook( "InitPostEntity", "credits.InitPostEntity", function()
	net.Start( "credits.clientReady" )
	net.SendToServer()
end )