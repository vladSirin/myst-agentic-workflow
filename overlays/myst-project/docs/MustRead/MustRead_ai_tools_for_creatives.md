# AI Tools Guide for Designers & Artists 设计师与美术人员AI工具指南

**Last Updated**: 2026-05-19

> **谁需要读这份文档？**
> 任何使用AI助手进行日常工作的团队成员——关卡设计师、美术、动画师、TA、LD。
> 你不需要懂代码。这份指南用最直白的方式讲清楚工具能做什么、不能做什么。

---

# English

## What Are These AI Tools?

This project has AI assistants built into it. Think of them as a very capable
junior team member who can:

- Find files and information in the project (instead of asking around)
- Create and edit simple scripts and configuration files
- Answer questions about how the project works
- Follow documented procedures (like Perforce submission steps)

These tools work in your terminal or editor. You talk to them in plain English.

There are two supported tools — you only need one:

| Tool | Where it runs | You activate it by |
|------|--------------|-------------------|
| **Claude Code** | VS Code, terminal, or desktop app | Typing questions or commands |
| **Codex** | VS Code extension | Typing questions or commands |

## What Can You Ask Them to Do?

### Finding things

> "Where is the material for the metal floor in GYM_Lookdev?"

> "Show me all the Blueprints that use the BP_FPCharacter class."

> "What does the MystReachTrigger do?"

### Understanding how things work

> "How does the damage system work in this project?"

> "Explain the Actor/Script/Director pattern we use."

> "What GameplayTags do we have for movement?"

### Following procedures

> "I have a new asset. Walk me through the Perforce submission steps."

> "What naming convention should I use for a new weapon Blueprint?"

> "Create a new CL for my level changes."

### Simple file edits (basic scripting tasks)

> "Create a new AngelScript trigger that prints a message when the player enters
> a zone."

> "Add a new item type to the inventory."

> "Change the damage value on the enemy weapon from 10 to 15."

## What Can They NOT Do?

These tools cannot:

- **Open the Unreal Editor.** They work with files on disk, not the running
  editor. If you need to place an actor in a level, you still do that yourself.
- **See the game running.** They cannot play the game and watch what happens.
  You need to describe what you saw.
- **Create .uasset files from scratch.** They can read references to assets
  but they cannot make a new Blueprint, Material, or Texture for you.
- **Know what happened in a PIE session** unless you tell them.

## Golden Rules (Please Read)

### DO

1. **Describe what you want in plain language.** You do not need to know
   technical terms. "I want a thing that prints hello when the player walks
   into a room" is fine.
2. **Mention specific files or assets if you know them.** "In GYM_Mission.umap,
   the red door near spawn..." helps a lot.
3. **Ask the AI to explain what it did.** If it made a change, you can ask
   "show me what you changed and why."
4. **Verify in the editor.** After the AI makes a file change, check the
   Output Log and test in PIE before submitting.

### DO NOT

1. **Do not edit AI-generated configuration files by hand unless you know
   which parts are safe.** Some files (especially `.claude/` and `.Codex/`
   settings) are managed by the tool. If you edit them and break
   something, tell a technical team member.
2. **Do not delete `.claude/` or `.Codex/` folders.** They
   contain the AI's instructions. Deleting them disables the AI until someone
   restores them.
3. **Do not submit AI agent settings to Perforce.** Files named
   `settings.json`, `settings.local.json`, or `scheduled_tasks.lock` are
   per-user and should not be checked in. They are already in `.p4ignore` but
   always double-check your changelist before submitting.

## Common Tasks — Step By Step

### Task 1: Find out how an existing system works

```
1. Open the AI assistant in your editor.
2. Type: "How does the MystReachTrigger work? Show me the script and explain it."
3. The AI will find the file and walk through it.
4. Ask follow-up questions: "What happens when the player leaves the trigger?"
```

### Task 2: Make a simple change to an AngelScript file

