local UPGRADE = {}
UPGRADE.id = "gif_gun"
UPGRADE.class = "weapon_ttt_meme_gun"
UPGRADE.name = "GIF Gun"
UPGRADE.desc = "x2 ammo, memes are animated GIFs!"
UPGRADE.ammoMult = 2
local materialFiles = file.Find("materials/ttt_pack_a_punch/gif_gun/*", "GAME")
local soundFiles = file.Find("sound/ttt_pack_a_punch/gif_gun/*", "GAME")

if SERVER then
    -- Forcing clients to download all images and sounds, including custom ones just sitting in the server materials/sound folders
    for _, fileName in ipairs(materialFiles) do
        resource.AddFile("materials/ttt_pack_a_punch/gif_gun/" .. fileName)
    end

    for _, fileName in ipairs(soundFiles) do
        resource.AddFile("sound/ttt_pack_a_punch/gif_gun/" .. fileName)
    end
end

function UPGRADE:Apply(SWEP)
    -- Populate meme gun material and sounds tables
    local memeMaterials = {}
    local memeSounds = {}

    for _, image in ipairs(materialFiles) do
        if string.GetExtensionFromFilename(image) == "vmt" then
            local mat = Material("ttt_pack_a_punch/gif_gun/" .. image)
            local name = string.StripExtension(image)
            memeMaterials[name] = mat
        end
    end

    for _, soundFile in ipairs(soundFiles) do
        if string.GetExtensionFromFilename(soundFile) == "mp3" then
            local snd = Sound("ttt_pack_a_punch/gif_gun/" .. soundFile)
            local name = string.StripExtension(soundFile)
            memeSounds[name] = snd
        end
    end

    -- It really helps when you can just add your own hooks to your own weapon...
    -- Selects a random meme, sends the chosen meme to clients, and plays the meme's sound if it has one
    if SERVER then
        self:AddHook("MemeGunSpawnedMeme", function(meme, gun)
            if self:IsUpgraded(gun) then
                local memeNames = table.GetKeys(memeMaterials)
                local randomMeme = memeNames[math.random(#memeNames)]
                meme:SetNWString("PAPGifGunMemeName", randomMeme)
                local memeSound = memeSounds[randomMeme]

                -- For a meme to play sound, it must have a .mp3 file the same name as the meme image in sound/ttt_pack_a_punch/gif_gun/
                if memeSound then
                    meme:EmitSound(memeSound)
                    meme:EmitSound(memeSound)

                    meme:CallOnRemove("PAPGifGunStopSound", function(ent)
                        ent:StopSound(memeSound)
                        ent:StopSound(memeSound)
                    end)
                end
            end
        end)
    end

    -- Sets the meme material
    if CLIENT then
        self:AddHook("MemeGunSetMaterial", function(meme)
            local name = meme:GetNWString("PAPGifGunMemeName", "")
            -- For a meme to work, it must be a .vtf file in materials/ttt_pack_a_punch/gif_gun/, as an UnlitGeneric and have "$nocull 1" set
            if name ~= "" then return memeMaterials[name] end
        end)
    end
end

TTTPAP:Register(UPGRADE)