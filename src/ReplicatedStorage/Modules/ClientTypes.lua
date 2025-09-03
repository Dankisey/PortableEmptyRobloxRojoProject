local SharedTypes = require(script.Parent.SharedTypes)
local UtilsTypes = require(script.Parent.UtilsTypes)
local Types = {}

--[[========================================================================================]]

export type ButtonsInteractionsConnector = {
    new: () -> ButtonsInteractionsConnector;

    ConnectButton: (ButtonsInteractionsConnector, button: GuiButton, callback: (any) -> (), any) -> nil;
    DisconnectButton: (ButtonsInteractionsConnector, button: GuiButton) -> nil;

    _connectedButtons: {[GuiButton]: {
        IsActive: boolean;
        HoveringTask: thread;
        Connection: RBXScriptConnection;
    }};
    _buttonsParent: {[GuiButton]: ScreenGui};
    _tweenigButtons: {[GuiButton]: boolean};
    _isMobile: boolean;
} & ControllerTemplate

export type CharacterMovementController = {
    new: () -> CharacterMovementController;

    EnableMovement: (CharacterMovementController) -> nil;
    DisableMovement: (CharacterMovementController) -> nil;
} & ControllerTemplate

export type ClientMessagesSender = {
    new: () -> ClientMessagesSender;

    SendMessage: (ClientMessagesSender, messageType: "Default"|"Congrats"|"Error", baseMessage: string, playerNames: {string}?) -> nil;
    MessageSent: UtilsTypes.Event;
} & ControllerTemplate

export type DialogSystem = {
    new: () -> DialogSystem;

    StartDialog: (DialogSystem, dialogName: string) -> nil;
    ProcessResponse: (DialogSystem, responseIndex: number) -> nil;
    EndDialog: (DialogSystem) -> nil;

    DialogStarted: UtilsTypes.Event;
    DialogUpdated: UtilsTypes.Event;
    DialogEnded: UtilsTypes.Event;
}

export type GuideBeamController = {
    new: () -> GuideBeamController;

    CreateOrRedirectGuideBeam: (GuideBeamController, category: string, targetPosition: Vector3, reachDistance: number?) -> nil;
    CreateOrRedirectGuideBeamToPart: (GuideBeamController, category: string, targetPart: Part, reachDistance: number?) -> nil;
    TryDestroyBeam: (GuideBeamController, category: string, isSavingTarget: boolean?) -> boolean;
} & ControllerTemplate

export type InputController = {
    new: () -> InputController;

    GetControllType: (InputController) -> "Console"|"Mobile"|"Desktop";
} & ControllerTemplate

export type SoundPlayer = {
    new: () -> SoundPlayer;

    PlaySound: (SoundPlayer, soundName: string, onPart: Part?) -> Sound;
} & ControllerTemplate

export type ToolsController = {
    new: () -> ToolsController;

    ActivateTool: (ToolsController, tool: Tool) -> ();
    ToolUnequipped: UtilsTypes.Event;
    ToolEquipped: UtilsTypes.Event;
} & ControllerTemplate

export type TooltipsController = {
    new: () -> TooltipsController;

    RegisterDefaultTooltip: (TooltipsController, activationObject: GuiObject, tooltipText: string) -> nil;
    RegisterTooltip: (TooltipsController, activationObject: GuiObject, info: {Type: string}) -> nil;

    DefaultTooltipActivated: UtilsTypes.Event;
    DefaultTooltipDisabled: UtilsTypes.Event;
} & ControllerTemplate

export type ZoneController = {
    new: () -> ZoneController;

    GetPlayersZone: (ZoneController, player: Player) -> Model;
    GetTeleportPart: (ZoneController) -> Part;
    GetZone: (ZoneController) -> Model;
} & ControllerTemplate

--[[========================================================================================]]

export type InfoPin = {
    new: (frame: Frame) -> InfoPin;

    IsEnabled: (InfoPin) -> boolean;
    TurnOff: (InfoPin) -> nil;
    TurnOn: (InfoPin) -> nil;
}

export type BoostWidget = {
    new: (frame: Frame, imageId: string, timer: UtilsTypes.Timer?) -> BoostWidget;

    SetText: (BoostWidget, text: string) -> nil;
    Destroy: (BoostWidget) -> nil;
}

export type BoostsFrame = {
    new: (frame: Frame) -> BoostsFrame;

    TryAddBoostWidget: (BoostsFrame, key: string, imageId: string, tooltipInfo: {any}, timer: UtilsTypes.Timer?) -> BoostWidget?;
    TryUpdateBoostTimer: (BoostsFrame, key: string, countTime: number) -> boolean;
    TryRemoveWidget: (BoostsFrame, key: string) -> boolean;
}  & ControllerTemplate

export type MainGui = {
    new: () -> MainGui;

    Boosts: BoostsFrame;
} & GuiTemplate

export type PopusGui = {
    new: () -> PopusGui;

    FirePopup: (PopusGui, statName: string, data: any) -> nil;
} & GuiTemplate

export type GuiController = {
    new: () -> GuiController;

    TryAddToEnablingQueue: (GuiController, gui: ScreenGui) -> nil;
    ForceEnabling: (GuiController, gui: ScreenGui) -> nil;

    [string]: GuiTemplate;
}
--[[========================================================================================]]

export type Controllers = {
    ButtonsInteractionsConnector: ButtonsInteractionsConnector;
    CharacterMovementController: CharacterMovementController;
    ClientMessagesSender: ClientMessagesSender;
    DialogSystem: DialogSystem;
    GuiController: GuiController;
    GuideBeamController: GuideBeamController;
    InputController: InputController;
    SoundPlayer: SoundPlayer;
    ToolsController: ToolsController;
    TooltipsController: TooltipsController;
    ZoneController: ZoneController;
}

--[[========================================================================================]]
export type AnimatedGuiTemplate = {
    CancelAnimations: (AnimatedGuiTemplate) -> nil;
    RemoveTween: (AnimatedGuiTemplate, tween: Tween) -> nil;

    InitialSize: UDim2;
    MainFrame: Frame;

    _animationTweens: {Tween};
} & GuiTemplate

export type GuiTemplate = {
    Enable: (GuiTemplate, isForced: boolean) -> nil;
    Disable: (GuiTemplate) -> nil;
    CreateChildren: (GuiTemplate, guiName: string, modules: {ModuleScript}) -> nil;

    InjectControllers: (GuiTemplate, controllers: Controllers) -> nil;
    InjectUtils: (GuiTemplate, utils: UtilsTypes.Utils) -> nil;
    InjectConfigs: (GuiTemplate, configs: {[string]: any}) -> nil;

    Disabled: UtilsTypes.Event;

    Gui: ScreenGui;
    Name: string;
    _controllers: Controllers;
    _utils: UtilsTypes.Utils;
    _configs: {[string]: any};
}

export type ControllerTemplate = {
    InjectControllers: (ControllerTemplate, controllers: Controllers) -> nil;
    InjectUtils: (ControllerTemplate, utils: UtilsTypes.Utils) -> nil;
    InjectConfigs: (ControllerTemplate, configs: {[string]: any}) -> nil;

    _controllers: Controllers;
    _utils: UtilsTypes.Utils;
    _configs: {[string]: any};
}

return Types