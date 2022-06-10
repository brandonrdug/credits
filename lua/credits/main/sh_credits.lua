--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.getPackage( id )
	for k, v in ipairs( credits.packages ) do
		if ( v.uniqueid == id ) then
			return v
		end
	end
end

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.getDiscountPrice( price, discount )
	return price - ( price * discount )
end

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.getPriceWithPlayer( package, pl )
	local price = package.credits
	local upgradingFrom = {}
	local upgrading

	-- Reduce price if they're upgrading
	if ( package.upgradeFrom and package.buyOnce == 1 ) then
		local activeTransactions = pl:GetCreditTransactions( package.upgradeFrom )

		if ( istable( package.upgradeFrom ) ) then
			for k, v in ipairs( activeTransactions ) do
				price = price + v.credits
				table.insert( upgradingFrom, v )
				upgrading = true
			end
		else
			if ( activeTransactions[ 1 ] ) then
				-- transaction.credits is stored as a negative int representing what it took away
				price = price + activeTransactions[ 1 ].credits
				upgrading = true
			end
		end
	end

	return ( price > 0 ) and ( package.discount and credits.getDiscountPrice( price, package.discount ) or price ) or 0, upgrading, upgradingFrom
end

--[[
	Name: isExpired
	Desc: Checks if a transaction has expired
	Params: <table> Transaction
	Returns: <bool> true/false
]]--

function credits.isExpired( transaction )
	return transaction.expireTime and transaction.expireTime < os.time()
end

--[[
	Name: isValid
	Desc: Checks if a transaction is valid
	Params: <table> Transaction
	Returns: <bool> true/false
]]--

function credits.isValid( transaction )
	return not ( transaction.disabled == 1 ) and not ( transaction.vars.runOnce and transaction.activated == 0 ) and not credits.isExpired( transaction )
end