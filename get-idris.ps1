# A Powershell script for setting up an Idris build environment
# by Niklas Larsson <niklas@mm.st>
#
# This script is based on the corresponding script for GHC at
# https://github.com/melted/getghc.git
# For best results, run it in an empty directory.
#
# This file has been placed in the public domain by the author.

$current_dir = pwd
$msys = 32 # 32 to build a 32-bit Idris or 64 to build 64-bit

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
#    $url="https://www.haskell.org/ghc/dist/7.8.3/ghc-7.8.3-i386-unknown-mingw32.tar.xz"
#    $file="downloads\ghc32.tar.xz"
#    $hash="10ed53deddd356efcca4ad237bdd0e5a5102fb11"
    $url="http://www.haskell.org/ghc/dist/7.6.3/ghc-7.6.3-i386-unknown-mingw32.tar.bz2"
    $file="downloads\ghc32.tar.bz"
    $hash="8729A1D7E73D69CE6CFA6E5519D6710F53A57064"
    if(get-tarball $url $file $hash) {
        .\support\7za x -y $file
        .\support\7za x -y ghc32.tar -omsys
        rm ghc32.tar
    }
}

function install-msys32() {
    $url="http://sourceforge.net/projects/msys2/files/Base/i686/msys2-base-i686-20150202.tar.xz/download"
    $file="downloads\msys32.tar.xz"
    $hash="FBE0F1D52E26045127287C3B20AAC22422FFE0E1"
    if(get-tarball $url $file $hash) {
        .\support\7za x -y $file
        .\support\7za x -y msys32.tar
        mv msys32 msys
        rm msys32.tar
    }
}

function install-ghc64 {
    $url="https://www.haskell.org/ghc/dist/7.8.3/ghc-7.8.3-x86_64-unknown-mingw32.tar.xz"
    $file="downloads\ghc64.tar.xz"
    $hash="e18e279e98768c70839a0ef606d55cb733e362dc"

#    $url="http://www.haskell.org/ghc/dist/7.6.3/ghc-7.6.3-x86_64-unknown-mingw32.tar.bz2"
#    $file="downloads\ghc64.tar.bz2"
#    $hash="758AC43AA13474C55F7FC25B9B19E47F93FD7E99"
    if(get-tarball $url $file $hash) {
        .\support\7za x -y $file
        .\support\7za x -y ghc64.tar -omsys
        rm ghc64.tar
    }
}

function install-msys64() {
    $url="http://sourceforge.net/projects/msys2/files/Base/x86_64/msys2-base-x86_64-20150202.tar.xz/download"
    $file="downloads\msys64.tar.xz"
    $hash="D67D980A3AFDDF497A3574BB3D6C6DD688B499CA"
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
    $url=" http://www.haskell.org/cabal/release/cabal-install-1.20.0.3/cabal-1.20.0.3-i386-unknown-mingw32.tar.gz"
    $file="downloads\cabal.tar.gz"
    $hash="370590316e6433957e2673cbfda5769e4eadfd38"
    if (get-tarball $url $file $hash) {
        .\support\7za x -y $file -odownloads
        .\support\7za x -y downloads\cabal.tar -odownloads
        rm downloads\cabal.tar
    }
}

function run-msys-installscripts {
    .\msys\usr\bin\bash -l -c "exit" | Out-Null
     $current_posix=.\msys\usr\bin\cygpath.exe -u $current_dir
     $win_home = .\msys\usr\bin\cygpath.exe -u $HOME
     $cache_file = $HOME+"\AppData\roaming\cabal\packages\hackage.haskell.org\00-index.cache"
     if (Test-Path $cache_file) {
        Write-Host "Removing cabal cache"
        rm $cache_file
     }

    $bash_paths=@"
        mkdir -p ~/bin
        echo 'export MSYSTEM=$($msys)' >> ~/.bash_profile
        echo 'export LC_ALL=C' >> ~/.bash_profile
        echo 'export PATH=/ghc-7.8.3/bin:`$PATH'       >> ~/.bash_profile
        echo 'export PATH=`$HOME/bin:`$PATH'            >> ~/.bash_profile
        echo 'export PATH=/mingw$($msys)/bin:`$PATH'            >> ~/.bash_profile
        echo 'export PATH=$($win_home)/AppData/Roaming/cabal/bin:`$PATH' >> ~/.bash_profile
        echo 'export CC=gcc' >> ~/.bash_profile
"@
    echo $bash_paths | Out-File -Encoding ascii temp.sh
    .\msys\usr\bin\bash -l -c "$current_posix/temp.sh"
    # Do the installations one at a time, pacman on msys2 tends to flake out
    # for some forking reason. A new bash helps.
    .\msys\usr\bin\bash -l -c "pacman -Syu --noconfirm"
    .\msys\usr\bin\bash -l -c "pacman -S --noconfirm git"
    .\msys\usr\bin\bash -l -c "pacman -S --noconfirm tar"
    .\msys\usr\bin\bash -l -c "pacman -S --noconfirm gzip"
    .\msys\usr\bin\bash -l -c "pacman -S --noconfirm binutils"
    .\msys\usr\bin\bash -l -c "pacman -S --noconfirm autoconf"
    .\msys\usr\bin\bash -l -c "pacman -S --noconfirm make"
    .\msys\usr\bin\bash -l -c "pacman -S --noconfirm libtool"
    .\msys\usr\bin\bash -l -c "pacman -S --noconfirm automake"
    .\msys\usr\bin\bash -l -c "pacman -S --noconfirm xz"
    .\msys\usr\bin\bash -l -c "pacman -S --noconfirm msys2-w32api-runtime"
    if ($msys -eq 32) {
        .\msys\usr\bin\bash -l -c "pacman -S --noconfirm mingw-w64-i686-gcc"
        .\msys\usr\bin\bash -l -c "pacman -S --noconfirm mingw-w64-i686-pkg-config"
        .\msys\usr\bin\bash -l -c "pacman -S --noconfirm mingw-w64-i686-libffi"
    } else {
        .\msys\usr\bin\bash -l -c "pacman -S --noconfirm mingw-w64-x86_64-gcc"
        .\msys\usr\bin\bash -l -c "pacman -S --noconfirm mingw-w64-x86_64-pkg-config"
        .\msys\usr\bin\bash -l -c "pacman -S --noconfirm mingw-w64-x86_64-libffi"
    }
    .\msys\usr\bin\bash -l -c "cp $current_posix/downloads/cabal.exe ~/bin"
    $ghc_cmds=@"
    ~/bin/cabal update
    cabal install alex
    git clone git://github.com/idris-lang/Idris-dev idris
    cd idris
    export CC=gcc
    CABALFLAGS="-fffi" make
"@
    echo $ghc_cmds | Out-File -Encoding ascii idris.sh
    .\msys\usr\bin\bash -l -e -c "$current_posix/idris.sh"
}

create-dirs
echo "Getting 7-zip"
install-7zip
if($msys -eq 32) {
    echo "Getting msys64"
    install-msys64
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
