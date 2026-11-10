# 網路與群組設定

每組包含 router、server、victim、attack 與 access 五個服務。router 使用兩張網卡，所有實驗主機的預設閘道直接指向 router。

| 主機 | 介面 | IPv4 | 預設閘道 |
| --- | --- | --- | --- |
| router | lan0 | 10.0.10.254/16 | 實驗轉發規則 |
| router | wan0 | 203.72.59.254/24 | 實驗轉發規則 |
| victim | lan0 | 10.0.0.10/16 | 10.0.10.254 |
| attack | lan0 | 10.0.0.20/16 | 10.0.10.254 |
| server | wan0 | 203.72.59.10/24 | 203.72.59.254 |
| access | lan0、mgmt0 | 內網 10.0.0.30/16 | 管理網路 |

## 重複 IPv4 的隔離方式

`compose.yaml` 用 `include` 選擇組別，每組檔案用 `extends` 取得 `compose.services.yaml` 的共用設定。

每組建立獨立的 macvlan LAN、macvlan WAN 和 bridge 管理網路。Docker IPAM 分配各組獨立的 IPv6 ULA 子網，實驗所用 IPv4 由容器的啟動程式設定。不同組的 ARP 廣播與實驗 IPv4 位於各自的二層網路。

LAN 與 WAN 設定為 `internal: true`。server 的 203.72.59.10 僅用於隔離實驗，容器不會將這段實驗流量直接送往真實外部網路。access 只在管理介面監聽，並以固定的四條代理連線提供 SSH、RDP、VNC 和 noVNC。

## 增減組別

預設啟用 g01。在 `compose.yaml` 取消 `compose.g02.yaml` 的註解即可同時啟動第二組。

| 組別 | SSH | RDP | VNC | noVNC | PCAP |
| --- | ---: | ---: | ---: | ---: | --- |
| g01 | 2222 | 13389 | 15901 | 6080 | captures/g01/ |
| g02 | 2223 | 13390 | 15902 | 6081 | captures/g02/ |

新增 g03 時，複製 `compose.g02.yaml`，將 `g02` 與 `G02` 改成 `g03` 與 `G03`。將 ULA 子網 `:02a::`、`:02b::` 改為 `:03a::`、`:03b::`，並選擇未被其他組使用的四個主機埠。保留實驗 IPv4 與 gateway。

修改每組密碼後，把檔案加入根 Compose 的 `include`，先執行 `docker compose config` 再啟動。移除組別前，先用原有的 include 清單執行 `docker compose down`，使舊組別正常結束。

## 錄製生命週期

router 在 lan0 錄製 ARP 與實驗網站的 TCP/80 流量。每次開始錄製使用一份 `lan.YYYYMMDDTHHMMSSZ.pcap`，時間為 UTC，直接寫入主機的 `captures/<組名>/`。同秒重開時會等到可用的新檔名，舊檔會保留。

`docker compose kill -s SIGUSR1 g01-router` 透過 init 將 SIGUSR1 送到 router 的控制程式。程式會讓 tcpdump 正常結束，再開啟新檔。router 的網卡、轉發規則與鄰居表持續使用。

`docker compose down` 會送出停止訊號並結束錄製。PCAP 已在主機的 bind mount 目錄中，每份檔案隨錄製時間增長。

## 平台範圍

Linux 原生 rootful Docker 是 macvlan 的上游支援路徑。CI 使用 Linux amd64 與 arm64 執行建置及實際容器流程。macOS 手冊使用 Lima 的 rootful Docker VM，並把專案掛載為可寫入目錄。

本專案先前已在 Windows Docker Desktop 的 WSL 2 Linux 引擎實測。Docker 官方將 Docker Desktop 列於 macvlan 的不支援平台，桌面端的可用性仍與引擎版本及後端有關。遇到網路建立失敗時，請記錄版本與完整錯誤。

[Docker macvlan 平台說明](https://docs.docker.com/engine/network/drivers/macvlan/#platform-support-and-requirements)
