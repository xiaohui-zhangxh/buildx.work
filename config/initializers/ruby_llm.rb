# RubyLLM 配置
# 统一 AI 接口库配置
# 使用 OpenRouter 作为 AI 服务提供商
# 参考：https://rubyllm.com/

Rails.application.config.after_initialize do
  # 从 SystemConfig 读取配置（延迟加载，确保数据库已初始化）
  # 注意：这里只设置一次，如果配置更新需要重启服务器
  # 或者可以在每次调用时动态读取（在 AiService 中处理）

  # 设置 OpenRouter 的 base_url（通过环境变量）
  # OpenRouter 使用 OpenAI 兼容的 API，但需要设置不同的 base_url
  ENV["OPENAI_BASE_URL"] ||= "https://openrouter.ai/api/v1"

  # 如果 SystemConfig 中有配置，设置 API Key
  # 注意：RubyLLM 会在每次调用时读取配置，所以这里可以动态设置
  # 但为了性能，我们建议在配置更新后重启服务器
end

raise "RubyLLM version is not 1.9.1, it is #{RubyLLM::VERSION}" if RubyLLM::VERSION != "1.9.1"

# 修复 Monica API 返回 OpenAI 接口时，tool_calls 的 id 为空字符串的问题， arguments 为 nil 的问题
# 标准 OpenAI API 返回的 tool_calls 的 id 为 nil， arguments 为空字符串
RubyLLM::Providers::OpenAI::Tools.prepend(Module.new do
  def parse_tool_calls(tool_calls, parse_arguments: true)
    return nil unless tool_calls&.any?

    tool_calls.to_h do |tc|
      id = tc["id"]
      name = tc.dig("function", "name")
      arguments = if parse_arguments
                    parse_tool_call_arguments(tc)
      else
                    tc.dig("function", "arguments") || ""
      end
      id = nil if id && id.empty?

      [ id, RubyLLM::ToolCall.new(id: id, name: name, arguments: arguments) ]
    end
  end
end)

# PR: https://github.com/crmne/ruby_llm/pull/423
# 让我们可以自由控制 messages 重置的逻辑
RubyLLM::ActiveRecord::ChatMethods.prepend(Module.new do
  private

    def populate_messages
      @chat.reset_messages!
      messages_association.each do |msg|
        @chat.add_message(msg.to_llm)
      end
    end

    def to_llm
      model_record = model_association
      @chat ||= (context || RubyLLM).chat(
        model: model_record.model_id,
        provider: model_record.provider.to_sym
      )

      populate_messages

      setup_persistence_callbacks
    end
end)

# PR: https://github.com/crmne/ruby_llm/pull/431
# 显示 Openrouter 的详细错误信息

RubyLLM::Providers::OpenRouter.prepend(Module.new do
  def parse_error(response)
    return if response.body.empty?

    body = try_parse_json(response.body)
    case body
    when Hash
      parse_error_part_message body
    when Array
      body.map do |part|
        parse_error_part_message part
      end.join(". ")
    else
      body
    end
  end

  private

    def parse_error_part_message(part)
      message = part.dig("error", "message")
      raw = try_parse_json(part.dig("error", "metadata", "raw"))
      return message unless raw.is_a?(Hash)

      raw_message = raw.dig("error", "message")
      return [ message, raw_message ].join(" - ") if raw_message

      message
    end
end)
