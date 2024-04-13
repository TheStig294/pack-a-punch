local UPGRADE = {}
UPGRADE.id = "you_cant_see_me"
UPGRADE.class = "weapon_john_bomb"
UPGRADE.name = "You Can't See Me"
UPGRADE.desc = "Become semi-invisible while holding"

function UPGRADE:Apply(SWEP)
    function SWEP:Cloak()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        owner:SetColor(Color(255, 255, 255, 0))
        owner:DrawShadow(false)
        owner:SetMaterial("models/effects/vol_light001")
        owner:SetRenderMode(RENDERMODE_TRANSALPHA)
        self:EmitSound("weapons/physgun_off.wav")
        self.conceal = true
    end

    function SWEP:UnCloak()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        owner:DrawShadow(true)
        owner:SetMaterial("")
        owner:SetRenderMode(RENDERMODE_NORMAL)
        self.conceal = false
    end

    function SWEP:Deploy()
        self:Cloak()

        return true
    end

    function SWEP:Holster()
        self:UnCloak()

        return true
    end

    function SWEP:PreDrop()
        self:UnCloak()
    end

    SWEP:Cloak()
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply:DrawShadow(true)
        ply:SetMaterial("")
        ply:SetRenderMode(RENDERMODE_NORMAL)
    end
end

TTTPAP:Register(UPGRADE)