local UPGRADE = {}
UPGRADE.id = "nerf_this"
UPGRADE.class = "c_dvaredux_nope"
UPGRADE.name = "Nerf This!"
UPGRADE.desc = "Right-click to set off a huge explosion!\nYou are immune, doesn't affect people behind cover"

UPGRADE.convars = {
    {
        name = "pap_nerf_this_radius",
        type = "int"
    },
    {
        name = "pap_nerf_this_damage",
        type = "int"
    },
    {
        name = "pap_nerf_this_owner_immune",
        type = "bool"
    }
}

local radiusCvar = CreateConVar("pap_nerf_this_radius", 700, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Radius of explosion", 1, 3000)

local damageCvar = CreateConVar("pap_nerf_this_damage", 10000, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Explosion damage", 1, 10000)

local ownerImmuneCvar = CreateConVar("pap_nerf_this_owner_immune", 1, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Owner is immune to explosion?", 0, 1)

function UPGRADE:Condition(SWEP)
    return scripted_ents.Get("d.va_mech") ~= nil
end

function UPGRADE:Apply(SWEP)
    if SERVER then
        self:AddToHook(SWEP, "SecondaryAttack", function()
            local owner = SWEP:GetOwner()
            if not IsValid(owner) or SWEP.TTTPAPSpawnedDvaMech then return end
            SWEP.TTTPAPSpawnedDvaMech = true
            local ownerShootPos = owner:GetShootPos()
            -- Place mech in same direction as player is facing
            local angles = owner:GetAngles()
            angles.z = 0
            local mech = ents.Create("d.va_mech")
            mech:SetAngles(angles)
            mech:SetPos(owner:GetPos())
            mech:Spawn()
            mech.PAPNerfThisStopDamage = true
            -- Broadcast the charge up sound here because we need to check if the gun has a valid owner or not before playing it
            BroadcastLua("surface.PlaySound(\"ttt_pack_a_punch/nerf_this/nerf_this.mp3\")")

            -- Start nerf this explosion after a delay, after the callout sound has finished playing
            timer.Simple(2, function()
                if not IsValid(mech) or not IsValid(owner) then return end
                mech:SetNWFloat("UltiCharge", 1000)
                mech.Activator = owner
                mech:Self_Destruct()
                BroadcastLua("surface.PlaySound(\"skill/ultimate2.mp3\")")

                -- Triggering the explosion a split-second before the mech does it itself, so we can re-block the damage later
                timer.Simple(3.4, function()
                    if not IsValid(mech) or not IsValid(owner) then return end
                    mech.PAPNerfThisStopDamage = false
                    local dmg = DamageInfo()
                    dmg:SetDamageType(DMG_BLAST)
                    dmg:SetDamage(damageCvar:GetInt())
                    dmg:SetAttacker(owner)
                    dmg:SetInflictor(mech)
                    -- Now, search for all players that are not behind cover, and damage them!
                    local Trace = {}
                    Trace.start = ownerShootPos
                    Trace.mask = MASK_PLAYERSOLID

                    for _, ent in ipairs(ents.FindInSphere(ownerShootPos, radiusCvar:GetInt())) do
                        -- Skip damaging the owner (if enabled), and the mech itself
                        if not IsValid(ent) or (ent == owner and ownerImmuneCvar:GetInt()) or ent == mech then continue end
                        -- Skip damaging dead players
                        if ent:IsPlayer() and not self:IsAlive(ent) then continue end

                        Trace.filter = {mech, owner, ent}

                        Trace.endpos = ent:GetPos()

                        -- Compare shoot position for players to take crouching, etc. into account
                        if ent:IsPlayer() then
                            Trace.endpos = ent:GetShootPos()
                        end

                        local TraceResult = util.TraceLine(Trace)

                        -- Only if the trace returns nothing blocking the space between the mech owner's shoot position and the victim, does the damage get applied
                        if not TraceResult.Hit then
                            ent:TakeDamageInfo(dmg)
                        end
                    end

                    mech.PAPNerfThisStopDamage = true
                end)
            end)
        end)
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        local inflictor = dmg:GetInflictor()
        -- Stop the mech's overpowered explosion and replace with our own
        -- Also stop the mech from taking damage
        if (IsValid(inflictor) and inflictor.PAPNerfThisStopDamage) or ent.PAPNerfThisStopDamage then return true end
    end)
end

TTTPAP:Register(UPGRADE)