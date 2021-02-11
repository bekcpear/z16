#!/usr/bin/env bash
#
# author: @bekcpear
#

opencc -i README.zhs.md -o README.zht.md -c s2twp.json
sed -i 's/\[中文繁體\](README\.zht\.md)/[中文简体](README.zhs.md)/' ./README.zht.md
sed -i '/「整」專案/a\\n  *本文由 opencc 轉換得*' ./README.zht.md
