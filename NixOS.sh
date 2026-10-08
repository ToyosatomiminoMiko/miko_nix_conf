# 查看源列表 系统
sudo nix-channel --list
# 查看源列表 用户
nix-channel --list
# 看最终生效的 Nix 配置
nix config show --extra-experimental-features nix-command | grep -E 'substituters|trusted-public-keys'

# 移除源
sudo nix-channel --remove [nixpkgs]
# 添加源(unstable为滚动)
sudo nix-channel --add https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixpkgs-unstable nixpkgs
# 更新索引
sudo nix-channel --update
# 查看nixos版本
nixos-version
# 频道更新后执行重建 显示详细
sudo nixos-rebuild switch --show-trace
# 更新记录
sudo nixos-rebuild list-generations


# 回滚
sudo nixos-rebuild switch --rollback


systemd-run --version
# 2026.10.04 官方逃生开关
sudo NIXOS_REBUILD_NO_SYSTEMD_RUN=1 nixos-rebuild switch


# 升级系统
sudo nixos-rebuild switch --upgrade
# 或
sudo nix-channel --update
sudo nixos-rebuild switch

