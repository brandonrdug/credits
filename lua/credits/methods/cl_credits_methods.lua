net.Receive( "credits.updatePropCount", function()
	LocalPlayer().credits.propCount = net.ReadUInt( 10 )
end )

local cache = {}

net.Receive( "credits.upgradeWeapon", function()
	local index = net.ReadUInt( 16 )
	local data = net.ReadTable()
	local ent = Entity( index )

	-- just incase it does exist 🤡
	if ( IsValid( ent ) ) then
		ent.upgradedWeapon = true
		ent.PrintName = data.cosmeticName
		ent.upgradedMaterial = data.material
		ent.bulletTracer = data.bulletTracer
	else
		cache[ index ] = {
			upgradedWeapon = true,
			PrintName = data.cosmeticName,
			upgradedMaterial = data.material,
			bulletTracer = data.bulletTracer
		}
	end
end )

-- when WeaponEquip networks to the client the entity, it sometimes doesn't exist soon enough on the client, so this is a workaround
hook( "OnEntityCreated", "credits", function( ent ) 
	-- entity data doesn't initialize this early either (like PrintName) so we have to wait till next tick
	timer.Simple( 0, function()
		if ( cache[ ent:EntIndex() ] ) then
			table.Merge( ent:GetTable(), cache[ ent:EntIndex() ] )
			cache[ ent:EntIndex() ] = nil
		end
	end )
end )

-- literal easiest way to do this
local viewMaterial

hook( "Think", "credits", function()
	if ( IsValid( LocalPlayer() ) ) then
		local weapon = LocalPlayer():GetActiveWeapon()

		if ( IsValid( weapon ) ) then
			if ( weapon.upgradedWeapon and weapon.upgradedMaterial ) then
				LocalPlayer():GetViewModel():SetMaterial( weapon.upgradedMaterial )
				viewMaterial = true
			elseif ( viewMaterial ) then
				LocalPlayer():GetViewModel():SetMaterial( "" )
				viewMaterial = nil
			end
		end
	end
end )

hook( "EntityFireBullets", "credits", function( ent, bullet )
	-- m9k shoots bullets from the player sometimes I guess?
	ent = ent:IsWeapon() and ent or ent:IsPlayer() and ent:GetActiveWeapon() or ent

	if ( ent.upgradedWeapon ) then
		if ( ent.bulletTracer ) then
			bullet.Tracer = 1
			bullet.TracerName = ent.bulletTracer

			return true
		end
	end
end )