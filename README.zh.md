# 维多利亚州公共交通 (PTV) 分析器

[![R Shiny](https://img.shields.io/badge/Dashboard-R%20Shiny-blue.svg)](https://zyyin1.shinyapps.io/ptv_analyzer/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个交互式数据可视化项目，用于分析墨尔本大都会铁路网络的通勤趋势、车站拥挤程度和网络鲁棒性。

---

### 🔗 快速链接

* 🌐 **在线网站:** [PTV Analyzer Dashboard](https://zyyin1.shinyapps.io/ptv_analyzer/)
* 📄 **英文版 README:** [README.md](README.md)
* 📜 **DEP 提案 (Proposal):** [DEP_Proposal_Version2.pdf](report/DEP_Proposal_Version2.pdf)
* 📊 **DEP 报告 (Report):** [DEP_Report.pdf](report/DEP_Report.pdf)

---

## 📖 项目概述

本仓库包含 **PTV Analyzer** 的完整源代码和文档，这是莫纳什大学 (Monash University) FIT5147 单元的一个项目。该项目分为两个阶段：

1.  **数据探索项目 (DEP):** 一个全面的统计分析项目，旨在回答关于列车频率、客流波动和车站拥挤量化的核心研究问题。相关发现已记录在 [DEP Report](report/DEP_Report.pdf) 中。
2.  **数据可视化项目 (DVP):** 一个基于 DEP 研究结果构建的交互式 R Shiny Web 应用程序。它将静态的洞察转化为探索性仪表盘，允许交通规划者和普通用户通过“故事模式”和“探索模式”与数据进行交互。

### 主要研究问题
本项目解决了两个主要问题：
1.  **供给与需求:** 列车服务频率和乘客数量如何随时间段（以及天气条件）波动？
2.  **车站拥挤:** 我们如何量化车站拥挤程度（通过自定义的 *车站拥挤指数 SCI*），以及哪些车站受时间段和基础设施等因素的影响最大？

---

## 📈 主要发现 (DEP)

基于 *数据探索项目* 中进行的统计分析，我们发现了关于墨尔本铁路网络的几个关键洞察：

* **供需不匹配:** 虽然主干线路（如 Pakenham, Lilydale）在早高峰 (07:00–09:00) 和晚高峰期间面临严重的运力短缺，但像 **Alamein** 这样的支线在非高峰时段的中午显示出显著的供给过剩，突显了调度效率低下的问题。
* **客流驱动因素:** 机器学习建模（随机森林）显示，**列车频率 (Train Frequency)** 是客流量的主导预测因子。与普遍看法相反，天气因素（降雨、气温）对客流量的影响微乎其微，而 **太阳辐射**（作为一天中时间的代理变量）排名第二。
* **"城市环线 (City Loop)" 瓶颈:** 使用自定义的 *车站拥挤指数 (SCI)* 分析发现，City Loop 车站（Flinders St, Southern Cross）的拥挤得分接近最大值。然而，成因有所不同：Flinders Street 主要由 **客流量** 驱动，而 Southern Cross 主要由 **服务频率强度** 驱动。
* **时间偏移:** 工作日的拥挤高峰出现在 16:00–20:00。值得注意的是，周末和公共假期的出行高峰时间显著推迟，且公共假期的交通量平均仅为正常工作日的 **60%**。

---

## 🖥️ 仪表盘功能 (DVP)

R Shiny 仪表盘将上述发现转化为交互式体验，具有两种独特的交互模式：用于引导叙事的 **“故事模式 (Story Mode)”** 和用于自由分析的 **“探索模式 (Exploration Mode)”**。

### 🔍 核心功能:
* **交互式供需分析:** 用户可以将列车频率密度与乘客上车密度叠加，直观地识别不同线路和日期类型的服务缺口（页面 1.2）。
* **车站拥挤热力图:** 网络中 *车站拥挤指数 (SCI)* 的地理空间可视化。包含一个 **动画小时滑块**，用于观察拥挤热点如何在一天中从郊区向市中心迁移（页面 2.4）。
* **网络鲁棒性模拟器:** 一个交互式网络图，允许用户模拟“车站故障”（节点移除）。它通过计算实时指标（如平均路径长度、直径）来测试系统应对基础设施中断的弹性（页面 2.5）。
* **城市环线客流可视化:** 一个交互式 **和弦图 (Chord Diagram)**，绘制了六个核心 City Loop 车站之间的定向客流，突出了源自 Flinders Street 的出站流量的主导地位（页面 2.2）。
* **预测模型演练场:** 允许用户在随机森林、决策树和线性回归模型之间切换，查看不同算法如何对客流预测的特征重要性进行排序（页面 1.3）。

---

## 📂 项目结构

以下是仓库的文件结构。

```text
2025-03-PTV-Analyzer-Website
├─ data                      # 网站使用的数据 (优化过的/RDS格式)
│  ├─ page_1.1_exploration_mode.rds
│  ├─ page_1.1_story_mode.rds
│  ├─ page_1.2_explore_public.rds
│  ├─ page_1.2_explore_school.rds
│  ├─ page_1.2_explore_weekday.rds
│  ├─ page_1.2_explore_weekend.rds
│  ├─ page_1.2_story_mode.rds
│  ├─ page_1.3_dt_importance.rds
│  ├─ page_1.3_lasso_importance.rds
│  ├─ page_1.3_lm_importance.rds
│  ├─ page_1.3_story_mode.rds
│  ├─ page_2.1_exploration_mode.csv
│  ├─ page_2.1_story1.csv
│  ├─ page_2.1_story2.csv
│  ├─ page_2.1_story3_story4.csv
│  ├─ page_2.2_cityloop_od_matrix.csv
│  ├─ page_2.3_2.4_station_stats.geojson
│  ├─ page_2.4_explore_mode_precomputed.rds
│  ├─ page_2.4_station_stats_with_station_type.geojson
│  ├─ page_2.4_train_lines_reference.geojson
│  ├─ page_2.4_train_line_labels.rds
│  └─ page_2.5_filtered_edges.csv
├─ draft
│  ├─ DEP_Draft_Code.Rmd     # 生成 DEP 报告中图表的草稿代码
│  └─ DVP_Draft_Code.Rmd     # 生成 DVP 网站中图表的草稿代码
├─ plot                      # DEP 报告中使用的静态图表
│  ├─ figure_1_1.png
│  ├─ ...
│  └─ figure_2_3.png
├─ LICENSE                   # MIT 许可证
├─ README.md                 # 项目文档 (英文版)
├─ README.zh.md              # 项目文档 (中文版)
├─ report
│  ├─ DEP_Proposal_Version1.pdf    # 初版 DEP 提案
│  ├─ DEP_Proposal_Version2.pdf    # 最终版 DEP 提案 (当前版本)
│  ├─ DEP_Report.pdf               # 完整的数据探索项目报告 (DEP Report)
│  ├─ DVP_Presentation.pdf         # 用于 DVP 设计过程的 "Five Design Sheet"
│  └─ DVP_Report.pdf               # 数据可视化项目报告 (DVP Report)
├─ rsconnect                       # shinyapps.io 的部署配置
│  └─ shinyapps.io
│     └─ zyyin1
│       └─ ptv_analyzer.dcf
├─ global.R                  # 全局配置和库导入
├─ server.R                  # Shiny Server 逻辑 (后端)
├─ ui.R                      # Shiny UI 布局 (前端)  
└─ www                       # 静态资源 (图片, 预生成的图表)
   ├─ img1.jpg                
   ├─ ...
   └─ radar_png              # 用于 Leaflet 工具提示的预生成雷达图
      ├─ Aircraft.png
      ├─ ... (包含所有车站的图片)
      └─ Yarraville.png
```

---

## 🛠️ R 环境与显示建议

此 R Shiny 应用程序是在以下环境中开发和测试的：

* **开发环境:** RStudio 2025.05.0+496 with R 4.4.3
* **测试环境:** MoVE 平台 (RStudio 2024.12.1+563 with R 4.4.2)

安装所有必需的包后，该应用程序在两个环境中均能正确运行。但请注意，某些视觉元素（特别是字体和布局渲染）在 MoVE 平台上可能略有不同。

为了确保最佳的观看和性能体验，请遵循以下建议：

1.  尽可能**在本地运行应用程序**。
2.  使用 **RStudio 2025.05.0+496** 和 **R 4.4.3**。
3.  在运行应用程序之前，请安装所有必需的包。RStudio 会自动提示安装 CRAN 包。
    包 `chorddiag` 和 `ggradar` **不在 CRAN 上**，必须手动安装（见下文）。
4.  应用程序运行后，请在 **Edge 或 Chrome** 中查看，并将浏览器缩放级别设置为 **100%** 以获得正确的布局渲染。
5.  *希望你喜欢。*

---

## 📦 特殊包安装说明

本项目使用了两个 **CRAN 上不可用** 的 R 包：

* [`chorddiag`](https://github.com/mattflor/chorddiag): 用于交互式和弦图 (页面 2.2)。
* [`ggradar`](https://github.com/ricardo-bion/ggradar): 用于基于 `ggplot2` 构建的雷达图 (页面 2.3 & 2.4)。

在运行应用程序之前，必须从 GitHub 安装这些包。

### 分步安装

你需要 `remotes` 包来从 GitHub 安装包：

```r
install.packages("remotes")
```

然后安装这两个包：

```r
# 从 GitHub 安装 chorddiag
remotes::install_github("mattflor/chorddiag")

# 从 GitHub 安装 ggradar
remotes::install_github("ricardo-bion/ggradar")
```

---

## 📊 数据来源

本项目使用了来自 **维多利亚州政府开放数据门户 (Victorian Government Open Data Portal)** 和 **Data Vic** 的四个主要数据集。

### 1. [Train Service Passenger Counts (FY July 2023–June 2024)](https://opendata.transport.vic.gov.au/dataset/train-service-passenger-counts)
* **描述:** 这是一个表格数据集（CSV 格式），包含墨尔本铁路服务的估计乘客上下车计数。该数据集有 1560 万行和 21 列，包括业务日期、日期类型（如工作日、公共假期）、线路名称、方向（往/返 Flinders Street）以及聚合的乘客计数（如上车人数、下车人数）等属性。
* **用途:** 空间属性（如车站坐标）和时间粒度（小时级间隔）使得分析客流趋势和特定车站的模式成为可能。该数据集用于回答 **问题 1 和 2**。

### 2. [Argyle Square Weather Stations Historical Data (May 2021–July 2024)](https://discover.data.vic.gov.au/dataset/argyle-square-weather-stations-historical-data)
* **描述:** 这是一个表格数据集（CSV 格式），包含 138,538 行每小时的天气观测数据。关键变量包括降水量、风速、气温和相对湿度。
* **用途:** 这些变量与客流数据合并，以评估天气的影响。结合数据源 A，该数据集有助于回答 **问题 1**（关于外部因素）。

### 3. [Public Transport Stops (November 2024)](https://opendata.transport.vic.gov.au/dataset/public-transport-lines-and-stops)
* **描述:** 这是一个空间数据集（GeoJSON 格式），提供了维多利亚州 28,323 个公共交通站点（包括墨尔本铁路网络）的地理坐标和元数据。属性包括站点 ID、站点名称和模式（如 Metro Train, Regional Train）。
* **用途:** 它支持绘制车站位置，并为可视化整合乘客数据的空间背景。

### 4. [Public Transport Lines (November 2024)](https://opendata.transport.vic.gov.au/dataset/public-transport-lines-and-stops)
* **描述:** 另一个空间数据集（GeoJSON 格式），详细描述了 9,776 条公共交通路线，包括铁路线。线路名称、车头牌（目的地）和模式等属性有助于分析服务覆盖范围和连通性。
* **用途:** 它补充了站点数据集，以便在空间上通过网络背景化乘客流。

---

## 👤 作者

**Zihan Yin**
* Monash University
* **项目指导:** Shivangi Gheewala & Michael Niemann

_本项目仅用于莫纳什大学 FIT5147 单元的教学目的。_