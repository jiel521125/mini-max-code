#!/usr/bin/env bash
# uninstall.sh — 回滚安装
# 注销 hook + 删除 mavis 端的 hook 文件
# 不动项目目录本身的数据

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}==> 卸载 hook: mavis:project-bootstrap-check${NC}"

if mavis hook list 2>/dev/null | grep -q "mavis:project-bootstrap-check"; then
  if mavis hook delete mavis:project-bootstrap-check; then
    echo -e "${GREEN}  ✓ hook 已注销${NC}"
  else
    echo -e "${RED}  ✗ hook 注销失败${NC}"
    exit 1
  fi
else
  echo "  ! hook 未注册，跳过"
fi

echo ""
echo -e "${GREEN}卸载完成${NC}"
echo "项目目录数据未删除。如需完全清理：rm -rf <project_root>"
