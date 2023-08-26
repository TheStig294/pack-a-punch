AddCSLuaFile()

if SERVER and file.Exists("lua/autorun/healthregen.lua", "GAME") then
    hook.Add("Think", "HealthRegen.Think", function()
        local enabled = GetConVar("healthregen_enabled"):GetFloat() > 0
        local speed = 1 / GetConVar("healthregen_speed"):GetFloat()
        local max = GetConVar("healthregen_maxhealth"):GetFloat()
        local time = FrameTime()

        for _, ply in pairs(player.GetAll()) do
            if (ply:Alive()) then
                local health = ply:Health()

                if (health < (ply.LastHealth or 0)) then
                    ply.HealthRegenNext = CurTime() + GetConVar("healthregen_delay"):GetFloat()
                end

                if (CurTime() > (ply.HealthRegenNext or 0) and enabled) then
                    ply.HealthRegen = (ply.HealthRegen or 0) + time

                    if (ply.HealthRegen >= speed) then
                        local add = math.floor(ply.HealthRegen / speed)
                        ply.HealthRegen = ply.HealthRegen - (add * speed)

                        if ((health < max and health < ply:GetMaxHealth()) or speed < 0) then
                            ply:SetHealth(math.min(health + add, max))
                        end
                    end
                end

                ply.LastHealth = ply:Health()
            end
        end
    end)
end

local class = "weapon_ttt_minifier_pap"
TTTPAP.convars[class] = {}

table.insert(TTTPAP.convars[class], {
    name = "ttt_pap_minifier_health",
    type = "int"
})

SWEP.Base = "weapon_ttt_minifier"
SWEP.ShrinkScale = 0.3
SWEP.PAPDesc = "Makes you absolutely tiny!"

if CLIENT then
    SWEP.PrintName = "Microfier"

    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = "Left-click to shrink your size and health!"
    }
end

if SERVER then
    CreateConVar("ttt_pap_minifier_health", SWEP.ShrinkScale * 100, {FCVAR_NOTIFY}, "The max health you are set to when using the minifier", 1, 100)
end

function SWEP:Minify()
    if CLIENT then return end
    local owner = self:GetOwner()

    if IsPlayer(owner) then
        if not owner.OGMinifierHeight then
            owner.OGMinifierHeight = {owner:GetViewOffset().z, owner:GetViewOffsetDucked().z}
        end

        owner:SendLua("surface.PlaySound(\"ttt_pack_a_punch/minifier/shrink.ogg\")")
        owner:SetModelScale(self.ShrinkScale, 1)
        owner:SetGravity(1 + self.ShrinkScale)
        self.minified = true
        -- Decrease height players can automatically step up (i.e. players can't climb stairs)
        owner:SetStepSize(18 * self.ShrinkScale)
        -- Shrink player hitbox
        owner:SetHull(Vector(-16, -16, 0) * self.ShrinkScale, Vector(16, 16, 72) * self.ShrinkScale)
        owner:SetHullDuck(Vector(-16, -16, 0) * self.ShrinkScale, Vector(16, 16, 36) * self.ShrinkScale)

        if SERVER then
            owner.oldMaxHealth = owner:GetMaxHealth()
            owner:SetHealth(owner:Health() * (GetConVar("ttt_pap_minifier_health"):GetInt() / 100))
            owner:SetMaxHealth(owner:Health())
        end

        local ID = "TTTMinifierShrink" .. owner:SteamID64()

        timer.Create(ID, 0.01, 100, function()
            local counter = 100 - timer.RepsLeft(ID)

            if counter < 100 - self.ShrinkScale * 100 then
                owner:SetViewOffset(Vector(0, 0, owner.OGMinifierHeight[1] - (counter * owner.OGMinifierHeight[1] / 100)))
                owner:SetViewOffsetDucked(Vector(0, 0, owner.OGMinifierHeight[2] - (counter * owner.OGMinifierHeight[2] / 100)))
            end
        end)
    end
end

function SWEP:UnMinify()
    if CLIENT then return end
    local owner = self:GetOwner()

    if IsPlayer(owner) then
        local targetViewHeight
        local targetViewHeightDucked

        if IsFirstTimePredicted() and owner.OGMinifierHeight then
            targetViewHeight = owner.OGMinifierHeight[1]
            targetViewHeightDucked = owner.OGMinifierHeight[2]
        end

        owner:SendLua("surface.PlaySound(\"ttt_pack_a_punch/minifier/unshrink.ogg\")")
        owner:SetModelScale(1, 1)
        owner:SetGravity(1)
        self.minified = false
        owner:SetStepSize(18)
        owner:ResetHull()

        if SERVER then
            owner:SetHealth(owner:Health() * (100 / GetConVar("ttt_pap_minifier_health"):GetInt()))
            owner:SetMaxHealth(owner.oldMaxHealth or 100)
        end

        local ID = "TTTMinifierUnshrink" .. owner:SteamID64()

        timer.Create(ID, 0.01, 100, function()
            local counter = 100 - timer.RepsLeft(ID)

            if counter < 100 - self.ShrinkScale * 100 then
                owner:SetViewOffset(Vector(0, 0, targetViewHeight / (1 / self.ShrinkScale) + (counter * targetViewHeight / 100)))
                owner:SetViewOffsetDucked(Vector(0, 0, targetViewHeightDucked / (1 / self.ShrinkScale) + (counter * targetViewHeightDucked / 100)))
            end
        end)
    end
end

function SWEP:Deploy()
    if not IsFirstTimePredicted() then return end
    local owner = self:GetOwner()

    hook.Add("PlayerButtonDown", "MinifierActivateFix" .. owner:SteamID64(), function(ply, button)
        timer.Simple(0.1, function()
            if IsPlayer(owner) and owner == ply and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon() == self and button == MOUSE_LEFT then
                self:PrimaryAttack()
                hook.Remove("PlayerButtonDown", "MinifierActivateFix" .. ply:SteamID64())
            end
        end)
    end)

    timer.Simple(3, function()
        if IsPlayer(owner) then
            hook.Remove("PlayerButtonDown", "MinifierActivateFix" .. owner:SteamID64())
        end
    end)

    return true
end

-- Delay the creation of the reset hook so it overrides the minifier's usual one as it may cause issues with viewheight
hook.Add("InitPostEntity", "MinifierResetHookOverride", function()
    hook.Add("TTTPrepareRound", "UnMinifyAll", function()
        if CLIENT then return end

        for k, v in pairs(player.GetAll()) do
            v.minified = false
            v.OGMinifierHeight = nil
        end
    end)
end)