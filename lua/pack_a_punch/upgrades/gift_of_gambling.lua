local UPGRADE = {}
UPGRADE.id = "gift_of_gambling"
UPGRADE.class = "weapon_ttt_gift"
UPGRADE.name = "Gift of Gambling"

UPGRADE.convars = {
    {
        name = "pap_gift_of_gambling_hp",
        type = "int"
    }
}

local hpConvar = CreateConVar("pap_gift_of_gambling_hp", 50, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "HP to give on success", 1, 100)

UPGRADE.desc = "Now fully heals and grants " .. hpConvar:GetInt() .. " max HP!\nBut still has a chance to explode..."

function UPGRADE:Apply(SWEP)
    function SWEP:CreateGift()
        if SERVER then
            local owner = self:GetOwner()
            if not IsValid(owner) then return end
            local gift = ents.Create("ttt_luckypresent")

            if IsValid(gift) and IsValid(owner) then
                spos = owner:GetShootPos()
                velo = owner:GetVelocity()
                aim = owner:GetAimVector()
                throw = velo + aim * 100
                gift:SetPos(spos + aim * 10)
                gift:Spawn()
                gift:PhysWake()
                phys = gift:GetPhysicsObject()

                if IsValid(phys) then
                    phys:SetVelocity(throw)
                end

                gift:SetPAPCamo()
                gift:SetUseType(SIMPLE_USE)
                gift.Uses = 2

                -- Just override the Use() hook with a completely different function because it's implemented terribly...
                function gift:Use(activator)
                    if not IsValid(activator) then return end

                    if math.random() < 0.75 then
                        self:EmitSound("buttons/button9.wav", 75, 150)
                        local currentHealth = activator:Health()
                        local maxHealth = activator:GetMaxHealth()

                        if currentHealth >= maxHealth then
                            activator:SetHealth(currentHealth + hpConvar:GetInt())
                        else
                            activator:SetHealth(maxHealth + hpConvar:GetInt())
                        end
                    else
                        util.BlastDamage(self, self, self:GetPos(), 150, 200)
                        local effect = EffectData()
                        effect:SetOrigin(self:GetPos() + Vector(0, 0, 10))
                        effect:SetStart(self:GetPos() + Vector(0, 0, 10))
                        util.Effect("Explosion", effect, true, true)
                        self:Remove()
                    end

                    self.Uses = self.Uses - 1

                    if self.Uses <= 0 then
                        self:Remove()
                    end
                end
            end

            self:Remove()
        end
    end
end

TTTPAP:Register(UPGRADE)