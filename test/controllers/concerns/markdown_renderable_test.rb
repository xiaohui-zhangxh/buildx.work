require "test_helper"

class MarkdownRenderableTest < ActiveSupport::TestCase
  # Test through ExperiencesController which includes MarkdownRenderable
  setup do
    @controller = ExperiencesController.new
    @controller.request = ActionDispatch::TestRequest.create
  end

  test "remove_front_matter removes YAML front matter" do
    content = <<~MARKDOWN
      ---
      description: Test description
      alwaysApply: true
      ---

      # Main Content
      This is the main content.
    MARKDOWN

    result = @controller.send(:remove_front_matter, content)

    assert_no_match(/---/, result)
    assert_match(/Main Content/, result)
    assert_match(/main content/, result)
  end

  test "remove_front_matter returns content unchanged if no front matter" do
    content = "# Main Content\nThis is the main content."

    result = @controller.send(:remove_front_matter, content)

    assert_equal content.strip, result
  end

  test "fix_list_formatting adds empty line before list items" do
    content = "Some text\n- Item 1\n- Item 2"

    result = @controller.send(:fix_list_formatting, content)

    assert_match(/\n\n- Item 1/, result)
  end

  test "fix_list_formatting does not add empty line if already present" do
    content = "Some text\n\n- Item 1\n- Item 2"

    result = @controller.send(:fix_list_formatting, content)

    # Should not add extra empty lines
    assert_match(/\n\n- Item 1/, result)
    assert_no_match(/\n\n\n- Item 1/, result)
  end

  test "markdown_to_html converts markdown to HTML" do
    markdown = "# Heading\n\nThis is **bold** text."

    html = @controller.send(:markdown_to_html, markdown)

    assert_match(/<h1/, html)
    assert_match(/Heading/, html)
    assert_match(/<strong>/, html)
    assert_match(/bold/, html)
  end

  test "convert_relative_links converts relative .md links to absolute URLs" do
    markdown = "[Fizzy 最佳实践学习总览](fizzy-overview.md)"
    
    result = @controller.send(:convert_relative_links, markdown, base_path: "/experiences")
    
    assert_equal "[Fizzy 最佳实践学习总览](/experiences/fizzy-overview)", result
  end

  test "convert_relative_links works with different base paths" do
    markdown = "[Rule](action-policy.md)"
    
    result = @controller.send(:convert_relative_links, markdown, base_path: "/tech-stack")
    
    assert_equal "[Rule](/tech-stack/action-policy)", result
  end

  test "convert_relative_links does not convert external links" do
    markdown = "[GitHub](https://github.com/basecamp/fizzy)"
    
    result = @controller.send(:convert_relative_links, markdown, base_path: "/experiences")
    
    assert_equal markdown, result
  end

  test "convert_relative_links does not convert anchor links" do
    markdown = "[Section](#section)"
    
    result = @controller.send(:convert_relative_links, markdown, base_path: "/experiences")
    
    assert_equal markdown, result
  end

  test "convert_relative_links does not convert absolute paths" do
    markdown = "[Home](/home)"
    
    result = @controller.send(:convert_relative_links, markdown, base_path: "/experiences")
    
    assert_equal markdown, result
  end

  test "convert_relative_links handles multiple links" do
    markdown = "[Link 1](file1.md) and [Link 2](file2.md)"
    
    result = @controller.send(:convert_relative_links, markdown, base_path: "/experiences")
    
    assert_equal "[Link 1](/experiences/file1) and [Link 2](/experiences/file2)", result
  end

  test "convert_relative_links handles links with special characters in filename" do
    markdown = "[Highlight.js](importmap-install-highlight-js.md)"
    
    result = @controller.send(:convert_relative_links, markdown, base_path: "/experiences")
    
    assert_equal "[Highlight.js](/experiences/importmap-install-highlight-js)", result
  end

  test "convert_relative_links handles links with anchor" do
    markdown = "[Section](file.md#section)"
    
    result = @controller.send(:convert_relative_links, markdown, base_path: "/experiences")
    
    assert_equal "[Section](/experiences/file#section)", result
  end

  test "convert_relative_links handles links with anchor and special characters" do
    markdown = "[Section](fizzy-overview.md#学习文档索引)"
    
    result = @controller.send(:convert_relative_links, markdown, base_path: "/experiences")
    
    assert_equal "[Section](/experiences/fizzy-overview#学习文档索引)", result
  end

  test "markdown_to_html handles code blocks with language" do
    markdown = <<~MARKDOWN
      ```ruby
      def hello
        puts "Hello"
      end
      ```
    MARKDOWN

    html = @controller.send(:markdown_to_html, markdown)

    assert_match(/language-ruby/, html)
    assert_match(/<pre>/, html)
    assert_match(/<code/, html)
  end

  test "markdown_to_html handles code blocks without language" do
    markdown = <<~MARKDOWN
      ```
      def hello
        puts "Hello"
      end
      ```
    MARKDOWN

    html = @controller.send(:markdown_to_html, markdown)

    assert_match(/<pre>/, html)
    assert_match(/<code/, html)
    # Should not have language class if no language specified
  end

  test "markdown_to_html escapes HTML in code blocks" do
    markdown = <<~MARKDOWN
      ```html
      <script>alert('xss')</script>
      ```
    MARKDOWN

    html = @controller.send(:markdown_to_html, markdown)

    assert_match(/&lt;script&gt;/, html)
    assert_no_match(/<script>/, html)
  end

  test "markdown_to_html handles tables" do
    markdown = <<~MARKDOWN
      | Header 1 | Header 2 |
      |----------|----------|
      | Cell 1   | Cell 2   |
    MARKDOWN

    html = @controller.send(:markdown_to_html, markdown)

    assert_match(/<table/, html)
    assert_match(/Header 1/, html)
    assert_match(/Cell 1/, html)
  end

  test "markdown_to_html handles links with target blank" do
    markdown = "[Link](https://example.com)"

    html = @controller.send(:markdown_to_html, markdown)

    assert_match(/target="_blank"/, html)
    assert_match(/rel="noopener noreferrer"/, html)
  end
end
