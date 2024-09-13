local UPGRADE = {}
UPGRADE.id = "rock_guitar"
UPGRADE.class = "weapon_ttt_lightningar1"
UPGRADE.name = "Rock Guitar"
UPGRADE.desc = "Infinite ammo, time to rock!"

function UPGRADE:Apply(SWEP)
    if CLIENT then return end
    local own = SWEP:GetOwner()

    if IsValid(own) then
        own:EmitSound("ttt_pack_a_punch/rock_guitar/equip.mp3")

        timer.Simple(1, function()
            if IsValid(own) then
                -- Spawn some smoke on upgrading around the player and explosion effects
                local pos = own:GetPos()
                local gren = ents.Create("ttt_smokegrenade_proj")
                if not IsValid(gren) then return end
                gren:SetPos(pos)
                gren:SetAngles(Angle(0, 0, 0))
                gren:SetOwner(own)
                gren:SetThrower(own)
                gren:SetGravity(0.4)
                gren:SetFriction(0.2)
                gren:SetElasticity(0.45)
                gren:Spawn()
                gren:PhysWake()
                gren:SetDetonateExact(CurTime() + 0.01)
                local explosionEffect = EffectData()
                explosionEffect:SetStart(pos)
                explosionEffect:SetOrigin(pos)
                explosionEffect:SetScale(1)
                util.Effect("Explosion", explosionEffect)

                if IsValid(SWEP) then
                    SWEP.TTTPAPBeginIdle = true
                end
            end
        end)
    end

    SWEP.TTTPAPGuitarIsAttacking = false

    function SWEP:Think()
        if not self.TTTPAPBeginIdle then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        -- Infinite ammo
        self:SetClip1(self.Primary.ClipSize)

        if owner:KeyDown(IN_ATTACK) and not self.TTTPAPGuitarIsAttacking then
            self.TTTPAPGuitarIsAttacking = true
            owner:EmitSound("ttt_pack_a_punch/rock_guitar/shoot.mp3")
            owner:StopSound("ttt_pack_a_punch/rock_guitar/idle.mp3")
        elseif not owner:KeyDown(IN_ATTACK) and self.TTTPAPGuitarIsAttacking then
            self.TTTPAPGuitarIsAttacking = false
            owner:StopSound("ttt_pack_a_punch/rock_guitar/shoot.mp3")
            owner:EmitSound("ttt_pack_a_punch/rock_guitar/idle.mp3", 50, 100, 50)
        end
    end

    function SWEP:Reset()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        owner:StopSound("ttt_pack_a_punch/rock_guitar/shoot.mp3")
        owner:StopSound("ttt_pack_a_punch/rock_guitar/idle.mp3")
    end

    function SWEP:Holster()
        self:Reset()

        return true
    end

    function SWEP:PreDrop()
        self:Reset()
    end

    function SWEP:OnRemove()
        self:Reset()

        return true
    end
end

TTTPAP:Register(UPGRADE)