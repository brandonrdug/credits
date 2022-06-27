credits.packages = {}

function credits.getData( steamID64, callback )
	credits.db.query( credits.db.queries.getCredits:format( steamID64 ), function( query, data )
		if ( !data[ 1 ] ) then
			if ( callback ) then
				callback( nil, nil, 404 )
			end
			
			return
		end

		local playerCredits = data[ 1 ].credits

		credits.db.query( credits.db.queries.getTransactions:format( steamID64 ), function( query, data )
			if ( callback ) then
				callback( credits, data )
			end
		end )
	end )
end

function credits.getCredits( steamID64, callback )
	credits.db.query( credits.db.queries.getCredits:format( steamID64 ), function( query, data )
		if (data[ 1 ]) then
			callback( data[ 1 ].credits )
		else
			callback( nil, 404 )
		end
	end )
end

function credits.setCredits( steamID64, int, callback, adminID64 )
	credits.getCredits( steamID64, function( amount, error )
		if ( error ) then
			return callback( error )
		end

		HTTP( {
			failed = function() end,
			success = function( code, body, headers )
				if ( code == 404 ) then
					return callback(code)
				end

				callback()
			end, 
			method = "PUT", 
			url = "https://hubtesting.exhibitionrp.com/api/store/addcredits", 
			parameters = {}, 
			headers = {
				["Authorization"] = "auth_token"
			}, 
			body = util.TableToJSON( { 
				["steamid"] = steamID64,
				["credits"] = int - amount,
				["adminid"] = adminID64
			} ),
			type = "application/json" 
		} )
	end )
end

function credits.newPackage( uniqueid, info )
	uniqueid = uniqueid:lower()

	if ( credits.getPackage( uniqueid ) ) then
		return
	end

	local id = #credits.packages + 1
	
	credits.packages[ id ] = {
		[ "id" ]			= id,
		[ "uniqueid" ] 		= uniqueid,
		[ "name" ] 			= info.name,
		[ "category" ] 		= info.category,
		[ "description" ]	= info.description or "",
		[ "credits" ] 		= info.credits,
		[ "type" ] 			= info.type,
		[ "upgradeFrom" ]	= info.upgradeFrom,
		[ "buyOnce" ]		= info.buyOnce and 1 or 0,
		[ "order" ]			= info.order or 0,
		[ "image" ]			= info.image,
		[ "vars" ] 			= info.vars,
		[ "duration" ] 		= info.duration,
		[ "timeScale" ]     = info.timeScale,
		[ "timeFree" ]      = info.timeFree,
		[ "disabled" ]		= 0
	}

	credits.net.newPackage( credits.packages[ id ] )
end

function credits.setDiscount( packageid, percentage )
	local package = credits.getPackage( packageid )

	if ( package ) then
		package.discount = percentage

		credits.net.updatePackage( package, "discount" )
	end
end

function credits.setSale( percentage )
	if ( percentage <= 0 ) then
		percentage = nil
	end

	for k, v in ipairs( credits.packages ) do
		v.discount = ( percentage != nil and percentage ) or nil
		credits.net.updatePackage( v, "discount" )
	end
end

