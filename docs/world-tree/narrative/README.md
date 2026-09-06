# 《世界树》游戏内文本归档

> 本目录是游戏内已产出叙事文本的正式资料库：所有文本一字不改照抄自源码，仅做抽取、组织、标注。
> 供后续写作（延续暗线、补写事件、审查文风）与代码实现引用。
> 归档日期：2026-09-05

## 文档清单

| 文件 | 系统 | 条目数 | 源码位置 |
| --- | --- | --- | --- |
| [01-relics.md](01-relics.md) | 遗迹碎片 | 9 篇（4 处基础遗迹 + 5 处隐藏遗迹） | `features/dreams/relic_library.gd` |
| [02-totems.md](02-totems.md) | 图腾五幅 | 5 幅（含解读文本） | `features/memories/totem_library.gd` |
| [03-plunder.md](03-plunder.md) | 夺梦文本 | 3 族信号池 ×3 + 揭示 ×3（石裔无梦 1 条） | `features/memories/plunder_data.gd` |
| [04-race-awakenings.md](04-race-awakenings.md) | 四族唤醒 | 4 篇 | `features/races/data/*.tres` |
| [05-relations.md](05-relations.md) | 关系仪式互动 | 4 篇 | `features/relations/relation_events.gd` |
| [06-intimate.md](06-intimate.md) | 亲密事件 | 4 篇（树以人形对坐） | `features/memories/intimate_events.gd` |
| [07-avatar-tiers.md](07-avatar-tiers.md) | 化身观感 | 4 档（漂移镜子） | `features/memories/avatar_tiers.gd` |
| [08-choices.md](08-choices.md) | 明选全文 | 6 组 8 卡 | `features/choices/data/choices.json` |
| [09-ui-broadcast.md](09-ui-broadcast.md) | UI 叙事播报 | 固定文案（含说书人/离线摘要） | `features/ui/main.gd` |
| [10-storyteller.md](10-storyteller.md) | 说书人故事 | 主线故事④—⑥ + 彩蛋 | `features/narrative/story_library.gd` |
| [11-ending-return.md](11-ending-return.md) | 归还序列 | 21 段（7 步 × 3 周目）+ 3 段停步 | `features/ending/return_sequence.gd` |

## 引用约定

写作或讨论中引用游戏内文本时，使用锚点定位，格式：

```
见 narrative/02-totems.md 图腾·第三幅
见 narrative/08-choices.md 明选·奥丁之祭 选项a「折断一根根须」
```

引用正文时须逐字照抄（含换行断句、标点、引号），不得转写为散文。

## 文风六则速查（铁律 5）

1. **短句呼吸**：长句拆短，一段 2-4 行，像诗行。一句一意，不多不少。
2. **意象代替说明**：不说"它很悲伤"，写"它的影子，比白天长"。
3. **留白不写尽**：最痛的句子，写到一半停笔——读者自己补完。
4. **柔和如风**：残酷的事用温柔的笔。"吞噬"是"把一切都拢进怀里，直到怀里空了"。
5. **自然词汇**：露、光、土、风、河、火、灰、种子——拒绝抽象词与形容词堆砌。
6. **人称柔软**：树的心语用"你"对自己低语，不用激烈的感叹。

## 归档约定

- 原文逐字照抄：含换行、标点、中英文引号、破折号；诗行式短句**逐行保留换行**。
- 「文风注」仅在代表性条目出现，标注意象技法与暗线，不做质量评判。
- 「触发条件」「后果数值」「flag」等标注来自配套逻辑代码（`features/*/actions.gd`、`choice_actions.gd`），非原文，仅供上下文理解。
- 标注的数值/阈值以归档当日源码为准；后续改动请同步更新本文档。
