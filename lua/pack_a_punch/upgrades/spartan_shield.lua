local UPGRADE = {}
UPGRADE.id = "spartan_shield"
UPGRADE.class = "weapon_slazer_new"
UPGRADE.name = "Spartan Shield"
UPGRADE.desc = "Gives you a regenerating shield,\nwhich protects from 1-shot deaths!"

UPGRADE.convars = {
    {
        name = "pap_spartan_shield_amount",
        type = "int"
    },
    {
        name = "pap_spartan_shield_cooldown",
        type = "int"
    }
}

local shieldCvar = CreateConVar("pap_spartan_shield_amount", 20, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "No. of shield points", 1, 100)

local cooldownCvar = CreateConVar("pap_spartan_shield_cooldown", 5, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds before shield recharges", 1, 30)

local function ResetShield(ply)
    ply:SetNWInt("PAPHealthShield", 0)
    ply.PAPSpartanShield = false

    if SERVER and ply.PAPOldPlayermodel then
        UPGRADE:SetModel(ply, ply.PAPOldPlayermodel)
    end
end

function UPGRADE:Apply(SWEP)
    local maxShield = shieldCvar:GetInt()

    -- Here's the difference between this and the other shield upgrades, it regenerates!
    local function RegenerateShield(ply)
        ply:EmitSound("ttt_pack_a_punch/spartan_shield/shield.mp3")
        local chargeRate = math.ceil(1 * (maxShield / 100))
        local shieldPoints = math.min(ply:GetNWInt("PAPHealthShield", 0) + chargeRate, maxShield)
        ply:SetNWInt("PAPHealthShield", shieldPoints)
        local timerName = "TTTPAPSpartanShieldRegenBegin" .. ply:SteamID64()

        timer.Create(timerName, 0.08, 0, function()
            if not IsValid(ply) or shieldPoints == maxShield or not ply.PAPSpartanShield then
                timer.Remove(timerName)

                if not ply.PAPSpartanShield then
                    ResetShield(ply)
                end

                return
            end

            shieldPoints = math.min(ply:GetNWInt("PAPHealthShield", 0) + chargeRate, maxShield)
            ply:SetNWInt("PAPHealthShield", shieldPoints)
        end)
    end

    -- If this weapon was picked up off the ground, apply the shield to the player!
    function SWEP:InitialiseShield()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        if SERVER then
            owner.PAPOldPlayermodel = owner:GetModel()

            -- Set their model to master chief if installed: https://steamcommunity.com/sharedfiles/filedetails/?id=125456150
            if util.IsValidModel("models/player/MasterChiefH3.mdl") then
                UPGRADE:SetModel(owner, "models/player/MasterChiefH3.mdl")
            end
        end

        owner.PAPSpartanShield = true
        RegenerateShield(owner)
    end

    SWEP:InitialiseShield()

    function SWEP:OwnerChanged()
        -- Only 1 player can have the shield at a time, dropping the weapon removes the shield
        for _, ply in player.Iterator() do
            if ply.PAPSpartanShield then
                ResetShield(ply)
            end
        end

        self:InitialiseShield()
    end

    -- Drawing the shield bar
    if CLIENT then
        self:AddHook("DrawOverlay", function()
            local ply = LocalPlayer()
            local shield = ply:GetNWInt("PAPHealthShield", 0)
            if shield <= 0 then return end
            local text = string.format("%i", shield, maxShield) .. " Shield"
            local x = 19
            local y = ScrH() - 95

            -- Don't show shield bar if player is dead or has the pause menu open
            if ply:Alive() and not ply:IsSpec() and not gui.IsGameUIVisible() then
                local texttable = {}
                texttable.font = "HealthAmmo"
                texttable.color = COLOR_WHITE

                texttable.pos = {135, y + 25}

                texttable.text = text
                texttable.xalign = TEXT_ALIGN_LEFT
                texttable.yalign = TEXT_ALIGN_BOTTOM
                draw.RoundedBox(5, x, y, 233, 28, Color(43, 65, 65))
                draw.RoundedBox(5, x, y, (shield / maxShield) * 233, 28, Color(67, 216, 216))
                draw.TextShadow(texttable, 2)
            end
        end)
    end

    -- Adding hard-coded fix for loosing shield while having PHD flopper, don't know how to do a proper generic fix for cases like that...
    local function ShouldBeImmune(ply, dmg)
        return ply:GetNWBool("PHDActive") and (dmg:IsFallDamage() or dmg:IsExplosionDamage())
    end

    -- Handling damage
    self:AddHook("EntityTakeDamage", function(ply, dmg)
        if not self:IsPlayer(ply) then return end
        local shield = ply:GetNWInt("PAPHealthShield", 0)

        if shield > 0 and not ShouldBeImmune(ply, dmg) then
            -- Block the damage, and take away shield points
            local newShield = math.floor(shield - dmg:GetDamage())

            if newShield < 0 then
                newShield = 0
            end

            dmg:ScaleDamage(0)
            ply:SetNWInt("PAPHealthShield", newShield)
            ply:EmitSound("ttt_pack_a_punch/chug_jug_tool/block.mp3")
            -- Playing sounds for the attacker and shielded player
            local attacker = dmg:GetAttacker()

            if self:IsPlayer(attacker) then
                attacker:SendLua("surface.PlaySound(\"ttt_pack_a_punch/chug_jug_tool/block.mp3\")")
            end

            if newShield == 0 then
                ply:EmitSound("ttt_pack_a_punch/chug_jug_tool/break.mp3")

                if self:IsPlayer(attacker) then
                    attacker:SendLua("surface.PlaySound(\"ttt_pack_a_punch/chug_jug_tool/break.mp3\")")
                end
            end
        end

        -- The shield regen timer is reset each time the player takes damage, via this timer being re-created
        if ply.PAPSpartanShield then
            -- Stop their currently regenerating shield from regenerating
            timer.Remove("TTTPAPSpartanShieldRegenBegin" .. ply:SteamID64())

            timer.Create("TTTPAPSpartanShieldRegen" .. ply:SteamID64(), cooldownCvar:GetInt(), 1, function()
                if IsValid(ply) and ply.PAPSpartanShield then
                    RegenerateShield(ply)
                end
            end)
        end
    end)

    self:AddHook("PlayerSpawn", function(ply)
        ResetShield(ply)
    end)

    self:AddHook("PostPlayerDeath", function(ply)
        ResetShield(ply)
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ResetShield(ply)
    end
end

TTTPAP:Register(UPGRADE)