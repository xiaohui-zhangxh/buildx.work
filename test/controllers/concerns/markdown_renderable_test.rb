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
