# Assets

App 图标源文件放这里。

- `AppIconSource.png` — App 图标源图（建议 1024×1024 正方形 PNG）。
  打包脚本会用 `sips` + `iconutil` 从这张图生成 `AppIcon.icns`。

首次打包时，如果仓库里还没有 `AppIconSource.png`，脚本会：

1. 优先使用命令行参数指定的图标路径；
2. 否则使用默认路径 `~/Downloads/ChatGPT Image 2026年6月13日 14_11_45.png`；
3. 并自动把它复制成 `Assets/AppIconSource.png`，方便以后复现。

手动指定图标：

```bash
./scripts/package_app.sh /path/to/your-icon.png
```
