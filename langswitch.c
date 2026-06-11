#include <Windows.h>
#include <errhandlingapi.h>
#include <handleapi.h>
#include <processthreadsapi.h>
#include <tchar.h>
#include <winbase.h>
#include <winnt.h>
#include <winuser.h>

#define false 0
#define true 1
#define null NULL
#define main WinMainCRTStartup

HHOOK    langswitch_hook;

[[noreturn]]
void report_winapi(const TCHAR *msg) {
    const TCHAR *strings[2];
    strings[1] = msg;
    const DWORD lastError = GetLastError();

    DWORD result = FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        null,
        lastError,
        0,
        (LPTSTR)&strings[0],
        0,
        null);

    if (result == 0) {
        goto EXIT;
    }

    result = FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER|FORMAT_MESSAGE_FROM_STRING|FORMAT_MESSAGE_ARGUMENT_ARRAY,
        _TEXT("%2\n\nSystem message:\n%1"),
        0,
        0,
        (LPTSTR)&strings[1],
        0,
        (va_list*)&strings[0]);

    if (result == 0) {
        goto EXIT;
    }

    MessageBox(null, strings[1], _TEXT("LangSwitch Error"), MB_OK | MB_ICONERROR);
EXIT:
    ExitProcess(1u);
}

[[noreturn]]
void report_msg(const TCHAR *msg) {
    MessageBox(null, msg, _TEXT("LangSwitch Error"), MB_OK | MB_ICONERROR);
    ExitProcess(1u);
}

LRESULT hook_proc(int code, WPARAM wParam, LPARAM lParam) {
    if (code < 0) {
        goto NEXT;
    }

    if (code == HC_ACTION) {
        KBDLLHOOKSTRUCT *ks = (KBDLLHOOKSTRUCT *)lParam;
        if (ks->vkCode == VK_CAPITAL &&
            (GetKeyState(VK_SHIFT) >= 0) &&
            wParam == WM_KEYDOWN) {
            HWND hwnd = GetForegroundWindow();

            if (hwnd != null) {
                PostMessage(hwnd, WM_INPUTLANGCHANGEREQUEST, 0, (LPARAM)HKL_NEXT);
                return true;
            }
        }
    }

NEXT:
    return CallNextHookEx(langswitch_hook, code, wParam, lParam);
}

void main() {
    const HANDLE hEvent = CreateEvent(null, true, false, _TEXT("NiTiSonLangSwitch"));

    if (hEvent == null) {
        report_winapi(_TEXT("CreateEvent()"));
    }

    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        report_msg(_TEXT("LangSwitch is already running!"));
        goto EXIT;
    }

    langswitch_hook = SetWindowsHookEx(WH_KEYBOARD_LL, hook_proc, GetModuleHandle(0), 0);
    if (langswitch_hook == 0)
        report_winapi(_T("SetWindowsHookEx()"));

    MSG msg;
    while (GetMessage(&msg, 0, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    UnhookWindowsHookEx(langswitch_hook);
    CloseHandle(hEvent);
EXIT:
    ExitProcess(0u);
}