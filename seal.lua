local inicfg = require 'inicfg'
local sampev = require 'samp.events'
local dlstatus = require('moonloader').download_status
local ffi = require 'ffi'

local imgui = require 'mimgui'
local new = imgui.new
local ActiveMenu = 1

local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- Автообновление
update_state = false;

local ScriptVersion = 4
local ScriptVersion_text = '0.2'

local UpdateSource = "https://raw.githubusercontent.com/meinhard-ru/seal/refs/heads/main/seal_update.ini"
local UpdatePath = getWorkingDirectory() .. "seal_update.ini"

local ScriptSource = "https://github.com/meinhard-ru/seal/raw/refs/heads/main/seal.lua"
local ScriptPath = thisScript().path

local SourceSettings = "seal.ini"
local ScriptSettings = inicfg.load({
    settings = {
        
        S_ActivateKillsay = false,
        S_KillsayVariation = 0,
        S_SendSquadMark = false,
        S_UseSquadMark = false,
        S_IgnoreMarkText = false,
        S_IgnoreYourMark = false,
        S_ActivationKey = '',
        S_UseCustomMarkTime = false,
        S_CustomMarkTime = 1000,
        S_AutoReport = false;
        S_ReportRadio = false;
        S_ReportSquad = false;

    },

    text = {
        S_CustomKillsay = [[Тут можно написать собственные отыгровки.
Максимум - 256 символов. Больше не получится ввести.
Так что опирайся на свои возможности!]]
    }
  }, SourceSettings)
  inicfg.save(ScriptSettings, SourceSettings)


-- Главное меню
local ActivateKillsay = imgui.new.bool(ScriptSettings.settings.S_ActivateKillsay)

-- Настройка отыгровок
local KillsayVariation = imgui.new.int(ScriptSettings.settings.S_KillsayVariation)

ScriptSettings.text.S_CustomKillsay = ScriptSettings.text.S_CustomKillsay:gsub("&", "\n")
local CustomKillsay = new.char[256](u8(ScriptSettings.text.S_CustomKillsay))

-- Настройка меток
local SendSquadMark = imgui.new.bool(ScriptSettings.settings.S_SendSquadMark)
local UseSquadMark = imgui.new.bool(ScriptSettings.settings.S_UseSquadMark)
local IgnoreMarkText = imgui.new.bool(ScriptSettings.settings.S_IgnoreMarkText)
local IgnoreYourMark = imgui.new.bool(ScriptSettings.settings.S_IgnoreYourMark)
local UseCustomMarkTime = imgui.new.bool(ScriptSettings.settings.S_UseCustomMarkTime)
local CustomMarkTime = new.int(ScriptSettings.settings.S_CustomMarkTime) 

-- Настройки отчетов
local AutoReport = imgui.new.bool(ScriptSettings.settings.S_AutoReport) 
local ReportRadio = imgui.new.bool(ScriptSettings.settings.S_ReportRadio) 
local ReportSquad = imgui.new.bool(ScriptSettings.settings.S_ReportSquad)

local WinState = new.bool(false)
local CheckpointTable = {}
local MapIconsTable = {}
local T_CustomKillsay = {}
local IsKillsayActive = false

function SoftBlueTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
  
    style.WindowPadding = imgui.ImVec2(15, 15)
    style.WindowRounding = 10.0
    style.ChildRounding = 6.0
    style.FramePadding = imgui.ImVec2(8, 7)
    style.FrameRounding = 8.0
    style.ItemSpacing = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing = imgui.ImVec2(10, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 12.0
    style.GrabMinSize = 10.0
    style.GrabRounding = 6.0
    style.PopupRounding = 8
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.90, 0.90, 0.93, 1.00)
    style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
    style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.18, 0.20, 0.22, 0.30)
    style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.13, 0.13, 0.15, 1.00)
    style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.30, 0.30, 0.35, 1.00)
    style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.18, 0.18, 0.20, 1.00)
    style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.15, 0.15, 0.17, 1.00)
    style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.10, 0.10, 0.12, 1.00)
    style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.15, 0.15, 0.17, 1.00)
    style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.30, 0.30, 0.35, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.50, 0.50, 0.55, 1.00)
    style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.70, 0.70, 0.90, 1.00)
    style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.70, 0.70, 0.90, 1.00)
    style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.80, 0.80, 0.90, 1.00)
    style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.18, 0.18, 0.20, 1.00)
    style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.60, 0.60, 0.90, 1.00)
    style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.28, 0.56, 0.96, 1.00)
    style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.20, 0.20, 0.23, 1.00)
    style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
    style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.50, 0.50, 0.55, 1.00)
    style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.60, 0.60, 0.65, 1.00)
    style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.20, 0.20, 0.23, 1.00)
    style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.64, 1.00)
    style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.70, 0.70, 0.75, 1.00)
    style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.61, 0.61, 0.64, 1.00)
    style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.70, 0.70, 0.75, 1.00)
    style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.10, 0.10, 0.12, 0.80)
    style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.18, 0.20, 0.22, 1.00)
    style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.60, 0.60, 0.90, 1.00)
    style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.28, 0.56, 0.96, 1.00)
end