```
1. Tell the AI: "In Script/Triggers/MystReachTrigger.as, change the message
   that prints when the player enters from 'Trigger Activated' to 'Zone Entered'."
2. The AI will make the edit and show you what changed.
3. Save the file (Angelscript hot-reloads automatically in the editor).
4. Test in PIE to confirm it works.
5. Ask the AI: "Create a Perforce changelist for this change."
```

### Task 3: Create a new changelist for your work

```
1. Tell the AI: "I've modified three files for the new level. Create a CL
   named 'New_Myst_Level_WIP' with a description."
2. The AI will check what files are open in Perforce and create the CL.
3. Review the CL description to make sure it's accurate.
4. Do NOT submit yet — ask the AI "review and submit" when you're ready.
```

## When Things Go Wrong

| Problem | What to do |
|---------|-----------|
| AI gives an error | Copy the error message and paste it to the AI. Say "I got this error, what does it mean?" |
| AI changed the wrong file | Tell the AI: "No, that's the wrong file. Revert that change. I meant [filename]." |
| AI does not understand your request | Rephrase with more detail. Mention the file name, asset name, or level name. |
| Something is broken after an AI change | Tell the AI: "Something broke after the last change. The error is [message]." |
| You are stuck | Ping `#dev-chat` in Slack or ask a technical team member. Link to this guide. |

## Which Tool Should I Use?

If you are new: ask a team member which tool is set up on your machine.

- **Claude Code** is the most full-featured. It is installed via the VS Code
  extension or the terminal CLI.
- **Codex** runs in VS Code. Good for quick questions.

Both tools share the same workflows and instructions. You cannot break anything
by switching between them.

## Getting Help

This guide lives in: `Docs/MustRead/MustRead_ai_tools_for_creatives.md`

Additional resources:
- Agentic workflow overview: `Docs/MustRead/MustRead_agentic_workflow.md`
- Project architecture: `Myst_Proto/CLAUDE.md`
- Asset naming: `StyleGuide.md`

For technical questions about the AI setup: ask the project lead or check
`Docs/agents/` documentation.

---

---

# 中文

## 这些AI工具是什么？

本项目内置了AI助手。可以把它理解成一个非常能干的新人同事，可以帮你：

- 在项目中查找文件和资料（不用再去问人了）
- 创建和编辑简单脚本和配置文件
- 解答项目运作方式的问题
- 按照文档流程操作（比如提交Perforce的步骤）

这些工具在你的编辑器或命令行终端里运行。你用日常中文和它交流就行。

目前支持两种工具，你只需要用一个：

| 工具 | 在哪运行 | 怎么启动 |
|------|---------|---------|
| **Claude Code** | VS Code、终端或桌面应用 | 打字提问或输入命令 |
| **Codex** | VS Code插件 | 打字提问或输入命令 |

## 可以帮做什么？

### 查找资料

> "GYM_Lookdev里那个金属地板用的是什么材质？"

> "列出所有用了BP_FPCharacter的蓝图。"

> "MystReachTrigger是干什么的？"

### 理解系统

> "这个项目的伤害系统是怎么运作的？"

> "解释一下我们用的Actor/Script/Director模式。"

> "我们有哪些移动相关的GameplayTag？"

### 按照流程操作

> "我有一个新资产，帮我走一遍Perforce提交流程。"

> "新武器蓝图该用什么命名规则？"

> "给我关卡改动新建一个CL。"

### 简单的文件修改

> "创建一个AngelScript触发器，玩家进入某个区域时打印一条消息。"

> "给物品栏新增一个物品类型。"

> "把敌人武器的伤害从10改成15。"

## 不能做什么？

这些工具做不到：

- **打开虚幻编辑器。** 它们操作磁盘上的文件，不能操作运行中的编辑器。
  如果你需要在关卡里摆东西，还是得自己动手。
- **看到游戏运行画面。** 它们不能玩游戏然后观察发生了什么。
  你需要描述你看到的现象。
