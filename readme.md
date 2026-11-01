# RubyUI

로블록스 Luau용 싱글 파일 UI 라이브러리. 사이드바 탭 + 좌/우 그룹박스 레이아웃, 토글/슬라이더/드롭다운/인풋/버튼/키피커/컬러피커 위젯, 알림 토스트, 설정 저장/불러오기(SaveManager), 테마 매니저(ThemeManager), 선택적 키 인증 화면(InitKeySystem)을 포함합니다.

## 설치

`rubyui.lua`를 실행기에서 불러오면 `Library` 테이블이 반환됩니다.

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rubyisbest276/scripts/refs/heads/main/ui.lua"))()
```

로컬 파일로 테스트 중이라면:

```lua
local Library = loadstring(readfile("rubyui.lua"))()
```

## 빠른 시작

```lua
local Library = loadstring(game:HttpGet("https://your-host/rubyui.lua"))()

local Window = Library:CreateWindow({
    Title = "RUBY UI",
    SubTitle = "v1.0",
    Footer = "made with RubyUI",
})

local Tab = Window:AddTab("Main", "home")
local Left = Tab:AddLeftGroupbox("General")

Left:AddToggle("MyToggle", {
    Text = "Example Toggle",
    Default = false,
    Callback = function(value)
        print("Toggle:", value)
    end,
})
```

더 전체적인 흐름은 `example.lua`를 참고하세요.

## `Library:CreateWindow(config)`

| 필드 | 타입 | 설명 |
|---|---|---|
| `Title` | string | 창 제목 (기본 `"EXTERNAL V2"`) |
| `SubTitle` | string | 제목 옆 서브텍스트 |
| `Footer` | string | 하단 바 텍스트 |
| `Center` | bool | 화면 중앙 배치 여부 (기본 true) |
| `AutoShow` | bool | 생성 즉시 보이기 (기본 true) |
| `BackgroundImage` | string | `rbxassetid://` 또는 URL 배경 이미지 |
| `ImageTransparency` | number | 배경 이미지 투명도 (0~1) |

`Window:AddTab(name, icon)` → `Tab`. `icon`은 Lucide 아이콘 이름("home", "settings" 등), `rbxassetid://숫자`, 숫자 문자열 중 아무거나 가능합니다.

`Tab:AddLeftGroupbox(title)` / `Tab:AddRightGroupbox(title)` → `Groupbox`

### Groupbox 위젯

- `Groupbox:AddToggle(id, { Text, Default, Callback })` → 체이닝 가능한 오브젝트 반환
  - `:AddColorPicker(id, { Default, Title, Callback })`
  - `:AddKeyPicker(id, { Default, Mode = "Toggle" | "Hold", Text, SyncToggleState, NoUI, Callback })`
- `Groupbox:AddSlider(id, { Text, Min, Max, Default, Rounding, Suffix, Callback })`
- `Groupbox:AddDropdown(id, { Text, Values, Default, Callback })`
  - 반환 오브젝트의 `:SetValues(newList)`로 목록 교체 가능
- `Groupbox:AddInput(id, { Text, Default, Placeholder, Finished, Callback })`
- `Groupbox:AddButton({ Text, Callback })`
- `Groupbox:AddLabel(text)` → `:AddKeyPicker(id, cfg)` 체이닝 가능

모든 `id`는 전역 `Toggles` / `Options` 테이블에 등록되어 다른 스크립트에서도 `Options["MyToggle"].Value`처럼 값을 읽을 수 있습니다 (`_G.Options`, `getgenv().Options`로도 접근 가능).

## 알림

```lua
Library:Notify({
    Title = "Saved",
    Message = "설정이 저장되었습니다.",
    Duration = 3,
    Icon = "check-circle",
})
```

## 설정 저장 (SaveManager)

```lua
Library.SaveManager:SetLibrary(Library)
Library.SaveManager:SetFolder("RubyLibraryConfigs")
Library.SaveManager:SetIgnoreIndexes({"MenuKeybind"}) -- 저장에서 제외할 id들

local ConfigTab = Window:AddTab("Config", "save")
Library.SaveManager:BuildConfigSection(ConfigTab)
Library.SaveManager:LoadAutoloadConfig() -- 창 생성 이후 호출
```

## 테마 (ThemeManager)

```lua
Library.ThemeManager:SetLibrary(Library)
Library.ThemeManager:SetFolder("RubyLibraryThemes")

local ThemeTab = Window:AddTab("Theme", "palette")
Library.ThemeManager:ApplyToTab(ThemeTab)
```

프리셋 액센트 색상, 커스텀 액센트/배경/테두리/텍스트 컬러피커, 배경 이미지 URL + 투명도 슬라이더, 폰트 선택, `End` 키로 UI 언로드까지 자동으로 구성됩니다.

## 키 인증 화면 (선택)

```lua
Library:InitKeySystem({
    Title = "Key Verification",
    Key = "RUBY-2026-KEY",
    Discord = "https://discord.gg/your-invite",
    OnSuccess = function()
        -- 인증 성공 후 Library:CreateWindow(...) 호출
    end,
})
```

## 키바인드 열기/닫기

`Options.MenuKeybind.Value`는 기본적으로 `Enum.KeyCode.RightShift`이며, 해당 키를 누르면 `Library:Toggle()`이 호출되어 창이 열고 닫힙니다. 다른 키로 바꾸려면:

```lua
Options.MenuKeybind:SetValue(Enum.KeyCode.Insert)
```

## 테마 커스터마이징 (코드로 직접)

```lua
Library:UpdateThemeColor("Accent", Color3.fromRGB(0, 230, 255))
Library:SetFont(Enum.Font.Montserrat)
Library:SetBackgroundImage("rbxassetid://1234567890", 0.85)
```

## 언로드

```lua
Library:OnUnload(function()
    print("UI unloaded")
end)

Library:Unload()
```

## 참고 사항

- 모든 위젯은 선언형 `id` 기반이며, `id`를 넘기지 않으면 `Toggles`/`Options`에 등록되지 않습니다 (익명 위젯으로 사용 가능).
- `Library:AddShadow` / `Library:ApplyGradient`는 커스텀 위젯을 직접 만들 때도 재사용할 수 있는 헬퍼입니다.
- `SaveManager`는 `writefile` / `readfile` / `isfile` / `listfiles` / `delfile`가 있는 실행기에서만 동작합니다 (없으면 조용히 무시됨).
