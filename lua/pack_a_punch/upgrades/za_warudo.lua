local UPGRADE = {}
UPGRADE.id = "za_warudo"
UPGRADE.class = "crimson_new"
UPGRADE.name = "ZA WARUDO"
UPGRADE.desc = "Press 'R' to time skip!"

function UPGRADE:Apply(SWEP)
    local secsFreeze = 10

    function SWEP:Reload()
        if SERVER and self:Clip1() > 0 then
            self.Delay = self.Delay or CurTime()

            if CurTime() >= self.Delay then
                self:SetAMode(not self:GetAMode())
                self.Delay = CurTime() + 0.2

                if self:GetAMode() then
                    self:TakePrimaryAmmo(1)
                    self:SetNextSecondaryFire(CurTime() + 10)
                    self:EmitSound("ttt_pack_a_punch/za_warudo/za_warudo.mp3", 0)

                    timer.Simple(7.256, function()
                        self:Skip(true)
                        net.Start("crimson_new.SkipStop")
                        net.Broadcast()

                        timer.Simple(secsFreeze / 2, function()
                            self:StopSkip(true)
                        end)
                    end)
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)