local UPGRADE = {}
UPGRADE.id = "blinking_angel"
UPGRADE.class = "ttt_weeping_angel"
UPGRADE.name = "Blinking Angel"
UPGRADE.desc = "Makes victims blink..."
UPGRADE.Timers = {}

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        p = owner
        if self:Clip1() <= 0 then return end
        local Bullet = {}
        self:SendWeaponAnim(self.PrimaryAnim)
        owner:MuzzleFlash()
        owner:SetAnimation(PLAYER_ATTACK1)
        Bullet.Dmgtype = "DMG_GENERIC"
        Bullet.Num = num
        Bullet.Spread = Vector(cone, cone, 0)
        Bullet.Tracer = 0
        Bullet.Force = 0
        Bullet.Damage = 3
        Bullet.Src = p:GetShootPos()
        Bullet.Dir = p:GetAimVector()
        Bullet.TracerName = "TRACER_NONE"

        Bullet.Callback = function(atk, tr, dmg)
            local tgt = tr.Entity

            if SERVER and tgt:IsPlayer() and tgt:Alive() then
                sound.Play("vo/npc/male01/behindyou01.wav", tgt:GetPos(), 100, 50, 1)
                tgt:PrintMessage(HUD_PRINTTALK, "Don't. Blink.")
                local ent = ents.Create("weepingangel")
                ent:SetPos(tgt:GetAimVector())
                ent:Spawn()
                ent:Activate()
                ent:SetVictim(tgt)
                ent:DropToFloor()
                ent:SetMaterial(TTTPAP.camo)
                local timername = "TTTPAPBlinkingAngel" .. owner:SteamID64()

                timer.Create(timername, 20, 0, function()
                    if GetRoundState() ~= ROUND_ACTIVE or not IsValid(ent) or not IsValid(tgt) then
                        timer.Remove(timername)

                        return
                    end

                    tgt:ScreenFade(SCREENFADE.STAYOUT, COLOR_BLACK, 0, 1)

                    timer.Simple(0.1, function()
                        tgt:ScreenFade(SCREENFADE.PURGE, COLOR_BLACK, 0, 1)
                    end)

                    local aimVector = tgt:GetAimVector()
                    aimVector.z = 0
                    aimVector = aimVector:GetNormalized() * 100
                    ent:SetPos(tgt:GetPos() + aimVector)
                    local angelAngles = owner:GetAimVector()
                    angelAngles.x = -angelAngles.x
                    angelAngles.y = -angelAngles.y
                    angelAngles.z = 0
                    ent:SetAngles(angelAngles:Angle())
                end)

                return ent
            end
        end

        self:TakePrimaryAmmo(1)
        p:FireBullets(Bullet)
    end
end

function UPGRADE:Reset()
    for _, timername in ipairs(self.Timers) do
        timer.Remove(timername)
    end
end

TTTPAP:Register(UPGRADE)