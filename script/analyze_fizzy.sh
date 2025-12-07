#!/bin/bash

# Fizzy 代码分析脚本
# 用于系统性地分析 Basecamp Fizzy 项目的代码结构和最佳实践

set -e

FIZZY_DIR="${1:-../fizzy}"
ANALYSIS_DIR="tmp/fizzy-analysis"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🔍 开始分析 Fizzy 项目..."
echo "📁 项目目录: $FIZZY_DIR"
echo "📊 分析结果目录: $ANALYSIS_DIR"

# 创建分析目录
mkdir -p "$ANALYSIS_DIR"

# 检查项目是否存在
if [ ! -d "$FIZZY_DIR" ]; then
    echo "❌ 项目目录不存在: $FIZZY_DIR"
    echo "💡 提示: 请先克隆项目: git clone https://github.com/basecamp/fizzy.git $FIZZY_DIR"
    exit 1
fi

cd "$FIZZY_DIR"

echo ""
echo "📋 1. 项目基本信息"
echo "=================="
echo "项目名称: $(basename $(pwd))"
echo "Git 仓库: $(git remote get-url origin 2>/dev/null || echo 'N/A')"
echo "当前分支: $(git branch --show-current 2>/dev/null || echo 'N/A')"
echo "最新提交: $(git log -1 --pretty=format:'%h - %s (%an, %ar)' 2>/dev/null || echo 'N/A')"

echo ""
echo "📁 2. 项目结构分析"
echo "=================="
cat > "$OLDPWD/$ANALYSIS_DIR/structure.txt" <<EOF
项目目录结构
============

$(tree -L 2 -I 'node_modules|tmp|log|storage|coverage|.git' -d 2>/dev/null || find . -maxdepth 2 -type d | grep -v node_modules | grep -v tmp | grep -v log | grep -v storage | grep -v coverage | grep -v .git | sort)

文件统计
========
EOF

echo "总文件数: $(find . -type f | wc -l | tr -d ' ')"
echo "Ruby 文件: $(find . -name '*.rb' | wc -l | tr -d ' ')"
echo "ERB 文件: $(find . -name '*.erb' | wc -l | tr -d ' ')"
echo "JavaScript 文件: $(find . -name '*.js' | wc -l | tr -d ' ')"
echo "CSS 文件: $(find . -name '*.css' | wc -l | tr -d ' ')"
echo "测试文件: $(find test -name '*_test.rb' 2>/dev/null | wc -l | tr -d ' ')"

echo ""
echo "📦 3. 依赖分析"
echo "=================="
if [ -f "Gemfile" ]; then
    echo "Gemfile 依赖:"
    grep -E "^  gem |^gem " Gemfile | head -20
    echo "... (更多依赖请查看 Gemfile)"
fi

if [ -f "package.json" ]; then
    echo ""
    echo "package.json 依赖:"
    grep -E '"[^"]+":' package.json | head -10
fi

echo ""
echo "⚙️  4. 配置文件分析"
echo "=================="
if [ -f "config/routes.rb" ]; then
    echo "路由数量: $(grep -E "^  (get|post|put|patch|delete|resources)" config/routes.rb | wc -l | tr -d ' ')"
    echo "路由文件已保存到: $ANALYSIS_DIR/routes.txt"
    cp config/routes.rb "$OLDPWD/$ANALYSIS_DIR/routes.txt"
fi

if [ -f "config/deploy.yml" ]; then
    echo "部署配置已保存到: $ANALYSIS_DIR/deploy.yml"
    cp config/deploy.yml "$OLDPWD/$ANALYSIS_DIR/deploy.yml"
fi

echo ""
echo "📊 5. 代码统计"
echo "=================="
cat > "$OLDPWD/$ANALYSIS_DIR/code_stats.txt" <<EOF
代码统计
========

按目录统计代码行数:
$(find app -name '*.rb' -exec wc -l {} + 2>/dev/null | tail -1 || echo "N/A")

模型文件:
$(find app/models -name '*.rb' 2>/dev/null | wc -l | tr -d ' ') 个文件

