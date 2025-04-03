# 覆盖率工具

此目录包含与代码覆盖率分析相关的工具和输出文件。

## 文件结构

- `analyze_coverage.py` - 分析覆盖率数据并生成报告的 Python 脚本
- `output/` - 包含所有生成的输出文件
  - `coverage_report.md` - Markdown 格式的覆盖率报告
  - `coverage_value.txt` - 用于 CI 的覆盖率数值
  - `coverage.json` - Tinymist 生成的原始覆盖率数据

## 使用方法

1. 运行 Tinymist 生成覆盖率数据：

   ```bash
   tinymist cov README.typ
   ```

2. 分析覆盖率并生成报告：

   ```bash
   python3 coverage/analyze_coverage.py
   ```

## 自动化

本项目的 GitHub Actions 工作流程配置为自动运行覆盖率分析并更新徽章。
详细信息请参阅 `.github/workflows/coverage.yml`
