# Running Typst Backend Tests

## Quick Start

### 使用 just 命令（推荐）

```bash
# 默认运行（使用 Typst_jll）
just test-backend

# 指定平台
just test-backend typst    # 使用 Typst_jll（默认）
just test-backend native   # 使用系统 Typst
just test-backend none     # 仅生成 .typ 源文件
```

### 手动运行

#### 默认运行（使用 Typst_jll）

```bash
cd /Users/zihuaw/com.github/lucifer1004/DocumenterTypst
julia --project=test/typst_backend test/typst_backend/runtests.jl
```

### 测试不同平台

#### 1. 测试 Typst_jll（默认）

```bash
TYPST_PLATFORM=typst julia --project=test/typst_backend test/typst_backend/runtests.jl
```

#### 2. 测试系统 Typst

```bash
# 首先确保安装了 typst
typst --version

# 运行测试
TYPST_PLATFORM=native julia --project=test/typst_backend test/typst_backend/runtests.jl
```

#### 3. 测试仅生成 .typ 源文件（不编译）

```bash
TYPST_PLATFORM=none julia --project=test/typst_backend test/typst_backend/runtests.jl
```

## 详细步骤

### 1. 首次设置

```bash
# 进入项目目录
cd /Users/zihuaw/com.github/lucifer1004/DocumenterTypst

# 安装测试环境依赖
julia --project=test/typst_backend -e '
  using Pkg
  Pkg.develop(PackageSpec(path=pwd()))
  Pkg.instantiate()'
```

### 2. 运行测试

#### 方式一：直接运行

```bash
julia --project=test/typst_backend test/typst_backend/runtests.jl
```

#### 方式二：使用 Julia REPL

```julia
# 启动 Julia
julia --project=test/typst_backend

# 在 REPL 中
using Pkg
Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()

# 运行测试
include("test/typst_backend/runtests.jl")
```

#### 方式三：指定平台

```bash
# macOS/Linux
export TYPST_PLATFORM=native
julia --project=test/typst_backend test/typst_backend/runtests.jl

# Windows PowerShell
$env:TYPST_PLATFORM="native"
julia --project=test/typst_backend test/typst_backend/runtests.jl

# Windows CMD
set TYPST_PLATFORM=native
julia --project=test/typst_backend test/typst_backend/runtests.jl
```

## 测试内容

Backend 测试会验证以下内容：

### ✅ 基础文档生成

- 简单的 Markdown 渲染
- 列表、粗体、斜体
- 代码块
- `.typ` 文件生成
- PDF 生成（非 `none` 平台）

### ✅ 数学渲染

- LaTeX 数学（通过 mitex）
- 原生 Typst 数学语法
- 行内和显示数学

### ✅ 多页文档

- 页面间链接
- 目录生成
- 跨页引用

### ✅ 表格和特殊字符

- 表格渲染
- 特殊字符转义

## 查看测试输出

测试会在临时目录中生成文件，但你可以保留它们：

```julia
# 修改 runtests.jl 或创建自己的测试脚本
using Documenter
using DocumenterTypst

# 在指定目录构建
makedocs(
    root = "/tmp/typst_test",
    source = "src",
    build = "build",
    sitename = "MyTest",
    format = DocumenterTypst.TypstWriter.Typst(platform = "none"),
    pages = ["index.md"],
    doctest = false,
    remotes = nothing,
)

# 查看生成的文件
# ls /tmp/typst_test/build/
```

## 调试失败的测试

### 1. 查看详细输出

```bash
julia --project=test/typst_backend test/typst_backend/runtests.jl -v
```

### 2. 启用 Julia 调试

```bash
JULIA_DEBUG=all julia --project=test/typst_backend test/typst_backend/runtests.jl
```

### 3. 只运行特定测试

编辑 `test/typst_backend/runtests.jl`，注释掉不需要的 `@testset`：

```julia
@testset "Typst Backend: $PLATFORM" begin
    @testset "Basic Document" begin
        # ... 这个会运行
    end

    # @testset "Math Rendering" begin
    #     # ... 这个被跳过
    # end
end
```

### 4. 保存失败的构建

```bash
# 设置调试目录
export DOCUMENTER_TYPST_DEBUG="$HOME/typst-debug"
julia --project=test/typst_backend test/typst_backend/runtests.jl

# 检查保存的文件
ls ~/typst-debug/
```

## CI 中的运行方式

在 GitHub Actions CI 中，测试会这样运行：

```yaml
- name: Run Typst backend tests
  run: julia --project=test/typst_backend --code-coverage test/typst_backend/runtests.jl
  env:
    TYPST_PLATFORM: ${{ matrix.platform }}
```

## 常见问题

### Q: 测试说找不到 typst 命令（platform=native）

**A**: 需要安装系统 typst：

```bash
# macOS
brew install typst

# Linux
curl -fsSL https://github.com/typst/typst/releases/latest/download/typst-x86_64-unknown-linux-musl.tar.xz | tar -xJ
sudo mv typst-*/typst /usr/local/bin/

# 验证安装
typst --version
```

### Q: 测试在 Windows 上失败

**A**: 确保：

1. 使用正确的路径分隔符（自动处理）
2. 如果测试 `native` 平台，需要在 PATH 中有 typst.exe
3. 考虑只测试 `typst` 和 `none` 平台

### Q: PDF 生成失败但 .typ 文件正常

**A**:

1. 检查 `.typ` 文件语法是否正确
2. 尝试手动编译：`typst compile build/Test.typ`
3. 查看 Typst 编译器错误信息

### Q: 测试很慢

**A**: 使用 `platform="none"` 跳过 PDF 编译：

```bash
TYPST_PLATFORM=none julia --project=test/typst_backend test/typst_backend/runtests.jl
```

## 添加新的 Backend 测试

在 `test/typst_backend/runtests.jl` 中添加新的 `@testset`：

```julia
@testset "My New Feature" begin
    mktempdir() do dir
        srcdir = joinpath(dir, "src")
        mkpath(srcdir)

        write(joinpath(srcdir, "index.md"), """
        # My New Feature Test

        Test content here...
        """)

        makedocs(
            root = dir,
            source = "src",
            build = "build",
            sitename = "FeatureTest",
            format = DocumenterTypst.TypstWriter.Typst(platform = PLATFORM),
            pages = ["index.md"],
            doctest = false,
            remotes = nothing,
        )

        # 验证
        typfile = joinpath(dir, "build", "FeatureTest.typ")
        @test isfile(typfile)

        content = read(typfile, String)
        @test contains(content, "expected output")
    end
end
```

## 性能基准

在 M4 Max 上的大致运行时间：

- `platform="none"`: ~2-5 秒（只生成 .typ）
- `platform="typst"`: ~5-10 秒（使用 Typst_jll）
- `platform="native"`: ~5-10 秒（使用系统 typst）

## 总结

最常用的命令：

```bash
# 使用 just（推荐）
just test-backend           # 使用 Typst_jll（默认）
just test-backend native    # 使用系统 typst
just test-backend none      # 仅生成 .typ（最快，推荐开发时用）

# 手动运行
# 快速测试（推荐开发时使用）
TYPST_PLATFORM=none julia --project=test/typst_backend test/typst_backend/runtests.jl

# 完整测试
julia --project=test/typst_backend test/typst_backend/runtests.jl

# 测试系统 typst
TYPST_PLATFORM=native julia --project=test/typst_backend test/typst_backend/runtests.jl
```