控制器文件:
$(find app/controllers -name '*.rb' 2>/dev/null | wc -l | tr -d ' ') 个文件

视图文件:
$(find app/views -name '*.erb' 2>/dev/null | wc -l | tr -d ' ') 个文件

辅助方法文件:
$(find app/helpers -name '*.rb' 2>/dev/null | wc -l | tr -d ' ') 个文件

后台任务文件:
$(find app/jobs -name '*.rb' 2>/dev/null | wc -l | tr -d ' ') 个文件

邮件文件:
$(find app/mailers -name '*.rb' 2>/dev/null | wc -l | tr -d ' ') 个文件
EOF

cat "$OLDPWD/$ANALYSIS_DIR/code_stats.txt"

echo ""
echo "📝 6. 关键文件内容"
echo "=================="

# 保存 README
if [ -f "README.md" ]; then
    cp README.md "$OLDPWD/$ANALYSIS_DIR/README.md"
    echo "✅ README.md 已保存"
fi

# 保存 STYLE 指南
if [ -f "STYLE.md" ]; then
    cp STYLE.md "$OLDPWD/$ANALYSIS_DIR/STYLE.md"
    echo "✅ STYLE.md 已保存"
fi

# 保存应用配置
if [ -f "config/application.rb" ]; then
    cp config/application.rb "$OLDPWD/$ANALYSIS_DIR/application.rb"
    echo "✅ config/application.rb 已保存"
fi

# 保存 Gemfile
if [ -f "Gemfile" ]; then
    cp Gemfile "$OLDPWD/$ANALYSIS_DIR/Gemfile"
    echo "✅ Gemfile 已保存"
fi

echo ""
echo "📋 7. 模型分析"
echo "=================="
if [ -d "app/models" ]; then
    echo "模型列表:"
    find app/models -name '*.rb' -exec basename {} \; | sed 's/.rb$//' | sort
    echo ""
    echo "模型文件已列出到: $ANALYSIS_DIR/models.txt"
    find app/models -name '*.rb' -exec basename {} \; | sed 's/.rb$//' | sort > "$OLDPWD/$ANALYSIS_DIR/models.txt"
fi

echo ""
echo "🎮 8. 控制器分析"
echo "=================="
if [ -d "app/controllers" ]; then
    echo "控制器列表:"
    find app/controllers -name '*_controller.rb' -exec basename {} \; | sed 's/_controller.rb$//' | sort
    echo ""
    echo "控制器文件已列出到: $ANALYSIS_DIR/controllers.txt"
    find app/controllers -name '*_controller.rb' -exec basename {} \; | sed 's/_controller.rb$//' | sort > "$OLDPWD/$ANALYSIS_DIR/controllers.txt"
fi

echo ""
echo "🧪 9. 测试分析"
echo "=================="
if [ -d "test" ]; then
    echo "测试文件统计:"
    echo "  模型测试: $(find test/models -name '*_test.rb' 2>/dev/null | wc -l | tr -d ' ')"
    echo "  控制器测试: $(find test/controllers -name '*_test.rb' 2>/dev/null | wc -l | tr -d ' ')"
    echo "  系统测试: $(find test/system -name '*_test.rb' 2>/dev/null | wc -l | tr -d ' ')"
    echo "  集成测试: $(find test/integration -name '*_test.rb' 2>/dev/null | wc -l | tr -d ' ')"
fi

echo ""
echo "✅ 分析完成！"
echo "📊 分析结果保存在: $ANALYSIS_DIR"
echo ""
echo "📖 下一步建议:"
echo "  1. 查看 $ANALYSIS_DIR/README.md 了解项目概述"
echo "  2. 查看 $ANALYSIS_DIR/routes.txt 了解路由设计"
echo "  3. 查看 $ANALYSIS_DIR/models.txt 和 controllers.txt 了解代码组织"
echo "  4. 阅读关键模型和控制器文件，学习代码风格"
echo "  5. 分析视图文件，学习 Hotwire 使用方式"

cd "$OLDPWD"

