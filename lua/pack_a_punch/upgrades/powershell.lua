local UPGRADE = {}
UPGRADE.id = "powershell"
UPGRADE.class = "ttt_cmdpmpt"
UPGRADE.name = "Powershell"
UPGRADE.desc = "All effects are upgraded!"

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()

    if self:IsPlayer(owner) then
        owner.TTTPAPPowershell = true
    end

    -- Can you believe it??? A custom weapon with an actual hook to modify its effects???
    -- Called whenever a command prompt upgrade is given to a player
    -- 2 passed arguments: a player, and an "effect", string, a description of the effect
    self:AddHook("TTTCMDPROMT", function(ply, effect)
        if not ply.TTTPAPPowershell then return end
        local upgradeMessage = ""

        if effect == "position swap on damage" then
            upgradeMessage = "50 Extra health!"
            ply:SetHealth(ply:Health() + 50)
            ply:SetMaxHealth(ply:GetMaxHealth() + 50)
        elseif effect == "speed buff" then
            upgradeMessage = "bigger speed boost!"
            ply:SetLaggedMovementValue(ply:GetLaggedMovementValue() * 1.2)
        elseif effect == "equipment stealer" then
            upgradeMessage = "extra pack-a-punch upgrade!"

            if TTTPAP:CanOrderPAP(ply) then
                TTTPAP:OrderPAP(ply)
            end
        elseif effect == "traitor spammer" then
            upgradeMessage = "free traitor tester!"
            ply:Give("weapon_ttt_wtester")
            local dnaScanner = ply:GetWeapon("weapon_ttt_wtester")

            if IsValid(dnaScanner) then
                ply:SetActiveWeapon(dnaScanner)
            else
                upgradeMessage = "extra pack-a-punch upgrade!"
            end

            if TTTPAP:CanOrderPAP(ply) then
                TTTPAP:OrderPAP(ply)
            end
        elseif effect == "aim assist" then
            upgradeMessage = "50 Extra health!"
            ply:SetHealth(ply:Health() + 50)
            ply:SetMaxHealth(ply:GetMaxHealth() + 50)
        elseif effect == "forcefield" then
            upgradeMessage = "30% extra global damage reduction!"
            ply.TTTPAPPowershellForcefield = true
        end

        ply:ChatPrint("Plus: " .. upgradeMessage)
    end)

    self:AddHook("EntityTakeDamage", function(ply, dmg)
        if self:IsPlayer(ply) and ply.TTTPAPPowershellForcefield then
            dmg:ScaleDamage(0.7)
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.TTTPAPPowershell = nil
        ply.TTTPAPPowershellForcefield = nil
    end
end

TTTPAP:Register(UPGRADE)