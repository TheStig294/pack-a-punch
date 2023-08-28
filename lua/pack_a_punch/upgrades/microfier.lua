local UPGRADE = {}
UPGRADE.id = "microfier"
UPGRADE.class = "weapon_ttt_minifier"
UPGRADE.name = "Microfier"
UPGRADE.desc = "Makes you absolutely tiny!"

UPGRADE.convars = {
    {
        name = "ttt_pap_minifier_scale",
        type = "int"
    }
}

local scaleCvar = CreateConVar("ttt_pap_minifier_scale", "0.3", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Minifier scale", 0.1, 1)

function UPGRADE:Apply(SWEP)
    if SERVER and file.Exists("lua/autorun/healthregen.lua", "GAME") then
        hook.Add("Think", "HealthRegen.Think", function()
            local enabled = GetConVar("healthregen_enabled"):GetFloat() > 0
            local speed = 1 / GetConVar("healthregen_speed"):GetFloat()
            local max = GetConVar("healthregen_maxhealth"):GetFloat()
            local time = FrameTime()

            for _, ply in pairs(player.GetAll()) do
                if ply:Alive() then
                    local health = ply:Health()

                    if health < (ply.LastHealth or 0) then
                        ply.HealthRegenNext = CurTime() + GetConVar("healthregen_delay"):GetFloat()
                    end

                    if CurTime() > (ply.HealthRegenNext or 0) and enabled then
                        ply.HealthRegen = (ply.HealthRegen or 0) + time

                        if ply.HealthRegen >= speed then
                            local add = math.floor(ply.HealthRegen / speed)
                            ply.HealthRegen = ply.HealthRegen - add * speed

                            if health < max and health < ply:GetMaxHealth() or speed < 0 then
                                ply:SetHealth(math.min(health + add, max))
                            end
                        end
                    end

                    ply.LastHealth = ply:Health()
                end
            end
        end)
    end

    SWEP.ShrinkScale = 0.3

    function SWEP:Minify()
        if CLIENT then return end
        local owner = self:GetOwner()

        if IsPlayer(owner) then
            if not owner.OGMinifierHeight then
                owner.OGMinifierHeight = {owner:GetViewOffset().z, owner:GetViewOffsetDucked().z}
            end

            owner:SendLua("surface.PlaySound(\"ttt_pack_a_punch/minifier/shrink.ogg\")")
            owner:SetModelScale(scaleCvar:GetFloat(), 1)
            owner:SetGravity(1 + scaleCvar:GetFloat())
            self.minified = true
            -- Decrease height players can automatically step up (i.e. players can't climb stairs)
            owner:SetStepSize(18 * scaleCvar:GetFloat())
            -- Shrink player hitbox
            owner:SetHull(Vector(-16, -16, 0) * scaleCvar:GetFloat(), Vector(16, 16, 72) * scaleCvar:GetFloat())
            owner:SetHullDuck(Vector(-16, -16, 0) * scaleCvar:GetFloat(), Vector(16, 16, 36) * scaleCvar:GetFloat())

            if SERVER then
                owner.oldMaxHealth = owner:GetMaxHealth()
                owner:SetHealth(owner:Health() * scaleCvar:GetFloat() / 100)
                owner:SetMaxHealth(owner:Health())
            end

            local ID = "TTTMinifierShrink" .. owner:SteamID64()

            timer.Create(ID, 0.01, 100, function()
                local counter = 100 - timer.RepsLeft(ID)

                if counter < 100 - scaleCvar:GetFloat() * 100 then
                    owner:SetViewOffset(Vector(0, 0, owner.OGMinifierHeight[1] - counter * owner.OGMinifierHeight[1] / 100))
                    owner:SetViewOffsetDucked(Vector(0, 0, owner.OGMinifierHeight[2] - counter * owner.OGMinifierHeight[2] / 100))
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
                owner:SetHealth(owner:Health() * 100 / GetConVar("ttt_pap_minifier_scale"):GetInt())
                owner:SetMaxHealth(owner.oldMaxHealth or 100)
            end

            local ID = "TTTMinifierUnshrink" .. owner:SteamID64()

            timer.Create(ID, 0.01, 100, function()
                local counter = 100 - timer.RepsLeft(ID)

                if counter < 100 - scaleCvar:GetFloat() * 100 then
                    owner:SetViewOffset(Vector(0, 0, targetViewHeight / (1 / scaleCvar:GetFloat()) + counter * targetViewHeight / 100))
                    owner:SetViewOffsetDucked(Vector(0, 0, targetViewHeightDucked / (1 / scaleCvar:GetFloat()) + counter * targetViewHeightDucked / 100))
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

    -- Creation of the reset hook so it overrides the minifier's usual one as it may cause issues with viewheight
    hook.Add("TTTPrepareRound", "UnMinifyAll", function()
        if CLIENT then return end

        for k, v in pairs(player.GetAll()) do
            v.minified = false
            v.OGMinifierHeight = nil
        end
    end)
end

TTTPAP:Register(UPGRADE)