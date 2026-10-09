let
    # 现状:固定在 nixpkgs 151fa4e8(nixos-unstable 26.11pre1086391)。带 sha256 就是固定的 store 路径,
    #       首次取回后不会再联网;原先直接指 unstable channel,nix 一旦过了 tarball TTL 就会整包重下 nixexprs。
    nixpkgs = fetchTarball {
        url = "https://codeload.github.com/NixOS/nixpkgs/tar.gz/151fa4e8ddfdd8dd25d945ad94ed54a13de9f6e4";
        sha256 = "0rm5v6n0kgqq5xrc34imn8nxx0y2xlmhpa0nag9sk6m6ys9slaij";
    };
    pkgs = import nixpkgs {};

    # 现状:MC 26.4 的 version json 要求 javaVersion.majorVersion >= 25,nixpkgs 的 openjdk 只到 25,
    #       故锁 Adoptium 的 temurin-bin-27(27.0.0);要降级只改这一行:27 / 26 / 25。
    jdk = pkgs.temurin-bin-27;

    # 现状:JavaFX 的 libglassgtk3.so 和 MC 的 libopenal.so 都要这些系统库。
    #       缺 GTK3/X11/GL 时 JavaFX 在开窗前崩(no glassgtk3 in java.library.path);
    #       缺 libstdc++.so.6 时 MC 在 Loading library OpenAL 处崩;
    #       MC 26 用 SDL 加载 GL,SDL 走 X11 时要能从 libGL.so.1 取到 glXGetProcAddress*,否则报
    #       "OpenGL is not supported: Could not retrieve OpenGL functions"。
    #       故意不放 vulkan-loader:这卡是 TeraScale(AMD TURKS / r600),radv 不支持,
    #       装上后 MC 会选中 Vulkan+lavapipe 软件渲染;不装则回退到 OpenGL 硬件路径。
    runtimeLibs = with pkgs; [
        stdenv.cc.cc.lib zlib
        gtk3 glib gdk-pixbuf pango cairo atk
        libGL libglvnd wayland
        libx11 libxext libxcursor libxi libxrandr libxrender libxkbcommon libxtst libxxf86vm
        alsa-lib libpulseaudio
    ];
    libsPath = pkgs.lib.makeLibraryPath runtimeLibs;

    # 现状:hmcl 是真正的 wrapper 脚本而不是 shell 函数,自己 export JAVA_HOME 和库路径,
    #       所以 HMCL 以及它拉起的游戏一定拿到正确的 LD_LIBRARY_PATH,不依赖外层 shell 的环境;
    #       每次启动把环境快照追加到 ~/minecraft/.hmcl-env.log,方便和正常环境对比。
    hmclBin = pkgs.writeShellScriptBin "hmcl" ''
        export JAVA_HOME=${jdk}
        export LD_LIBRARY_PATH="${libsPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        {
            echo "=== $(date '+%F %T')  cwd=$PWD ==="
            ${jdk}/bin/java -version 2>&1 | head -1
            printf 'LD_LIBRARY_PATH=%s\n' "$LD_LIBRARY_PATH"
        } >> "$HOME/minecraft/.hmcl-env.log" 2>&1
        exec ${jdk}/bin/java -Djdk.gtk.version=3 -jar "$PWD/HMCL-3.17.0.359.jar" "$@"
    '';
in
pkgs.mkShell {
    packages = [
        jdk
        pkgs.unzip
        hmclBin
    ];

    buildInputs = runtimeLibs;

    shellHook = ''
        export JAVA_HOME=${jdk}
        export PATH="$JAVA_HOME/bin:$PATH"
        export LD_LIBRARY_PATH="${libsPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        # 清掉旧 nix-shell 里 export -f 出去的 hmcl 函数,否则会盖住上面的 wrapper 可执行文件
        unset -f hmcl 2>/dev/null || true
        echo "java: $(java -version 2>&1 | head -1)"
    '';
}