- **从零创建 .uasset 文件。** 它们能看懂资产引用，但不能帮你新建蓝图、材质、
  贴图。
- **知道PIE里发生了什么**，除非你告诉它。

## 黄金法则

### 要做

1. **用日常语言描述你要什么。** 不需要懂技术术语。
   "我想做一个玩家走进房间时打印hello的东西"是可以的。
2. **如果你知道具体文件或资产名，说出来。** "在GYM_Mission.umap里，
   出生点旁边的红色门..." 这样会准很多。
3. **让AI解释它做了什么。** 改完之后可以问"给我看看改了什么以及为什么"。
4. **在编辑器里验证。** AI改完文件后，检查Output Log，进PIE测试，确认没问题
   再提交。

### 不要做

1. **不要手动编辑AI生成/管理的配置文件**（除非你确定哪些部分是安全的）。
   尤其是`.claude/`、`.Codex/`里的设置文件。
   不小心改坏了就找技术人员帮忙。
2. **不要删除`.claude/`、`.Codex/`文件夹。**
   那里面有AI的工作指令，删掉AI就废了。
3. **不要把AI的本地设置文件提交到Perforce。**
   `settings.json`、`settings.local.json`、`scheduled_tasks.lock`这类文件是
   每个人自己用的，不应入库。它们已经被`.p4ignore`排除了，但提交之前还是
   过一次CL确认一下。

## 常见任务步骤

### 任务1：搞清楚某个系统怎么运作

```
1. 在编辑器里打开AI助手。
2. 输入："MystReachTrigger是怎么工作的？给我看脚本并解释一下。"
3. AI会找到文件并讲解。
4. 你可以追问："玩家离开触发器时会发生什么？"
```

### 任务2：简单修改一个AngelScript文件

```
1. 告诉AI："在Script/Triggers/MystReachTrigger.as里，把玩家进入时打印的消息
   从'Trigger Activated'改成'Zone Entered'。"
2. AI会做修改并显示改了什么。
3. 保存文件（AngelScript在编辑器里会自动热重载）。
4. 进PIE测试确认。
5. 告诉AI："给这个改动建一个Perforce changelist。"
```

### 任务3：给你的工作创建CL

```
1. 告诉AI："我改了三个文件，是给新关卡用的。建一个叫'New_Myst_Level_WIP'的CL
   并写好描述。"
2. AI会检查Perforce里哪些文件已打开，然后创建CL。
3. 审核CL描述是否准确。
4. 不要马上提交——准备好后告诉AI"review and submit"。
```

## 出问题了怎么办

| 问题 | 应对 |
|------|------|
| AI报错了 | 把报错消息复制粘贴给AI，说"我遇到这个错误，什么意思？" |
| AI改错了文件 | 说："不对，改错文件了。把那个改动撤回。我说的是[文件名]。" |
| AI听不懂你的要求 | 换个说法，多给细节。提到文件名、资产名、关卡名。 |
| AI改完之后东西坏了 | 说："上次改完之后出问题了。报错是[写出来]。" |
| 卡住了 | 在Slack的`#dev-chat`频道问一下，或者找技术人员。附上本指南的链接。 |

## 我该用哪个工具？

新人的话：问同事你电脑上装了哪个。

- **Claude Code**功能最全。装VS Code插件或命令行工具即可使用。
- **Codex**在VS Code里运行，适合快速提问。

两个工具共享同一套工作流程和指令。来回切换不会搞坏任何东西。

## 获取帮助

本指南位置：`Docs/MustRead/MustRead_ai_tools_for_creatives.md`

其他资源：
- 完整工作流程概览：`Docs/MustRead/MustRead_agentic_workflow.md`
- 项目架构文档：`Myst_Proto/CLAUDE.md`
- 资产命名规范：`StyleGuide.md`

关于AI设置的技术问题：找项目负责人或查看`Docs/agents/`目录下的文档。
