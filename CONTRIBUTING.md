# 參與貢獻

歡迎修正建置流程、容器設定、教材步驟與排版。請先搜尋既有 issue，較大的行為變更請先開 issue 說明使用情境、預期結果與影響的平台。

1. Fork 本專案，從 `main` 建立自己的分支。
2. 修改對應的 `containers/` 或 Compose 設定。單組本機建置入口為 `docker compose -f compose.yaml -f compose.build.yaml up -d --build`。
3. 執行 `python3 scripts/validate-project.py`，再依修改範圍驗證 HTTP 循環、桌面入口與 PCAP。
4. 修改學生手冊時，同步更新 Markdown、PDF 與 Markdown ZIP，保留封面、目錄和可讀的圖說。請逐頁檢查 PDF 的截圖、換行與頁碼。
5. 提交 Pull Request，說明改動、測試環境、驗證結果及尚未驗證的平台。

修改群組時，請保留每組的獨立 LAN、WAN 和管理網路。新增組別必須使用獨立的 ULA 子網、主機入口埠與抓包目錄。實驗 IPv4 依教材沿用。

PCAP、真實帳密、`.env`、SSH 私鑰和學生個資請留在本機。問題重現可附去識別化的文字紀錄與必要的畫面。

提交貢獻表示同意將程式與設定依 MIT 授權，將 `docs/` 的原創教材依 CC BY 4.0 授權。第三方素材請標示來源與授權。請遵守 [行為準則](CODE_OF_CONDUCT.md)。
