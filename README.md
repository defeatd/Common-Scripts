## 这是我自己初始化VPS的一些命令，懒得一行一行敲，直接一键执行
### 只支持 Debian/Ubuntu 系统
## 初始化
```bash
sudo apt update && sudo apt install wget -y && wget https://raw.githubusercontent.com/defeatd/Common-Scripts/main/setup.sh && sudo bash setup.sh
```
## 一键配置2GB swap
```bash
sudo apt update && sudo apt install wget -y && wget https://github.com/defeatd/Common-Scripts/raw/refs/heads/main/setup_swap.sh && sudo bash setup_swap.sh
```