function credits.transact( pl, packageID, charge, callback )
	local package = credits.getPackage( packageID )
	assert( package.disabled == 0, "This package is disabled, how'd they get to buying this?" )

	pl:GetCredits( function( amount, error )
		if ( error ) then
			return callback and callback( error )
		end

		if ( package.buyOnce == 1 ) then
			local transactions = pl:GetCreditTransactions( packageID )

			if ( transactions[ 1 ] ) then
				return ErrorNoHalt( pl, " tried buying " .. packageID .. " a second time. How'd we get here?" )
			end
		end

		local price = 0
		local upgrading, upgradingFrom

		if ( charge ) then
			price, upgrading, upgradingFrom = credits.getPriceWithPlayer( package, pl )
		end

		if ( amount < price ) then
			if ( callback ) then
				callback( "cant_afford" )
			end

			return
		end

		local duration = package.duration

		if ( duration and package.buyOnce == 1 ) then
			local activeTransactions = pl:GetActiveTransactions( packageID )
			
			if ( activeTransactions[ 1 ] ) then
				-- Link time between last transaction and this one, then disable last one
				duration = duration + ( transaction.expireTime - os.time() )

				// @add to callback
				credits.db.query( credits.db.queries.disableTransactionByPackage:format( pl:SteamID64(), packageID ) )

				activeTransactions[ 1 ].disabled = 1
				credits.net.updateTransaction( pl, activeTransactions[ 1 ], "disabled" )
			end
		end

		if ( upgrading ) then
			for k, v in ipairs( upgradingFrom ) do
				-- Disable the old transactions if upgrading
				credits.db.query( credits.db.queries.disableTransactionByPackage:format( pl:SteamID64(), package.upgradeFrom ) )

				v.disabled = 1
				credits.net.updateTransaction( pl, v, "disabled" )
			end
		end

		local time = os.time()
		local id64 = pl:SteamID64()

		pl:SetCredits( amount - price, function()
			credits.db.query( credits.db.queries.insertTransaction:format( duration or "null", id64, package.uniqueid, -price, package.type, credits.db.conn:escape( util.TableToJSON( package.vars ) ), time ), function( query, data )
				query:getNextResults()

				local id = query:lastInsert()

				if ( IsValid( pl ) ) then
					// 2nd query because mysqloo was buggin with query:getNextResults()
					credits.db.query("SELECT `expireTime` FROM `CreditTransactions` WHERE `id` = " .. id, function( query, data )
						if ( IsValid( pl ) ) then
							pl:GetCreditTransactions()[ id ] = {
								[ "id" ] 			= id,
								[ "steamID64" ] 	= id64,
								[ "package" ] 		= package.uniqueid,
								[ "credits" ] 		= -price,
								[ "activated" ] 	= 0,
								[ "type" ]			= package.type,
								[ "vars" ]			= package.vars,
								[ "time" ] 			= time,
								[ "expireTime" ]	= data[ 1 ][ "expireTime" ],
								[ "disabled" ]		= 0
							}

							credits.net.sendCredits( pl )
							credits.net.sendTransaction( pl, pl:GetCreditTransactions()[ id ] )

							hook.Run( "packageBought", pl, package, pl:GetCreditTransactions()[ id ] )

							da.amsg( "Someone bought something! thanks # for buying #!" )
								:Insert( pl )
								:Insert( DA_COLOR, package.name )
								:Send()

							credits.runAction( pl, id )

							if ( callback ) then
								callback()
							end
						else
							if ( callback ) then
								callback( "disconnected" )
							end
						end
					end )
				else
					if ( callback ) then
						callback( "disconnected" )
					end
				end
			end )
		end )
	end )
end

function credits.runAction( pl, transactionid, callback )
	local transaction = pl:GetCreditTransactions()[ transactionid ]
	local package = credits.getPackage( transaction.package )
	local type = credits.config.get( "packageTypes" )[ transaction.type ]

	if ( transaction.disabled == 0 ) then
		if ( transaction.activated == 0 ) then
			if ( not credits.isExpired( transaction ) ) then
				credits.db.query( "UPDATE `CreditTransactions` SET `activated` = 1, `vars` = '" .. credits.db.conn:escape( util.TableToJSON( transaction.vars ) ) .. "' WHERE `steamID64` = '" .. pl:SteamID64() .. "' AND `id` = " .. transaction.id, function( query )
					if ( IsValid( pl ) ) then
						type.action( pl, transaction )

						transaction.activated = 1
						credits.net.updateTransaction( pl, transaction, "activated" )

						if ( transaction.vars.runOnce ) then
							credits.net.oneTimeNotification( pl, transactionid )
						end

						if ( callback ) then
							callback()
						end
					else
						if ( callback ) then
							callback( "disconnected" )
						end
					end
				end )
			else
				if ( callback ) then
					callback( "package_expired" )
				end
			end
		else
			if ( not transaction.vars.runOnce ) then
				if ( not credits.isExpired( transaction ) ) then
					type.action( pl, transaction )
					
					if ( callback ) then
						callback()
					end
				else
					if ( callback ) then
						callback( "package_expired" )
					end
				end
			end
		end
	end
end

function credits.initializePlayer( pl )
	credits.getData( pl:SteamID64(), function( creditAmount, transactions, error )		
		if ( IsValid( pl ) ) then
			if ( error ) then
				creditAmount = 0
				transactions = {}
			end

			pl.credits = { [ "transactions" ] = {} }

			for k, v in ipairs( transactions ) do
				pl.credits.transactions[ v.id ] = v
			end

			// @ cut to only request when opening f4
			// credits.net.sendCredits( pl )

			-- run player inits for package prereqs
			for k, v in pairs( credits.config.get( "packageTypes" ) ) do
				if ( v.playerInit ) then
					v.playerInit( pl )
				end
			end

			for _, transaction in pairs( pl:GetCreditTransactions() ) do
				transaction.vars = util.JSONToTable( transaction.vars )

				local package = credits.getPackage( transaction.package )

				if ( package ) then
					if ( transaction.disabled == 0 ) then
						credits.runAction( pl, transaction.id )
					end
				else
					ErrorNoHalt( "[credits] " .. pl:NameID() .. " runAction failed because of missing package '" .. transaction.package .. "'." )
				end
			end
		end
	end )
end
