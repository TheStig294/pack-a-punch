local UPGRADE = {}
UPGRADE.id = "free_graffiti_can"
UPGRADE.class = "weapon_spraymhs"
UPGRADE.name = "Graffiti"
UPGRADE.desc = "Forcibly gives everyone a graffiti can!"
UPGRADE.noCamo = true

function UPGRADE:Apply(SWEP)
    if SERVER then
        local owner = SWEP:GetOwner()

        for _, ply in ipairs(self:GetAlivePlayers()) do
            if owner == ply then continue end
            local replaced = false

            for _, wep in ipairs(ply:GetWeapons()) do
                if wep.Kind == SWEP.Kind then
                    wep:Remove()
                    replaced = true
                    break
                end
            end

            timer.Simple(0.1, function()
                local can = ply:Give(self.class)
                can.PAPUpgrade = self
                ply:SelectWeapon(self.class)
                ply:PrintMessage(HUD_PRINTCENTER, "Someone upgraded a graffiti can!")
                ply:PrintMessage(HUD_PRINTTALK, "Right-click to change colour!")

                if replaced then
                    ply:PrintMessage(HUD_PRINTTALK, "The graffiti can replaced whatever weapon you had in that slot!")
                end
            end)
        end
    end

    timer.Simple(0.1, function()
        for _, ply in ipairs(player.GetAll()) do
            local can = ply:GetWeapon(self.class)

            if IsValid(can) then
                can.PAPUpgrade = self

                if can.VElements then
                    can.VElements.m.material = TTTPAP.camo
                end

                if can.WElements then
                    can.WElements.spr.material = TTTPAP.camo
                end
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)