local UPGRADE = {}
UPGRADE.id = "nerf_this"
UPGRADE.class = "c_dvaredux_nope"
UPGRADE.name = "Nerf This!"
UPGRADE.desc = "Sets off a big explosion, you are immune!\nDoesn't affect people behind cover"

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

local radiusCvar = CreateConVar("pap_nerf_this_radius", 700, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Radius of explosion", 1, 3000)

local damageCvar = CreateConVar("pap_nerf_this_damage", 10000, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Explosion damage", 1, 10000)

local ownerImmuneCvar = CreateConVar("pap_nerf_this_owner_immune", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Owner is immune to explosion?", 0, 1)

function UPGRADE:Apply(SWEP)
    -- Something I keep forgetting... This function is already networked to all players...
    -- So for things that happen on-upgrade there is no need to create a new network string, everyone will run this code on the client
    if CLIENT then
        surface.PlaySound("ttt_pack_a_punch/nerf_this/nerf_this.mp3")

        timer.Simple(2, function()
            surface.PlaySound("skill/ultimate2.mp3")
        end)
    end

    if SERVER then
        local own = SWEP:GetOwner()
        local ownerShootPos = own:GetShootPos()
        -- Place mech in same direction as player is facing
        local angles = own:GetAngles()
        angles.z = 0
        local mech = ents.Create("d.va_mech")
        mech:SetAngles(angles)
        mech:SetPos(own:GetPos())
        mech:Spawn()
        mech.PAPNerfThisStopDamage = true

        -- Start nerf this explosion after a delay, after the callout sound has finished playing
        timer.Simple(2, function()
            if not IsValid(mech) or not IsValid(own) then return end
            mech:SetNWFloat("UltiCharge", 1000)
            mech.Activator = own
            mech:Self_Destruct()

            -- Triggering the explosion a split-second before the mech does it itself, so we can re-block the damage later
            timer.Simple(3.4, function()
                if not IsValid(mech) or not IsValid(own) then return end
                mech.PAPNerfThisStopDamage = false
                local dmg = DamageInfo()
                dmg:SetDamageType(DMG_BLAST)
                dmg:SetDamage(damageCvar:GetInt())
                dmg:SetAttacker(own)
                dmg:SetInflictor(mech)
                -- Now, search for all players that are not behind cover, and damage them!
                local Trace = {}
                Trace.start = ownerShootPos
                Trace.mask = MASK_PLAYERSOLID

                for _, ent in ipairs(ents.FindInSphere(ownerShootPos, radiusCvar:GetInt())) do
                    -- Skip damaging the owner (if enabled), and the mech itself
                    if not IsValid(ent) or (ent == own and ownerImmuneCvar:GetInt()) or ent == mech then continue end
                    -- Skip damaging dead players
                    if ent:IsPlayer() and not self:IsAlive(ent) then continue end

                    Trace.filter = {mech, own, ent}

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
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        local inflictor = dmg:GetInflictor()
        -- Stop the mech's overpowered explosion and replace with our own
        -- Also stop the mech from taking damage
        if (IsValid(inflictor) and inflictor.PAPNerfThisStopDamage) or ent.PAPNerfThisStopDamage then return true end
    end)
end

TTTPAP:Register(UPGRADE)