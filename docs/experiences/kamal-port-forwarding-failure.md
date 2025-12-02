# Kamal 部署时端口转发失败问题

**日期**：2025-12-02  
**问题类型**：部署问题、Kamal、SSH 端口转发  
**状态**：✅ 已解决

## 问题描述

在执行 `bin/kamal build` 或 `bin/kamal deploy` 时，Kamal 尝试建立本地注册表端口转发时失败，错误信息如下：

```
Setting up local registry port forwarding to [服务器]...
ERROR Error setting up port forwarding to [服务器]: RuntimeError: Failed to establish port forward on [服务器]
```

### 错误堆栈

错误发生在 Kamal 尝试通过 SSH 建立端口转发时：

```
/Users/[用户]/.asdf/installs/ruby/3.3.5/lib/ruby/gems/3.3.0/gems/kamal-2.8.2/lib/kamal/cli/build/port_forwarding.rb:36:in `block (4 levels) in forward_ports'
/Users/[用户]/.asdf/installs/ruby/3.3.5/lib/ruby/gems/3.3.0/gems/net-ssh-7.3.0/lib/net-ssh/service/forward.rb:226:in `block in remote'
/Users/[用户]/.asdf/installs/ruby/3.3.5/lib/ruby/gems/3.3.0/gems/net-ssh/connection/session.rb:605:in `request_failure'
```

### 关键日志信息

从日志中可以看到：

1. **SSH 连接成功**：
   - 通过代理服务器连接到目标服务器
   - 公钥认证成功
   - SSH 会话建立正常

2. **端口转发请求失败**：
   - 发送全局请求 `tcpip-forward`
   - 收到 `global request failure` 响应
   - 最终错误：`Failed to establish port forward on [服务器]`

3. **authorized_keys 配置**：
   ```
   /home/[用户]/.ssh/authorized_keys:1: key options: agent-forwarding port-forwarding pty user-rc x11-forwarding
   ```
   说明 `authorized_keys` 中已经允许了 `port-forwarding`，但请求仍被拒绝。

## 问题原因分析

### 根本原因

虽然 `authorized_keys` 中允许了端口转发，但 SSH 服务器端的配置可能禁用了 TCP 转发功能。SSH 服务器配置的优先级高于 `authorized_keys` 中的选项。

### 可能的原因

1. **SSH 服务器配置限制（最可能）**
   - 服务器端 `/etc/ssh/sshd_config` 中 `AllowTcpForwarding` 设置为 `no`
   - 即使 `authorized_keys` 允许，服务器端配置会覆盖

2. **SSH 代理服务器限制**
   - 如果使用了 SSH 代理（如配置中的 `proxy: user@proxy-server`）
   - 代理服务器可能不允许端口转发
   - 需要在代理服务器上也允许端口转发

3. **权限或安全策略**
   - 服务器可能有额外的安全策略限制端口转发
   - SELinux、AppArmor 等安全模块可能限制

## 解决方案

### 方案 1：检查并修改服务器 SSH 配置（推荐）

在目标服务器上执行以下步骤：

#### 步骤 1：检查当前配置

```bash
sudo grep -i "AllowTcpForwarding" /etc/ssh/sshd_config
```

如果输出为空或显示 `AllowTcpForwarding no`，则需要修改。

#### 步骤 2：修改配置

如果配置不存在或为 `no`，添加或修改为：

```bash
# 方法 1：使用 sed 修改（如果已存在）
sudo sed -i 's/^#*AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config

# 方法 2：直接添加（如果不存在）
echo "AllowTcpForwarding yes" | sudo tee -a /etc/ssh/sshd_config
```

#### 步骤 3：重启 SSH 服务

```bash
sudo systemctl restart sshd
```

**注意**：重启 SSH 服务前，确保有其他方式可以访问服务器，避免连接中断。

#### 步骤 4：验证配置

重新执行 Kamal 命令验证：

```bash
bin/kamal build
```

### 方案 2：使用远程注册表（临时方案）

如果无法修改服务器配置，可以改用远程注册表，避免使用本地端口转发：

在 `config/deploy.yml` 中修改：

```yaml
registry:
  # 使用远程注册表
  server: registry.example.com  # 取消注释这行
  # server: localhost:5555  # 注释掉本地注册表
```

**注意**：使用远程注册表需要：
- 配置注册表认证信息（如需要）
- 确保服务器可以访问远程注册表
- 可能需要配置 `username` 和 `password`（从环境变量读取）

### 方案 3：检查代理服务器配置

如果使用了 SSH 代理，需要在代理服务器上也检查并允许端口转发：

```bash
# 在代理服务器上执行
sudo grep -i "AllowTcpForwarding" /etc/ssh/sshd_config
sudo sed -i 's/^#*AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## 关键经验总结

### 1. SSH 端口转发配置优先级

- **服务器端配置优先**：`/etc/ssh/sshd_config` 中的 `AllowTcpForwarding` 设置优先级高于 `authorized_keys` 中的选项
- **即使 authorized_keys 允许**：如果服务器端禁止，端口转发仍然会失败
- **需要同时配置**：确保服务器端和客户端都允许端口转发

### 2. Kamal 本地注册表端口转发

- **默认行为**：Kamal 使用本地注册表（`localhost:5555`）时，需要通过 SSH 端口转发将本地注册表暴露到服务器
- **失败影响**：端口转发失败会导致镜像构建和部署失败
- **替代方案**：可以使用远程注册表避免端口转发

### 3. SSH 代理和端口转发

- **代理链问题**：如果使用 SSH 代理，代理服务器也需要允许端口转发
- **多层配置**：需要确保代理服务器和目标服务器都允许端口转发
- **调试方法**：可以通过直接连接目标服务器（不使用代理）来验证是否是代理问题

### 4. 错误信息识别

**关键错误信息**：
- `Failed to establish port forward`：端口转发建立失败
- `global request failure`：SSH 全局请求失败
- `request_failure`：SSH 请求失败

**排查步骤**：
1. 检查 SSH 连接是否正常（通常正常）
2. 检查 `authorized_keys` 配置（通常已配置）
3. **重点检查**：服务器端 `/etc/ssh/sshd_config` 配置
4. 如果使用代理，检查代理服务器配置

### 5. 安全考虑

- **最小权限原则**：如果只需要特定端口转发，可以使用 `AllowTcpForwarding local` 或 `AllowTcpForwarding remote`
- **生产环境**：考虑使用远程注册表，避免在服务器上开放端口转发
- **网络安全**：确保端口转发不会暴露敏感服务

## 相关文件

- `config/deploy.yml` - Kamal 部署配置文件
- `/etc/ssh/sshd_config` - SSH 服务器配置文件（在服务器上）
- `~/.ssh/authorized_keys` - SSH 公钥认证文件（在服务器上）

## 参考资料

- [Kamal 文档 - 注册表配置](https://kamal-deploy.org/docs/configuration)
- [SSH 端口转发文档](https://www.ssh.com/academy/ssh/tunneling/example)
- [OpenSSH 配置文档](https://www.openssh.com/manual.html)

