local PLAYER = FindMetaTable( "Player" )

function PLAYER:GetCreditTransactions( package )
	if ( self.credits ) then
		if ( package ) then
			local transactions = {}

			for k, v in pairs( self.credits.transactions ) do
				if ( not package or package == v.package or istable( package ) and table.HasValue( package, v.package ) ) then
					table.insert( transactions, v )
				end
			end
		
			return transactions
		else
			return self.credits.transactions
		end
	end
end

function PLAYER:GetActiveTransactions( package )
	local activeTransactions = {}

	for k, v in pairs( self:GetCreditTransactions() ) do
		if ( v.disabled == 0 ) then
			if ( v.expireTime ) then
				if ( v.expireTime > os.time() ) then
					if ( not package or package == v.package or istable( package ) and table.HasValue( package, v.package ) ) then
						table.insert( activeTransactions, v )
					end
				end
			else
				if ( not package or package == v.package or istable( package ) and table.HasValue( package, v.package ) ) then
					table.insert( activeTransactions, v )
				end
			end
		end
	end

	return activeTransactions
end