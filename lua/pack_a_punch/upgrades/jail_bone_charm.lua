local UPGRADE = {}
UPGRADE.id = "jail_bone_charm"
UPGRADE.class = "weapon_thr_bonecharm"
UPGRADE.name = "Jail Bone Charm"
UPGRADE.desc = "Respawn in jail after you die"

UPGRADE.convars = {
    {
        name = "pap_jail_bone_charm_jail_secs",
        type = "int"
    }
}

local jailSecsCvar = CreateConVar("pap_jail_bone_charm_jail_secs", "20", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "How long a player is in jail in seconds", 0, 180)

function UPGRADE:Apply()
    -- Modified version of the bonk bat jail
    -- Cleaned up code
    -- Modified timings and triggers for the bone charm upgrade
    -- Added a floor and ceiling to the jail
    -- 
    -- Creates a jail wall
    local function JailWall(pos, angle)
        local wall = ents.Create("prop_physics")
        wall:SetModel("models/props_building_details/Storefront_Template001a_Bars.mdl")
        wall:SetPos(pos)
        wall:SetAngles(angle)
        wall:Spawn()
        local physobj = wall:GetPhysicsObject()

        if physobj:IsValid() then
            physobj:EnableMotion(false)
            physobj:Sleep(false)
        end

        return wall
    end

    -- Respawn and trap the player in jail after they first die
    self:AddHook("DoPlayerDeath", function(ply)
        local boneCharm = ply:GetWeapon(self.class)
        -- Only affect players with a bone charm that is PAPed
        -- They will naturally only be able to respawn once,
        -- because once they do their bone charm won't be upgraded anymore
        if not IsValid(boneCharm) or not boneCharm.PAPUpgrade then return end
        local credits = ply:GetCredits()
        local items = ply:GetEquipmentItems()
        local weps = ply:GetWeapons()

        for i, wep in ipairs(weps) do
            weps[i] = wep:GetClass()
        end

        local ammo = ply:GetAmmo()

        timer.Simple(1, function()
            -- Don't trap the player if they die as the round restarts
            if GetRoundState() == ROUND_PREP then return end
            ply:PrintMessage(HUD_PRINTTALK, "Your bone charm saved you!\nBut you're stuck in jail for " .. jailSecsCvar:GetInt() .. " seconds!")
            ply:SpawnForRound(true)
            -- Credits
            ply:SetCredits(credits)
            -- Equipment
            ply.equipment_items = items
            ply:SendEquipment()

            -- Weapons
            for _, wep in ipairs(weps) do
                ply:Give(wep)
            end

            -- Ammo
            for ammoID, ammoCount in pairs(ammo) do
                ply:GiveAmmo(ammoCount, ammoID, true)
            end

            local jail = {}
            -- far side
            jail[0] = JailWall(ply:GetPos() + Vector(0, -25, 50), Angle(0, 275, 0))
            -- close side
            jail[1] = JailWall(ply:GetPos() + Vector(0, 25, 50), Angle(0, 275, 0))
            -- left side
            jail[2] = JailWall(ply:GetPos() + Vector(-25, 0, 50), Angle(0, 180, 0))
            -- right side
            jail[3] = JailWall(ply:GetPos() + Vector(25, 0, 50), Angle(0, 180, 0))
            -- ceiling side
            jail[4] = JailWall(ply:GetPos() + Vector(0, 0, 100), Angle(90, 0, 0))
            -- floor side
            jail[5] = JailWall(ply:GetPos() + Vector(0, 0, -25), Angle(90, 0, 0))
            -- Display a countdown to freeing the player
            local timerName = "TTTPAPJailBoneCharm" .. ply:SteamID64()

            timer.Create(timerName, 1, jailSecsCvar:GetInt(), function()
                -- If player disconnects, remove the jail and timer
                if not IsValid(ply) then
                    for _, wall in pairs(jail) do
                        if IsValid(wall) then
                            wall:Remove()
                        end
                    end

                    timer.Remove(timerName)

                    return
                end

                ply:PrintMessage(HUD_PRINTCENTER, "Seconds left in jail: " .. timer.RepsLeft(timerName))

                -- Remove the jail walls once time is up
                if timer.RepsLeft(timerName) <= 0 then
                    for _, wall in pairs(jail) do
                        if IsValid(wall) then
                            wall:Remove()
                        end
                    end
                end
            end)
        end)
    end)
end

TTTPAP:Register(UPGRADE)