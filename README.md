# ElvUI - Vanilla (1.12.1)
:exclamation: *Does NOT work with Retail - [Classic (1.13)](https://git.tukui.org/elvui/elvui-classic)*

This is the backported version of ElvUI for World of Warcraft - Vanilla (1.12.1) 
<br />
ElvUI is a full UI replacement.
It completely replaces the default Blizzard UI at every level with a new and better interface.
As such, you'll only ever have to update ElvUI and not worry too much about its individual components.
This UI will arrange your interface to be more flexible and practical.

## Screenshots:

<img src="https://cloud.githubusercontent.com/assets/590348/22867052/f8d570ba-f190-11e6-9e4c-aee3adc16154.jpg" align="right" width="48.5%">
<img src="https://cloud.githubusercontent.com/assets/590348/22867049/f8d43506-f190-11e6-9a1c-019a9a190fd7.jpg" width="48.5%">
<img src="https://cloud.githubusercontent.com/assets/590348/22867050/f8d4f662-f190-11e6-9acd-fc83d7827bc0.jpg" align="right" width="48.5%">
<img src="https://cloud.githubusercontent.com/assets/590348/22944322/5d95a2b0-f301-11e6-81e3-52d1d619c850.jpg" width="48.5%">
<img src="https://user-images.githubusercontent.com/19589902/30231616-62e40f32-94f4-11e7-9712-a32f19719cd8.jpg" align="right" width="48.5%">
<img src="https://user-images.githubusercontent.com/19589902/30231617-62e74594-94f4-11e7-96e5-65d81991dcf1.jpg" width="48.5%">

## Plugins:

[ElvUI_AddOnSkins](https://github.com/ElvUI-Vanilla/ElvUI_AddOnSkins)
<br />
[ElvUI_DataTextColors](https://github.com/ElvUI-Vanilla/ElvUI_DataTextColors)
<br />
[ElvUI_Enhanced](https://github.com/ElvUI-Vanilla/ElvUI_Enhanced)
<br />
[ElvUI_EnhancedFriendsList](https://github.com/ElvUI-Vanilla/ElvUI_EnhancedFriendsList)
<br />
[ElvUI_LocPlus](https://github.com/ElvUI-Vanilla/ElvUI_LocPlus)
<br />
[ElvUI_RaidMarkers](https://github.com/ElvUI-Vanilla/ElvUI_RaidMarkers)

-- Please Note: These plugins will not function without ElvUI installed.

## Commands:

    /ec or /elvui     Toggle the configuration GUI.
    /rl or /reloadui  Reload the whole UI.
    /moveui           Open the movable frames options.
    /bgstats          Toggles Battleground datatexts to display info when inside a battleground.
    /egrid            Toggles visibility of the grid for helping placement of thirdparty addons.
    /farmmode         Toggles the Minimap Farmmode.
    /in               The input of how many seconds you want a command to fire. 
                          usage: /in <seconds> <command>
                          example: /in 1.5 /say hi
    /enable           Enable an Addon. 
                          usage: /enable <addon>
                          example: /enable AtlasLoot
    /disable          Disable an Addon.
                          usage: /disable <addon>
                          example: /disable AtlasLoot
    
    ---------------------------------------------------------------------------------------------------------------
    -- Development ------------------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------------
    /etrace           Toggles events window.
    /luaerror on      Enable luaerrors.
    /luaerror off     Disable luaerrors.
    /frame            Command to grab frame information when mouseing over a frame or when inputting the name.
                          usage: /frame (when mousing over frame) or /frame <name>
                          example: /frame WorldFrame
    /framelist        Dumps frame level information with children and parents. Also places info into copy box.
    /framestack       Toggles dynamic mouseover frame displaying frame name and level information.
    /resetui          If no argument is provided it will reset all frames to their default positions. 
                      If an argument is provided it will reset only that frame. 
                          example: /resetui uf (resets all unitframes)
                  

## Languages:

ElvUI supports and contains language specific code for the following gameclients:
* English (enUS)
* Korean (koKR)
* French (frFR)
* German (deDE)
* Chinese (zhCN)
* Spanish (esES)
* Russian (ruRU)

## FAQ:

### I would like to report a bug. What i need to do?
Make sure you're using the latest version of ElvUI
<br />
Describe your issue in as much detail as possible.
<br />
If your issue is graphical, please take some screenshots to illustrate it.
<br />
What were you doing when the problem occurred?
<br />
Explain how people can reproduce the issue.
<br />
The more info you provide, the better and faster support you will receive.

### I would like to request a feature. Where do I go?
This repository has been created to reproduce the original ElvUI functions.
<br />
If you want to request a feature, post in the [ElvUI_Enhanced](https://github.com/ElvUI-Vanilla/ElvUI_Enhanced/issues)

### I have a suggestion/problem with ElvUI_"PluginName". Where do I go?
Create an issue at the bug tracker of [ElvUI](https://github.com/ElvUI-Vanilla)_"PluginName" repository.

## FAQ RU:

### Я хочу сообщить о баге. Что мне нужно делать?
Убедитесь что вы используете последнюю версию ElvUI
<br />
Детально опишите свою проблему.
<br />
Если ваша проблема носит визуальный характер, пожалуйста предоставьте скриншоты.
<br />
Что вы делали, когда произошла ошибка?
<br />
Опишите, как можно воспроизвести эту ошибку.
<br />
Чем больше информации о проблемы вы предоставите, тем быстрее вам помогут.

### Я хотел бы попросить о добавлении возможности в ElvUI. Где написать?
Данный репозиторий создан с целью воспроизведения оригинального функционал ElvUI.
<br />
Запросы на добавление нового функционала рассматриваются в репозитории [ElvUI_Enhanced](https://github.com/ElvUI-Vanilla/ElvUI_Enhanced/issues)

### У меня проблема с ElvUI_"ИмяПлагина". Где написать?
Создайте запрос в репозитории баг-трекере [ElvUI](https://github.com/ElvUI-Vanilla)_"ИмяПлагина".
