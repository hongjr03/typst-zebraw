set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

package target="@local":
    bash scripts/package "{{target}}"

test:
    tt run
