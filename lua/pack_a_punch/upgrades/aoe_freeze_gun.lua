local UPGRADE = {}
UPGRADE.id = "aoe_freeze_gun"
UPGRADE.class = "weapon_ttt_freezegun"
UPGRADE.name = "AOE Freeze Gun"
UPGRADE.desc = "Freezes nearby players too!"

UPGRADE.convars = {
    {
        name = "pap_aoe_freeze_gun_range",
        type = "int"
    }
}

local rangeCvar = CreateConVar("pap_aoe_freeze_gun_range", 200, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Range of the freeze gun AOE", 10, 1000)

function UPGRADE:Apply(SWEP)
    local freezeDuration = GetConVar("ttt_freezegun_duration")
    local screenColour = Color(0, 238, 255, 20)
    local freezeColour = Color(0, 255, 255)

    local function FreezeTarget(attacker, tr, _)
        local ent = tr.Entity
        if not IsValid(ent) then return end

        if SERVER then
            -- disallow if prep or post round
            if not ent:IsPlayer() or (not GAMEMODE:AllowPVP()) then return end

            for _, ply in player.Iterator() do
                if not self:IsAlive(ply) then continue end
                -- Don't let players freeze themselves!
                if ply == attacker then continue end
                -- If 100 range
                -- 100 * 100 = 10000
                local range = rangeCvar:GetInt() * rangeCvar:GetInt()

                if ply:GetPos():DistToSqr(ent:GetPos()) < range then
                    ply:Freeze(true)
                    ply:EmitSound("ttt_pack_a_punch/aoe_freeze_gun/freeze.mp3")
                    ply:ScreenFade(SCREENFADE.OUT, screenColour, 1, freezeDuration:GetInt() - 1)
                    local oldPlayerColour = ply:GetColor()
                    ply:SetColor(freezeColour)

                    timer.Simple(freezeDuration:GetInt() + 0.1, function()
                        if IsValid(ply) then
                            ply:Freeze(false)
                            ply:SetColor(oldPlayerColour)
                        end
                    end)
                end
            end
        end
    end

    function SWEP:ShootIce()
        local cone = self.Primary.Cone
        local owner = self:GetOwner()
        local bullet = {}
        bullet.Num = 1
        bullet.Src = owner:GetShootPos()
        bullet.Dir = owner:GetAimVector()
        bullet.Spread = Vector(cone, cone, 0)
        bullet.Tracer = 1
        bullet.Force = 2
        bullet.Damage = self.Primary.Damage
        bullet.TracerName = self.Tracer
        bullet.Callback = FreezeTarget
        owner:FireBullets(bullet)
    end
end

TTTPAP:Register(UPGRADE)