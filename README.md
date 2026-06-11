# LangSwitch

Repurpose your **Caps Lock** key as a keyboard layout switcher on Windows.
This utility is *Windows only*.

> [!WARNING]
> Program require **admin** privileges to work in file rename and file picker windows, due to some Windows limitations. Though **admin** privileges is not necessary to work.

## Install

Run in PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
irm https://github.com/NiTiSon/langswitch/releases/latest/download/install.ps1 | iex
```

## Uninstall

Go to **Settings → Apps → Installed apps**, find **LangSwitch**, and click **Uninstall**.  
Or run `%LocalAppData%\langswitch\uninstall.ps1` manually.

## Build

Requirements:
+ LLVM 22 (or any other version, I suppose)
+ Windows

To build application just launch `build.cmd` that's all.