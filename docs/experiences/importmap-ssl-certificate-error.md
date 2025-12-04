---
date: 2025-11-25
problem_type: 配置问题、Importmap、SSL 证书
status: 已解决
---

# Importmap SSL 证书验证错误

## 问题描述

在执行 `bin/importmap pin highlight.js` 命令时，出现 SSL 证书验证失败的错误：

```
OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 peeraddr=198.18.0.228:443 state=error: certificate verify failed (unable to get certificate CRL)
```

### 错误堆栈

错误发生在 `importmap-rails` gem 尝试通过 HTTPS 连接到 JSPM CDN 时：

```
/Users/xiaohui/.asdf/installs/ruby/3.3.5/lib/ruby/gems/3.3.0/gems/importmap-rails-2.2.2/lib/importmap/packager.rb:133:in `rescue in post_json': Unexpected transport error (OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 peeraddr=198.18.0.228:443 state=error: certificate verify failed (unable to get certificate CRL)) (Importmap::Packager::HTTPError)
```

## 问题原因分析

### 根本原因

Rails 项目默认没有包含 `openssl` gem，导致 Ruby 的 OpenSSL 扩展无法正确验证 SSL 证书。当 `importmap-rails` 尝试通过 HTTPS 连接到 JSPM CDN 下载 JavaScript 包时，SSL 证书验证失败。

### 为什么会出现这个问题

1. **Rails 8 默认不包含 openssl gem**：虽然 Ruby 本身包含 OpenSSL 支持，但在某些环境下（特别是使用 asdf 等版本管理器时），可能需要显式添加 `openssl` gem 来确保 SSL 功能正常工作。

2. **证书验证机制**：OpenSSL 需要能够获取证书撤销列表（CRL）来验证证书的有效性。如果 OpenSSL 扩展配置不当，可能无法获取 CRL，导致验证失败。

3. **环境差异**：这个问题在不同环境下表现可能不同，取决于：
   - Ruby 的编译方式（是否包含 OpenSSL 支持）
   - 系统 SSL 证书配置
   - 网络环境（是否使用代理）

## 解决方案

### 步骤 1：在 Gemfile 中添加 openssl gem

在 `Gemfile` 中添加 `openssl` gem：

```ruby
# 解决 importmap 下载依赖失败的问题 state=error: certificate verify failed
gem "openssl", "~> 3.3", ">= 3.3.2"
```

### 步骤 2：安装 gem

运行 bundle install：

```bash
bundle install
```

### 步骤 3：验证修复

重新执行 importmap pin 命令：

```bash
bin/importmap pin highlight.js
```

如果问题已解决，命令应该能够成功下载包并更新 `config/importmap.rb`。

## 关键经验总结

### 1. Rails 8 和 OpenSSL gem

- **Rails 8 默认不包含 openssl gem**：虽然 Ruby 本身有 OpenSSL 支持，但在某些环境下可能需要显式添加
- **建议**：如果遇到 SSL 相关错误，首先尝试添加 `openssl` gem

### 2. Importmap 和 HTTPS 连接

- `importmap-rails` 通过 HTTPS 连接到 JSPM CDN 下载包
- 需要正确的 SSL 证书验证才能正常工作
- 如果遇到证书验证错误，检查 OpenSSL 配置

### 3. 错误信息识别

**关键错误信息**：
- `certificate verify failed`：证书验证失败
- `unable to get certificate CRL`：无法获取证书撤销列表
- `SSL_connect returned=1`：SSL 连接失败

**解决方案**：添加 `openssl` gem 通常可以解决这类问题。

### 4. 版本选择

- 使用 `~> 3.3`, `>= 3.3.2` 确保使用稳定版本
- 与 Ruby 3.3.x 兼容

## 相关文件

- `Gemfile` - 添加 openssl gem 的位置
- `config/importmap.rb` - Importmap 配置文件（pin 命令会更新此文件）

## 参考资料

- [OpenSSL gem 文档](https://github.com/ruby/openssl)
- [Importmap Rails 文档](https://github.com/rails/importmap-rails)
- [Ruby OpenSSL 文档](https://docs.ruby-lang.org/en/master/OpenSSL.html)

