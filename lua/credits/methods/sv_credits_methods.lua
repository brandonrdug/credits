net.addStrings( "credits.upgradeWeapon", "credits.updatePropCount" )

function credits.net.updatePropCount( pl )
	net.Start( "credits.updatePropCount" )
		net.WriteUInt( pl.credits.propCount, 10 )
	net.Send( pl )
end

function credits.spawnMethods( pl )
	if ( pl.credits ) then
		if ( pl.credits.weapons ) then
			if ( pl.credits.weapons[ 1 ] ) then
				for k, v in ipairs( pl.credits.weapons ) do
					if ( credits.isValid( v ) ) then
						local weapon = pl:Give( v.vars.weapon )
						weapon.permanentWeapon = true
					else
						table.remove( pl.credits.weapons, k )
					end
				end
			end
		end

		if ( pl.credits.ammo ) then
			if ( pl.credits.ammo[ 1 ] ) then
				for k, v in ipairs( pl.credits.ammo ) do
					if ( credits.isValid( v ) ) then
						pl:GiveAmmo( v.vars.ammoAmount, v.vars.ammoType, true )
					else
						table.remove( pl.credits.ammo, k )
					end
				end
			end
		end
	end
end

hook( "PlayerSpawn", "credits", credits.spawnMethods )

hook( "OnPlayerChangedTeam", "credits", function( pl )
	timer.Simple( 0, function()
		credits.spawnMethods( pl )
	end )
end )

function credits.upgradeWeapon( weapon, transaction )
	weapon.upgradedWeapon = true
	weapon.damageIncreasePercentage = transaction.vars.damageIncreasePercentage

	if ( transaction.vars.material ) then
		weapon:SetMaterial( transaction.vars.material )
	end

	net.Start( "credits.upgradeWeapon" )
		net.WriteEntity( weapon )
		net.WriteTable( {
			cosmeticName = transaction.vars.cosmeticName,
			material = transaction.vars.material,
			bulletTracer = transaction.vars.bulletTracer,
		} )
	net.Broadcast()
end

hook( "WeaponEquip", "credits", function( weapon, pl )
	if ( pl.credits and pl.credits.upgradedWeapons ) then
		local transaction = pl.credits.upgradedWeapons[ weapon:GetClass() ]
		
		if ( transaction ) then
			if ( credits.isValid( transaction ) or ( transaction.vars.used == false ) ) then
				transaction.vars.used = true

				credits.upgradeWeapon( weapon, transaction )
			else
				pl.credits.upgradedWeapon[ weapon:GetClass() ] = nil
			end
		end
	end
end )

hook( "EntityFireBullets", "credits", function( ent, bullet )
	ent = ent:IsWeapon() and ent or ent:IsPlayer() and ent:GetActiveWeapon() or ent

	if ( ent.upgradedWeapon ) then
		if ( ent.damageIncreasePercentage ) then
			bullet.Damage = bullet.Damage + ( bullet.Damage * ( ent.damageIncreasePercentage / 100 ) )

			return true
		end
	end
end )