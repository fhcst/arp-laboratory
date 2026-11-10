# 開發與發布

## 修改容器

公開 attacker 映像預裝 MIT 授權的 VSCodium，並用專案的 `code` 啟動指令開啟。Microsoft 官方 VS Code 成品使用獨立的再散布條款。

[VSCodium 授權說明](https://vscodium.com/) · [VS Code 授權](https://code.visualstudio.com/license)

五個映像的來源分別在 `containers/router/`、`containers/access/`、`containers/server/`、`containers/victim/` 與 `containers/attack/`。

預設 Compose 使用 GHCR 映像。修改程式後，以單組本機建置 override 啟動。

```bash
docker compose -f compose.yaml -f compose.build.yaml up -d --build
docker compose -f compose.yaml -f compose.build.yaml logs --tail 10 g01-victim
docker compose -f compose.yaml -f compose.build.yaml down
```

這個 override 將 g01 的五個映像改為 `arp-laboratory-<元件>:local`，並指定本機 build context。若已啟用其他組，那些組會繼續使用共用設定指定的 GHCR 映像。修改 router 程式也需要重新建置 router 映像。

`python3 scripts/validate-project.py` 會用範例環境值檢查預設模式、本機建置模式、雙組網路與埠的獨立性，以及手冊連結、PDF 和 Markdown ZIP。

## GitHub Actions

`.github/workflows/images.yml` 會先檢查設定與教材，再在原生 amd64 與 arm64 runner 建置五個映像，實際啟動 lab，檢查下列功能。

- victim 完成 HTTP 登入與面板操作循環。
- Python、Scapy、Firefox 與 noVNC 入口可用。
- SIGUSR1 另開新錄製檔，router 的啟動時間、MAC 與 nftables 規則維持一致。
- router 正常停止後，主機上的 PCAP 仍可解析出 victim 的登入表單。

Pull Request 執行建置與檢查。`main` 的推送與手動執行成功後，先推送各架構映像，再組合多架構的 `latest` 和 `sha-<完整提交值>`。映像標籤可直接指定給 `LAB_IMAGE_TAG`。

工作流程使用 repo 的 `GITHUB_TOKEN` 與 `packages: write` 發布，並透過 `org.opencontainers.image.source` 標籤連結來源 repo。Fork 後自行發布時，調整 Dockerfile、Bake 的 source 標籤和預設 `LAB_IMAGE_PREFIX`。

首次建立 GHCR 套件後，維護者需在每個套件的設定中將可見性設為 Public，並確認匿名下載成功。套件的存取權限與來源 repo 連結，和套件本身的公開可見性是分開的設定。

[GitHub Container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

## 教材檔案

`docs/handouts/` 收錄兩份 Markdown 原稿、兩份 PDF、共用的 `handout-images/` 與各平台的 Markdown ZIP。修改教學步驟時，請同步所有格式。

更新 PDF 時，保留每份 10 頁的封面、目錄、操作頁面與頁碼。重新產生 ZIP 時，放入該份 Markdown 和它實際引用的圖片。檢查 PDF 裡的新路徑、命令與圖說，也在實際頁面尺寸確認文字和截圖可讀。

歷史版本從 Git 提交記錄取得。實驗產生的 PCAP 留在 `captures/`，該目錄已排除版本控制。
