This is a Powershell script for setting up an Idris development environment on Windows. It requires Powershell 3.0.

It is based on the corresponding script for [GHC](https://github.com/melted/getghc).

### Usage

To use it create an empty directory to be used for the installation, place the script get-idris.ps1 there and run it from PowerShell. By default it builds a 64-bit Idris, which can be changed in the script. When the script has finished, Idris can be run by starting the `mingw32_shell.bat` or `mingw64_shell.bat` (choose the same as the bitness you built with, 64 if you haven't changed anything) and running `idris` from the shell prompt. The Idris source is in `msys/home/<your user name>/idris`. It can be updated with `git pull` and rebuilt with `make`.

If you want to use Idris outside of the MSYS shell you need to put the Idris executable and gcc in your Windows path environment variable. `Idris.exe` is in `<Your windows home dir>\AppData\Roaming\cabal\bin`, gcc is in `msys/mingw32/bin` or `msys/mingw64/bin`.
