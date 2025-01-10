import Data.Map qualified as M
import Graphics.X11.ExtraTypes.XF86
  ( xF86XK_AudioLowerVolume,
    xF86XK_AudioMicMute,
    xF86XK_AudioMute,
    xF86XK_AudioNext,
    xF86XK_AudioPlay,
    xF86XK_AudioPrev,
    xF86XK_AudioRaiseVolume,
    xF86XK_Display,
    xF86XK_Favorites,
    xF86XK_Go,
    xF86XK_Messenger,
    xF86XK_MonBrightnessDown,
    xF86XK_MonBrightnessUp,
    xF86XK_WLAN,
  )
import XMonad
import XMonad.Actions.CopyWindow (copyToAll, kill1, killAllOtherCopies)
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)
import XMonad.Hooks.InsertPosition
import XMonad.Hooks.ManageDocks (avoidStruts, manageDocks)
import XMonad.Hooks.ManageHelpers (doFullFloat, isFullscreen)
import XMonad.Hooks.StatusBar
import XMonad.Layout.Fullscreen (fullscreenManageHook, fullscreenSupport)
import XMonad.Layout.Grid
import XMonad.Layout.NoBorders (Ambiguity (OnlyScreenFloat), lessBorders)
import XMonad.Layout.ResizableThreeColumns
import XMonad.Layout.Spacing (spacingWithEdge, toggleScreenSpacingEnabled, toggleWindowSpacingEnabled)
import XMonad.StackSet qualified as S

toggleFloat :: Window -> X ()
toggleFloat w =
  windows
    ( \s ->
        if M.member w (S.floating s)
          then S.sink w s
          else S.float w (S.RationalRect (1 / 3) (1 / 4) (1 / 2) (1 / 2)) s
    )

toggleFullscreen :: X ()
toggleFullscreen =
  withWindowSet $ \ws ->
    withFocused $ \w -> do
      let fullRect = S.RationalRect 0 0 1 1
      let isFullFloat = w `M.lookup` S.floating ws == Just fullRect
      windows $ if isFullFloat then S.sink w else S.float w fullRect

toggleGaps :: X ()
toggleGaps = do
  toggleScreenSpacingEnabled
  toggleWindowSpacingEnabled

-- Infix to make keybinds code cleaner
infixr 0 ~>

(~>) :: a -> b -> (a, b)
(~>) = (,)

