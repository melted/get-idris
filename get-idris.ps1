# A Powershell script for setting up an Idris build environment
# by Niklas Larsson <niklas@mm.st>
#
# This script is based on the corresponding script for GHC at
# https://github.com/melted/getghc.git
# For best results, run it in an empty directory.
#
# This file has been placed in the public domain by the author.

$current_dir = pwd
$msys = 64 # Change to 32 to build a 32-bit GHC

function get-tarball {
    param([string]$url, [string]$outfile, [string]$hash)
    $exists = Test-Path $outfile
    if(!$exists) {
        Invoke-WebRequest $url -OutFile $outfile -UserAgent "Curl"
        if(Test-Path $outfile) {
            Unblock-File $outfile
        } else {
            Write-Error "failed to get file $url"
            return $false
        }
    }
    $filehash = Get-FileHash $outfile -Algorithm SHA1
    if ($filehash.Hash -ne $hash) {
        rm $outfile
        $res = $filehash.Hash
        Write-Error "Mismatching hashes for $url, expected $hash, got $res"
        return $false
    } else {
        return $true
    }
}

function extract-zip
{
    param([string]$zip, [string] $outdir)
    $has_dir=Test-Path $outdir
    if(!$has_dir) {
        mkdir $outdir
    }
    if(test-path $zip)
    {
        $shell = new-object -com shell.application
        $zipdir = $shell.NameSpace($zip)
        $target = $shell.NameSpace($outdir)
        $target.CopyHere($zipdir.Items())
    }
}


function create-dir {
    param([string]$name)
    $exists = test-path $name
    if(!$exists) {
        mkdir $name
    }
}

function create-dirs {
    create-dir downloads
    create-dir support
}

function install-ghc32 {
    $url="http://www.haskell.org/ghc/dist/7.8.2/ghc-7.8.2-i386-unknown-mingw32.tar.xz"
    $file="downloads\ghc32.tar.xz"
    $hash="87C8F37EF3C4A7266043B18F2AE869C551681EF3"
    if(get-tarball $url $file $hash) {
        .\support\7za x -y $file
        .\support\7za x -y ghc32.tar -omsys
        rm ghc32.tar
    }
}

function install-msys32() {
    $url="http://sourceforge.net/projects/msys2/files/Base/i686/msys2-base-i686-20131208.tar.xz/download"
    $file="downloads\msys32.tar.xz"
    $hash="6AD1FA798C7B7CA9BFC46F01708689FD54B2BB9B"
    if(get-tarball $url $file $hash) {
        .\support\7za x -y $file
        .\support\7za x -y msys32.tar
        mv msys32 msys
        rm msys32.tar
    }
}

function install-ghc64 {
    $url="http://www.haskell.org/ghc/dist/7.8.2/ghc-7.8.2-x86_64-unknown-mingw32.tar.xz"
    $file="downloads\ghc64.tar.xz"
    $hash="B512690BFACD446DDE0C98302013DCAFCE4535A9"
    if(get-tarball $url $file $hash) {
        .\support\7za x -y $file
        .\support\7za x -y ghc64.tar -omsys
        rm ghc64.tar
    }
}

function install-msys64() {
    $url="http://sourceforge.net/projects/msys2/files/Base/x86_64/msys2-base-x86_64-20140216.tar.xz/download"
    $file="downloads\msys64.tar.xz"
    $hash="B512C52B3DAE5274262163A126CE43E5EE4CA4BA"
    if(get-tarball $url $file $hash) {
        .\support\7za x -y $file
        .\support\7za x -y msys64.tar
        mv msys64 msys
        rm msys64.tar
    }
}

function install-7zip() {
    $url="http://sourceforge.net/projects/sevenzip/files/7-Zip/9.20/7za920.zip/download"
    $file="downloads\7z.zip"
    $hash="9CE9CE89EBC070FEA5D679936F21F9DDE25FAAE0"
    if (get-tarball $url $file $hash) {
        $dir = "$current_dir\support"
        $abs_file = "$current_dir\$file"
        create-dir $dir
        Extract-Zip $abs_file $dir
    }
}

function download-cabal {
    $url=" http://www.haskell.org/cabal/release/cabal-install-1.18.0.2/cabal.exe"
    $file="downloads\cabal.exe"
    $hash="776AAF4626993FB308E3168944A465235B0DA9A5"
    if (get-tarball $url $file $hash) {
    }
}

function run-msys-installscripts {
    .\msys\bin\bash -l -c "exit"
     $current_posix=.\msys\bin\cygpath.exe -u $current_dir
     $win_home = .\msys\bin\cygpath.exe -u $HOME
     $cache_file = $HOME+"\AppData\roaming\cabal\packages\hackage.haskell.org\00-index.cache"
     if (Test-Path $cache_file) {
        Write-Host "Removing cabal cache"
        rm $cache_file
     }

    $bash_paths=@"
        mkdir -p ~/bin
        echo 'export LC_ALL=C' >> ~/.bash_profile
        echo 'export PATH=/ghc-7.8.2/bin:`$PATH'       >> ~/.bash_profile
        echo 'export PATH=`$HOME/bin:`$PATH'            >> ~/.bash_profile
        echo 'export PATH=$($win_home)/AppData/Roaming/cabal/bin:`$PATH' >> ~/.bash_profile
"@
    echo $bash_paths | Out-File -Encoding ascii temp.sh
    .\msys\bin\bash -l -c "$current_posix/temp.sh"
    # Do the installations one at a time, pacman on msys2 tends to flake out
    # for some forking reason. A new bash helps.
    .\msys\bin\bash -l -c "pacman -Syu --noconfirm"
    .\msys\bin\bash -l -c "pacman -S --noconfirm git"
    .\msys\bin\bash -l -c "pacman -S --noconfirm tar"
    .\msys\bin\bash -l -c "pacman -S --noconfirm gzip"
    .\msys\bin\bash -l -c "pacman -S --noconfirm binutils"
    .\msys\bin\bash -l -c "pacman -S --noconfirm autoconf"
    .\msys\bin\bash -l -c "pacman -S --noconfirm make"
    .\msys\bin\bash -l -c "pacman -S --noconfirm libtool"
    .\msys\bin\bash -l -c "pacman -S --noconfirm automake"
    .\msys\bin\bash -l -c "pacman -S --noconfirm xz"
    if ($msys -eq 32) {
        .\msys\bin\bash -l -c "pacman -S --noconfirm mingw-w64-i686-gcc"
    } else {
        .\msys\bin\bash -l -c "pacman -S --noconfirm mingw-w64-x86_64-gcc"
    }
    .\msys\bin\bash -l -c "cp $current_posix/downloads/cabal.exe ~/bin"
    $ghc_cmds=@"
    ~/bin/cabal update
    git clone git://github.com/idris-lang/Idris-dev idris
    cd idris
    export CC=gcc
    ~/bin/cabal install
"@
    echo $ghc_cmds | Out-File -Encoding ascii idris.sh
    .\msys\bin\bash -l -e -c "$current_posix/idris.sh"
}

create-dirs
echo "Getting 7-zip"
install-7zip
if($msys -eq 32) {
    echo "Getting msys32"
    install-msys32
    echo "Getting bootstrap GHC 32-bit"
    install-ghc32
} else {
    echo "Getting msys64"
    install-msys64
    echo "Getting bootstrap GHC 64-bit"
    install-ghc64
}
echo "Getting cabal.exe"
download-cabal
echo "Starting msys configuration"
run-msys-installscripts
