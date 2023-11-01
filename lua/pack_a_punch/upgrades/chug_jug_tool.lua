local UPGRADE = {}
UPGRADE.id = "chug_jug_tool"
UPGRADE.class = "weapon_ttt_fortnite_building"
UPGRADE.name = "Chug Jug Tool"

UPGRADE.convars = {
    {
        name = "pap_chug_jug_tool_shield",
        type = "int"
    },
    {
        name = "pap_chug_jug_tool_dmg_resist",
        type = "int"
    }
}

local shieldCvar = CreateConVar("pap_chug_jug_tool_shield", 100, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "No. of shield points", 1, 500)

local dmgResistCvar = CreateConVar("pap_chug_jug_tool_dmg_resist", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "% damage resistance", 0, 100)

UPGRADE.desc = "Gives you a health shield!\nResists " .. dmgResistCvar:GetInt() .. "% of damage, protects from 1-shot deaths!"

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()
    local maxShield = shieldCvar:GetInt()
    local dmgResist = 1 - dmgResistCvar:GetInt() / 100
    owner:SetColor(Color(0, 255, 255))

    if IsValid(owner) then
        owner:EmitSound("ttt_pack_a_punch/chug_jug_tool/shield.mp3")
        owner:SetNWInt("PAPHealthShield", maxShield)
    end

    -- Drawing the shield bar
    if CLIENT then
        self:AddHook("DrawOverlay", function()
            local ply = LocalPlayer()
            local shield = ply:GetNWInt("PAPHealthShield", 0)
            if shield <= 0 then return end
            local text = string.format("%i", shield, maxShield) .. " Shield"
            local x = 19
            local y = ScrH() - 95

            -- Don't show shield bar if player is dead or has the pause menu open
            if ply:Alive() and not ply:IsSpec() and not gui.IsGameUIVisible() then
                local texttable = {}
                texttable.font = "HealthAmmo"
                texttable.color = COLOR_WHITE

                texttable.pos = {135, y + 25}

                texttable.text = text
                texttable.xalign = TEXT_ALIGN_LEFT
                texttable.yalign = TEXT_ALIGN_BOTTOM
                draw.RoundedBox(5, x, y, 233, 28, Color(43, 65, 65))
                draw.RoundedBox(5, x, y, (shield / maxShield) * 233, 28, Color(67, 216, 216))
                draw.TextShadow(texttable, 2)
            end
        end)
    end

    -- Handling damage
    self:AddHook("EntityTakeDamage", function(ply, dmg)
        if not self:IsPlayer(ply) then return end
        local shield = ply:GetNWInt("PAPHealthShield", 0)

        if shield > 0 then
            local attacker = dmg:GetAttacker()
            local damage = dmg:GetDamage() * dmgResist
            ply:SetNWInt("PAPHealthShield", math.floor(shield - damage))
            ply:EmitSound("ttt_pack_a_punch/chug_jug_tool/block.mp3")

            if self:IsPlayer(attacker) then
                attacker:SendLua("surface.PlaySound(\"ttt_pack_a_punch/chug_jug_tool/block.mp3\")")
            end

            if ply:GetNWInt("PAPHealthShield", 0) <= 0 then
                ply:SetColor(COLOR_WHITE)
                ply:EmitSound("ttt_pack_a_punch/chug_jug_tool/break.mp3")

                if self:IsPlayer(attacker) then
                    attacker:SendLua("surface.PlaySound(\"ttt_pack_a_punch/chug_jug_tool/break.mp3\")")
                end
            end

            return true
        end
    end)

    self:AddHook("PlayerSpawn", function(ply)
        ply:SetNWInt("PAPHealthShield", 0)
    end)

    self:AddHook("PostPlayerDeath", function(ply)
        ply:SetNWInt("PAPHealthShield", 0)
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply:SetNWInt("PAPHealthShield", nil)
        ply:SetColor(COLOR_WHITE)
    end
end

TTTPAP:Register(UPGRADE)