imgui.OnFrame(function() return WinState[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(500,500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(800, 400), imgui.Cond.Always)
    imgui.Begin('SEAL', WinState, imgui.WindowFlags.NoResize)
    SoftBlueTheme()

    if imgui.Button(u8'Главное меню') then ActiveMenu = 1 end
    imgui.SameLine()

    if ActivateKillsay[0] then
        if imgui.Button(u8'Настройка отыгровки') then ActiveMenu = 2 end
        imgui.SameLine()

        if imgui.Button(u8'Настройка меток') then ActiveMenu = 3 end
        imgui.SameLine()

        if ActivateKillsay[0] then
            if imgui.Button(u8'Настройка отчетов') then ActiveMenu = 4 end
            imgui.SameLine()
        end
        
    end

    if imgui.Button(u8'Сохранение настроек') then
        UserNotification("Попытка сохранения настроек скрипта.")

        SaveSettings = {
            settings = {

                S_ActivateKillsay = ActivateKillsay[0],
                S_KillsayVariation = KillsayVariation[0],
                S_SendSquadMark = SendSquadMark[0],
                S_UseSquadMark = UseSquadMark[0],
                S_IgnoreMarkText = IgnoreMarkText[0],
                S_IgnoreYourMark = IgnoreYourMark[0],
                S_UseCustomMarkTime = UseCustomMarkTime[0],
                S_CustomMarkTime = CustomMarkTime[0],
                S_AutoReport = AutoReport[0];
                S_ReportRadio = ReportRadio[0];
                S_ReportSquad = ReportSquad[0];

            },

            text = {
                S_CustomKillsay = (u8:decode(ffi.string(CustomKillsay))):gsub("\n", "&")
            }
        }
        inicfg.save(SaveSettings, SourceSettings)
        UserNotification("Настройки скрипта успешно сохранены.")
    end

    imgui.Separator()

    if ActiveMenu == 1 then

            imgui.Checkbox(u8'Активация скрипта', ActivateKillsay)

    elseif ActiveMenu == 2 then

            imgui.RadioButtonIntPtr(tostring(u8"Без использования отыгровки"), KillsayVariation, 0)
            imgui.RadioButtonIntPtr(tostring(u8"Обассывание \"Классическое\""), KillsayVariation, 1)
            imgui.RadioButtonIntPtr(tostring(u8"За мат извини"), KillsayVariation, 2)
            imgui.RadioButtonIntPtr(tostring(u8"Hasta la vista"), KillsayVariation, 3)
            imgui.RadioButtonIntPtr(tostring(u8"Использовать свою отыгровку"), KillsayVariation, 4)
            if KillsayVariation[0] == 4 then
                imgui.Text(u8"Максимальное количество символов - 256\nИспользовать никнейм противника в отыгровках - $peenick")
                imgui.InputTextMultiline("##Своя отыгровка", CustomKillsay, 256)
            end

    elseif ActiveMenu == 3 then

        imgui.Checkbox(u8'Отправлять метки ликвидации в /fs', SendSquadMark)
        imgui.Checkbox(u8'Использовать метки ликвидации', UseSquadMark)
            if UseSquadMark[0] then
                imgui.Separator()
                imgui.Checkbox(u8'Не показывать текст меток в чате', IgnoreMarkText)
                imgui.Checkbox(u8'Игнорировать установку собственных меток', IgnoreYourMark)
                imgui.Checkbox(u8'Использовать свое время отображения метки (мс)', UseCustomMarkTime)
                if UseCustomMarkTime[0] then
                    imgui.SliderInt(u8'', CustomMarkTime, 100, 2000)
                end
                imgui.Separator()
            end

    elseif ActiveMenu == 4 then

        imgui.Checkbox(u8'Автоматическая отправка при убийстве', AutoReport)
        imgui.Checkbox(u8'Отчет о нейтрализации в /rb', ReportRadio)
        imgui.Checkbox(u8'Отчет о нейтрализации в /fs', ReportSquad)

    end
        
    imgui.End()
end)

function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
    while not isSampAvailable() do wait(100) end

    -- автообновление
    downloadUrlToFile(UpdateSource, UpdatePath, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            UpdateIni = inicfg.load(nil, UpdatePath)
            if tonumber(UpdateIni.version.Version) > ScriptVersion then
                UserNotification("Есть обновление! Текущая версия - "..ScriptVersion_text..". Доступная версия - "..UpdateIni.version.VersionText)
                update_state = true
            end
            os.remove(UpdatePath)
        end
    end)

	UserNotification("Скрипт успешно загружен. Автор: Isus Christos")
    UserNotification("Активация - /seal, Версия скрипта - "..ScriptVersion_text)

	sampRegisterChatCommand("seal", MainMenu)
	sampRegisterChatCommand("killsay", Killsay)

    while true do
        wait(0)

        -- автообновление
        if update_state then
            downloadUrlToFile(ScriptSource, ScriptPath, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    UserNotification("Скрипт успешно обновлен до версии "..UpdateIni.version.VersionText..". Приятного пользования!")
                    thisScript():reload()
                end
            end)
        end

        if ActivateKillsay[0] then
            EnemyResult, EnemyTarget = getCharPlayerIsTargeting(playerHandle)

            if EnemyResult and isCharInAnyCar(EnemyTarget) == false then
                EnemyResultTwo, EnemyID = sampGetPlayerIdByCharHandle(EnemyTarget)

                if EnemyResultTwo and EnemyID > - 1 then
                    EnemyNickname = sampGetPlayerNickname(EnemyID)
                    EnemyName, EnemySurname = string.match(EnemyNickname, "(%g+)_(%g+)")
                    EnemyHP = sampGetPlayerHealth(EnemyID)

                    if EnemyHP == 0 and isCharDead(EnemyTarget) then
                        EnemyX, EnemyY, EnemyZ = getCharCoordinates(EnemyTarget)
                        EnemyIsKilled = true
                        if EnemyIsKilled and AutoReport[0] and not IsKillsayActive then
                            Killsay()
                        end
                    end
                end
            end
        end
    end

	wait(-1)
end

function MainMenu()
	WinState[0] = not WinState[0]
end

function Killsay()
    lua_thread.create(function()
        if EnemyIsKilled and not IsKillsayActive then

            IsKillsayActive = true
            EnemyIsKilled = false

            PlayerX, PlayerY, PlayerZ = getCharCoordinates(playerPed)

            if SendSquadMark[0] then
                Killsay_SendSquadMark()
            end

            if getDistanceBetweenCoords3d(EnemyX, EnemyY, EnemyZ, PlayerX, PlayerY, PlayerZ) < 15 then

                if KillsayVariation[0] == 1 then
                    sampSendChat("/me расстегнул ширинку, приспустил джинсы, сделал тяжелый вдох, достал инструмент.")
                    wait(1400)
                    sampSendChat("/do Ароматная золотая жидкость струйкой стекает по трупу "..EnemyNickname..".")
                    wait(1400)
                    sampSendChat("/me подтянул джинсы, вздохнул с облегчением, застегнул ширинку.")
                    wait(1400)

                elseif KillsayVariation[0] == 2 then
                    sampSendChat("Слышь "..EnemyNickname.." хуле ты мне сделаешь??")
                    wait(1400)
                    sampSendChat("вовторых пошел нахуй")
                    wait(1400)
                    sampSendChat("втетьих что ты мне сделаешь, я в другом городе, за мат извени")
                    wait(1400)

                elseif KillsayVariation[0] == 3 then
                    sampSendChat("Hasta la vista, "..EnemyNickname)
                    wait(1400)

                elseif KillsayVariation[0] == 4 then
                    for CustomKillsay_text in u8:decode(ffi.string(CustomKillsay)):gmatch("[^\r\n]+") do
                        CustomKillsay_text = CustomKillsay_text:gsub("$peenick", ''..EnemyNickname)
                        table.insert(T_CustomKillsay, CustomKillsay_text)
                    end

                    for i, CustomKillsay_text in ipairs(T_CustomKillsay) do
                        sampSendChat(CustomKillsay_text)
                        wait(1400)
                    end

                    T_CustomKillsay = {}

                end
            end


            if ReportSquad[0] then
                sampSendChat("/fs "..EnemyNickname.."["..EnemyID.."] нейтрализован.")
                wait(1200)
            end

            if ReportRadio[0] then
                sampSendChat("/rb "..EnemyNickname.."["..EnemyID.."] нейтрализован.")
                wait(1200)
            end

            IsKillsayActive = false

        end
    end)
end

function SetDeathCheckpoint()
    local PlayerNickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
    if PlayerNickname == SendNick and IgnoreYourMark[0] then
        return false
    else
        lua_thread.create(function()
            local SetCheckpoint = createCheckpoint(2, tonumber(MarkX), tonumber(MarkY), tonumber(MarkZ), 0, 0, 0, 1)
            local MapIcon = addSpriteBlipForContactPoint(MarkX, MarkY, MarkZ, 19)
            table.insert(CheckpointTable, SetCheckpoint)
            table.insert(MapIconsTable, MapIcon)

            if UseCustomMarkTime[0] then

                wait(math.floor(CustomMarkTime[0]))

                for i, CheckHandle in ipairs(CheckpointTable) do
                    deleteCheckpoint(CheckHandle)
                    CheckHandle = nil
                end

                for i, MapHandle in ipairs(MapIconsTable) do
                    removeBlip(MapHandle)
                    MapHandle = nil
                end

            else

                wait(1000)

                for i, CheckHandle in ipairs(CheckpointTable) do
                    deleteCheckpoint(CheckHandle)
                    CheckHandle = nil
                end

                for i, MapHandle in ipairs(MapIconsTable) do
                    removeBlip(MapHandle)
                    MapHandle = nil
                end
            end
        end)
    end
end

function Killsay_SendSquadMark()
    if getActiveInterior() == 0 then
        sampSendChat("/u DCHECKSEALKPOSX"..math.floor(EnemyX).."Y"..math.floor(EnemyY).."Z"..math.floor(EnemyZ))
        wait(1000)
    end
end

function sampev.onServerMessage(color, text)
    if text:find("^.+%[.*%]% {FFFFFF%}(.*)%[(.*)%]: DCHECKSEALKPOSX.+Y.+Z.+") and UseSquadMark[0] and ActivateKillsay[0] then
        SendNick, SendID, MarkX, MarkY, MarkZ = text:match("^.+%[.*%]% {FFFFFF%}(.*)%[(.*)%]: DCHECKSEALKPOSX(.+)Y(.+)Z(.+)")
        SetDeathCheckpoint(MarkX, MarkY, MarkZ)
        if IgnoreMarkText[0] then
            return false
        end
    end
end

function UserNotification(UserNorification_text)
    sampAddChatMessage("[SEAL] {FFFFFF}"..UserNorification_text, 0xDC143C)
end