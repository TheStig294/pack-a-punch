local UPGRADE = {}
UPGRADE.id = "bomb_silencer"
UPGRADE.class = "weapon_ttt_defuser"
UPGRADE.name = "Bomb Silencer"
UPGRADE.desc = "Single-use, disarms all C4s on the map!"

function UPGRADE:Apply(SWEP)
    local defuse = Sound("c4.disarmfinish")

    function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        local spos = self:GetOwner():GetShootPos()
        local sdest = spos + self:GetOwner():GetAimVector() * 80

        local tr = util.TraceLine({
            start = spos,
            endpos = sdest,
            filter = self:GetOwner(),
            mask = MASK_SHOT
        })

        if IsValid(tr.Entity) and tr.Entity.Defusable then
            local bomb = tr.Entity

            if bomb.Defusable == true or bomb:Defusable() then
                if SERVER and bomb.Disarm then
                    bomb:Disarm(self:GetOwner())
                    sound.Play(defuse, bomb:GetPos())
                end

                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay * 2)
            end
        end

        local c4Count = 0

        for _, ent in ipairs(ents.FindByClass("ttt_c4")) do
            local bomb = ent

            if bomb.Defusable == true or bomb:Defusable() then
                if SERVER and bomb.Disarm then
                    bomb:Disarm(self:GetOwner())
                    sound.Play(defuse, bomb:GetPos())
                    c4Count = c4Count + 1
                end

                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay * 2)
            end
        end

        if SERVER then
            self:GetOwner():ChatPrint("Defused " .. c4Count .. " active bomb(s) on the map")
            self:Remove()
        end
    end
end

TTTPAP:Register(UPGRADE)