keybinds conf@(XConfig {XMonad.modMask = mod, XMonad.terminal = term}) =
  M.fromList $
    [ -- launch a terminal
      (mod, xK_Return) ~> spawn term,
      -- lock screen
      (mod, xK_l) ~> spawn "xset s activate",
      -- launch browser
      (mod, xK_w) ~> spawn "$BROWSER",
      -- Color picker
      (mod, xK_c) ~> spawn "color",
      -- rofi menus
      (mod, xK_space) ~> spawn "rofi -show drun",
      (mod .|. shiftMask, xK_BackSpace) ~> spawn "power-menu",
      (mod, xK_e) ~> spawn "rofi -show emoji",
      (mod, xK_b) ~> spawn "rofi-bluetooth",
      -- launch file manager
      (mod, xK_r) ~> spawn (term ++ " -e $FM"),
      (mod .|. shiftMask, xK_r) ~> spawn "$FMGUI",
      -- email
      (mod, xK_m) ~> spawn "thunderbird",
      -- Media keys
      (0, xF86XK_AudioPlay) ~> spawn "playerctl play-pause",
      (0, xF86XK_AudioPrev) ~> spawn "playerctl previous",
      (0, xF86XK_AudioNext) ~> spawn "playerctl next",
      -- laptop top row
      (0, xF86XK_AudioMute) ~> spawn "audio-control mute",
      (0, xF86XK_AudioLowerVolume) ~> spawn "audio-control down 10%",
      (0, xF86XK_AudioRaiseVolume) ~> spawn "audio-control up 10%",
      (0, xF86XK_AudioMicMute) ~> spawn "amixer -q set Capture toggle",
      (0, xF86XK_MonBrightnessUp) ~> spawn "brightnessctl s +10%",
      (0, xF86XK_MonBrightnessDown) ~> spawn "brightnessctl s 10%-",
      -- not implemented yet
      (0, xF86XK_Display) ~> spawn "",
      (0, xF86XK_WLAN) ~> spawn "",
      (0, xF86XK_Messenger) ~> spawn "",
      (0, xF86XK_Go) ~> spawn "",
      (0, xK_Cancel) ~> spawn "",
      (0, xF86XK_Favorites) ~> spawn "",
      -- Change song with comma and period too
      (mod, xK_slash) ~> spawn "playerctl play-pause",
      (mod, xK_comma) ~> spawn "playerctl previous",
      (mod, xK_period) ~> spawn "playerctl next",
      -- Kill focused window
      (mod, xK_q) ~> kill,
      -- Toggle gaps
      (mod .|. shiftMask, xK_g) ~> toggleGaps, -- toggle all gaps
      -- Toggle Full Screen
      (mod .|. shiftMask, xK_f) ~> toggleFullscreen,
      -- Rotate through the available layout algorithms
      (mod, xK_n) ~> sendMessage NextLayout,
      -- Reset the layouts on the current workspace to default
      (mod .|. shiftMask, xK_n) ~> setLayout $ XMonad.layoutHook conf,
      -- Move focus to the next window
      (mod, xK_j) ~> windows S.focusDown,
      -- Move focus to the previous window
      (mod, xK_k) ~> windows S.focusUp,
      -- Swap the focused window and the master window
      (mod, xK_f) ~> windows S.swapMaster,
      -- Swap the focused window with the next window
      (mod .|. shiftMask, xK_j) ~> windows S.swapDown,
      -- Swap the focused window with the previous window
      (mod .|. shiftMask, xK_k) ~> windows S.swapUp,
      -- Shrink the master area
      (mod .|. shiftMask, xK_h) ~> sendMessage Shrink,
      -- Expand the master area
      (mod .|. shiftMask, xK_l) ~> sendMessage Expand,
      -- Toggle window being tiled or floating
      (mod, xK_t) ~> withFocused toggleFloat,
      -- Increment the number of windows in the master area
      (mod .|. shiftMask, xK_period) ~> sendMessage (IncMasterN 1),
      -- Deincrement the number of windows in the master area
      (mod .|. shiftMask, xK_comma) ~> sendMessage (IncMasterN (-1)),
      -- Restart xmonad
      (mod .|. shiftMask, xK_q) ~> spawn "xmonad --restart",
      -- Take a screenshot
      (mod .|. shiftMask, xK_s) ~> spawn "flameshot gui",
      (0, xK_Print) ~> spawn "flameshot screen -c",
      (0 .|. shiftMask, xK_Print) ~> spawn "flameshot screen",
      -- Window pinning to all workspaces
      (mod, xK_s) ~> windows copyToAll,
      (mod .|. controlMask, xK_s) ~> killAllOtherCopies,
      (mod .|. shiftMask, xK_c) ~> kill1
    ]
      ++
      -- mod-[1..9], Switch to workspace N
      -- mod-shift-[1..9], Move client to workspace N
      [ (m .|. mod, k) ~> windows $ f i
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9],
          (f, m) <- [(S.greedyView, 0), (S.shift, shiftMask)]
      ]
      ++
      -- mod-([, ]), Switch to physical/Xinerama screens 1 or 2
      -- mod-shift-([, ]), Move client to screen 1 or 2
      [ ((m .|. mod, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_braceleft, xK_braceright] [0 ..],
          (f, m) <- [(S.view, 0), (S.shift, shiftMask)]
      ]

myMouseBindings (XConfig {XMonad.modMask = modm}) =
  M.fromList
    [ -- Set the window to floating mode and move by dragging
      ( (modm, button1),
        \w ->
          focus w
            >> mouseMoveWindow w
            >> windows S.shiftMaster
      )
    ]

managehook =
  fullscreenManageHook
    <+> manageDocks
    <+> composeAll
      [ -- New windows will open at the bottom of the stack
        fmap not willFloat --> insertPosition Below Newer,
        isFullscreen --> (doF S.focusDown <+> doFullFloat)
      ]

layouthook =
  lessBorders OnlyScreenFloat $
    avoidStruts $
      spacingWithEdge
        8 -- width of gaps
        (ResizableThreeCol 1 (3 / 100) (1 / 2) [] ||| Grid)

toggleStrutsKey XConfig {XMonad.modMask = modm} = (modm, xK_b)

main :: IO ()
main =
  xmonad
    . fullscreenSupport
    . ewmhFullscreen
    . ewmh
    . withEasySB (statusBarProp "polybar -c ~/.config/polybar/config.ini" (pure def)) toggleStrutsKey
    $ def
      { terminal = "wezterm",
        focusFollowsMouse = True,
        clickJustFocuses = False,
        borderWidth = 3,
        modMask = mod4Mask,
        workspaces = map show [1 .. 9],
        normalBorderColor = "#000000",
        focusedBorderColor = "#d6acff",
        keys = keybinds,
        layoutHook = layouthook,
        manageHook = managehook
      }
