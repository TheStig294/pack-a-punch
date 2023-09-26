local UPGRADE = {}
UPGRADE.id = "shouting_credit_printer"
UPGRADE.class = "weapon_ttt_printer"
UPGRADE.name = "Shouting Credit Printer"
UPGRADE.desc = "Prints credits faster, but makes more sound"

UPGRADE.convars = {
    {
        name = "pap_shouting_credit_printer_length_mult",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_shouting_credit_printer_max_credits",
        type = "int"
    },
    {
        name = "pap_shouting_credit_printer_sounds",
        type = "bool"
    }
}

function UPGRADE:Apply(SWEP)
    function SWEP:PrinterDrop()
        if SERVER then
            local ply = self:GetOwner()
            if not IsValid(ply) then return end
            local vsrc = ply:GetShootPos()
            local vang = ply:GetAimVector()
            local vvel = ply:GetVelocity()
            local vthrow = vvel + vang * 200
            local printer = ents.Create("ttt_pap_shouting_credit_printer")

            if IsValid(printer) then
                printer:SetPos(vsrc + vang * 10)
                printer:Spawn()
                printer:PhysWake()
                local phys = printer:GetPhysicsObject()

                if IsValid(phys) then
                    phys:SetVelocity(vthrow)
                end

                self:Remove()
            end
        end

        self:EmitSound("Weapon_SLAM.SatchelThrow")
    end
end

TTTPAP:Register(UPGRADE)