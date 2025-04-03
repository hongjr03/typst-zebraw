import json
import os


def analyze_coverage(json_file):
    with open(json_file, "r") as f:
        coverage_data = json.load(f)

    results = {}

    for file_path, locations in coverage_data.items():
        if not locations:  # Skip empty arrays
            results[file_path] = {
                "file_name": os.path.basename(file_path),
                "executed": 0,
                "not_executed": 0,
                "total": 0,
                "coverage_percent": "0.00%",
                "coverage_value": 0.0,
            }
            continue

        executed = 0
        not_executed = 0

        for location in locations:
            if "executed" in location:
                if location["executed"]:
                    executed += 1
                else:
                    not_executed += 1

        total = executed + not_executed
        coverage_percent = (executed / total * 100) if total > 0 else 0

        file_name = os.path.basename(file_path)

        results[file_path] = {
            "file_name": file_name,
            "executed": executed,
            "not_executed": not_executed,
            "total": total,
            "coverage_percent": f"{coverage_percent:.2f}%",
            "coverage_value": coverage_percent,
        }

    return results


def print_results(results):
    print("\nCoverage Analysis Results:\n")
    print(
        f"{'File Name':<30} {'Executed':<10} {'Not Executed':<10} {'Total':<10} {'Coverage':<10}"
    )
    print("-" * 70)

    total_executed = 0
    total_not_executed = 0

    for file_path, data in results.items():
        file_name = os.path.basename(file_path)
        print(
            f"{file_name:<30} {data['executed']:<10} {data['not_executed']:<10} {data['total']:<10} {data['coverage_percent']:<10}"
        )
        total_executed += data["executed"]
        total_not_executed += data["not_executed"]

    total = total_executed + total_not_executed
    total_coverage = (total_executed / total * 100) if total > 0 else 0

    print("-" * 70)
    print(
        f"{'Total':<30} {total_executed:<10} {total_not_executed:<10} {total:<10} {f'{total_coverage:.2f}%':<10}"
    )

    return total_coverage


def generate_badge(coverage_value):
    """Generate coverage badge"""
    color = "red"
    if coverage_value >= 90:
        color = "brightgreen"
    elif coverage_value >= 80:
        color = "green"
    elif coverage_value >= 70:
        color = "yellowgreen"
    elif coverage_value >= 60:
        color = "yellow"
    elif coverage_value >= 50:
        color = "orange"

    badge_url = f"https://img.shields.io/badge/coverage-{coverage_value:.2f}%25-{color}"
    return badge_url


def generate_markdown_report(results):
    """Generate Markdown format coverage report"""
    total_executed = 0
    total_not_executed = 0

    for data in results.values():
        total_executed += data["executed"]
        total_not_executed += data["not_executed"]

    total = total_executed + total_not_executed
    total_coverage = (total_executed / total * 100) if total > 0 else 0

    markdown = f"# Tinymist Coverage Report\n\n"
    markdown += f"![Coverage](https://img.shields.io/badge/coverage-{total_coverage:.2f}%25-{get_color(total_coverage)})\n\n"
    markdown += f"## Overall Coverage: {total_coverage:.2f}%\n\n"
    markdown += f"| File | Executed | Not Executed | Total | Coverage |\n"
    markdown += f"|------|--------|--------|------|--------|\n"

    # Sort by coverage value
    sorted_results = sorted(
        results.items(), key=lambda x: x[1]["coverage_value"], reverse=True
    )

    for file_path, data in sorted_results:
        file_name = os.path.basename(file_path)
        markdown += f"| {file_name} | {data['executed']} | {data['not_executed']} | {data['total']} | {data['coverage_percent']} |\n"

    markdown += f"\n**Total:** {total_executed} executed, {total_not_executed} not executed, {total} total items\n"

    # Add last update time
    from datetime import datetime

    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    markdown += f"\n\nLast updated: {now}\n"

    return markdown, total_coverage


def get_color(coverage_value):
    """Get color based on coverage value"""
    if coverage_value >= 90:
        return "brightgreen"
    elif coverage_value >= 80:
        return "green"
    elif coverage_value >= 70:
        return "yellowgreen"
    elif coverage_value >= 60:
        return "yellow"
    elif coverage_value >= 50:
        return "orange"
    return "red"


if __name__ == "__main__":
    # 更新文件路径
    input_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")

    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)

    # 处理 coverage.json 文件
    coverage_file = os.path.join(input_dir, "target", "coverage.json")
    if os.path.exists(coverage_file):
        # 分析覆盖率数据
        results = analyze_coverage(coverage_file)
        print_results(results)

        # 将 coverage.json 复制到 output 目录
        output_json = os.path.join(output_dir, "coverage.json")
        with open(coverage_file, "r") as src, open(output_json, "w") as dst:
            dst.write(src.read())

        # 生成 Markdown 报告
        markdown_report, total_coverage = generate_markdown_report(results)

        # 保存 Markdown 报告到文件
        report_path = os.path.join(output_dir, "coverage_report.md")
        with open(report_path, "w", encoding="utf-8") as f:
            f.write(markdown_report)

        # 同时在根目录创建一个副本，用于向后兼容（后续可移除）
        with open(
            os.path.join(input_dir, "coverage_report.md"), "w", encoding="utf-8"
        ) as f:
            f.write(markdown_report)

        # 保存覆盖率值到文件
        value_path = os.path.join(output_dir, "coverage_value.txt")
        with open(value_path, "w", encoding="utf-8") as f:
            f.write(f"{total_coverage:.2f}")

        # 同时在根目录创建一个副本，用于向后兼容（后续可移除）
        with open(
            os.path.join(input_dir, "coverage_value.txt"), "w", encoding="utf-8"
        ) as f:
            f.write(f"{total_coverage:.2f}")

        print(f"\nCoverage report has been generated to {report_path}")
    else:
        print(f"Error: Coverage file {coverage_file} not found")
        exit(1)
