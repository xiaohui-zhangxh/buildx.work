# frozen_string_literal: true

# Custom FormBuilder for DaisyUI styled forms
# Provides consistent form styling and structure across the application
class DaisyFormBuilder < ActionView::Helpers::FormBuilder
  # Default CSS classes for form elements
  DEFAULT_INPUT_CLASSES = "input input-bordered w-full focus:input-primary"
  DEFAULT_TEXTAREA_CLASSES = "textarea textarea-bordered w-full"
  DEFAULT_SELECT_CLASSES = "select select-bordered w-full"
  DEFAULT_CHECKBOX_CLASSES = "checkbox checkbox-primary"
  DEFAULT_RADIO_CLASSES = "radio radio-primary"

  # Render error messages for the form object
  # Returns a DaisyUI alert component with error messages
  def error_messages(options = {})
    return "" unless object&.errors&.any?

    error_class = options[:class] || "alert alert-error mb-4 shadow-lg"
    title = options[:title] || "请修复以下错误："

    @template.content_tag(:div, role: "alert", class: error_class) do
      @template.content_tag(:svg,
        xmlns: "http://www.w3.org/2000/svg",
        class: "stroke-current shrink-0 h-6 w-6",
        fill: "none",
        viewBox: "0 0 24 24") do
        @template.content_tag(:path,
          "",
          stroke_linecap: "round",
          stroke_linejoin: "round",
          stroke_width: "2",
          d: "M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z")
      end +
        @template.content_tag(:div) do
          @template.content_tag(:h3, title, class: "font-bold") +
            @template.content_tag(:ul, class: "list-disc list-inside text-sm") do
              object.errors.full_messages.map do |message|
                @template.content_tag(:li, message)
              end.join.html_safe
            end
        end
    end
  end

  # Render a text field with consistent styling
  # Only wraps with label if label_text is provided
  def text_field(method, options = {})
    label_text = options.delete(:label_text)
    if label_text
      field_wrapper(method, label_text: label_text) do
        super(method, merge_input_classes(options))
      end
    else
      # Preserve Rails default behavior - just apply default classes
      super(method, merge_input_classes(options))
    end
  end

  # Render an email field with consistent styling
  # Only wraps with label if label_text is provided
  def email_field(method, options = {})
    label_text = options.delete(:label_text)
    if label_text
      field_wrapper(method, label_text: label_text) do
        super(method, merge_input_classes(options))
      end
    else
      # Preserve Rails default behavior - just apply default classes
      super(method, merge_input_classes(options))
    end
  end

  # Render a password field with consistent styling
  # Only wraps with label if label_text is provided
  def password_field(method, options = {})
    label_text = options.delete(:label_text)
    if label_text
      field_wrapper(method, label_text: label_text) do
        super(method, merge_input_classes(options))
      end
    else
      # Preserve Rails default behavior - just apply default classes
      super(method, merge_input_classes(options))
    end
  end

  # Render a number field with consistent styling
  # Only wraps with label if label_text is provided
  def number_field(method, options = {})
    label_text = options.delete(:label_text)
    if label_text
      field_wrapper(method, label_text: label_text) do
        super(method, merge_input_classes(options))
      end
    else
      # Preserve Rails default behavior - just apply default classes
      super(method, merge_input_classes(options))
    end
  end

  # Render a textarea with consistent styling
  # Only wraps with label if label_text is provided
  def text_area(method, options = {})
    label_text = options.delete(:label_text)
    if label_text
      field_wrapper(method, label_text: label_text) do
        default_rows = options.delete(:rows) || 3
        super(method, merge_textarea_classes(options).merge(rows: default_rows))
      end
    else
      # Preserve Rails default behavior - just apply default classes
      default_rows = options.delete(:rows) || 3
      super(method, merge_textarea_classes(options).merge(rows: default_rows))
    end
  end

  # Render a select field with consistent styling
  # Only wraps with label if label_text is provided
  def select(method, choices = nil, options = {}, html_options = {})
    label_text = html_options.delete(:label_text)
    if label_text
      field_wrapper(method, label_text: label_text) do
        super(method, choices, options, merge_select_classes(html_options))
      end
    else
      # Preserve Rails default behavior - just apply default classes
      super(method, choices, options, merge_select_classes(html_options))
    end
  end

  # Render a checkbox with consistent styling
  # Only wraps with label if label_text is provided
  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    label_text = options.delete(:label_text)
    if label_text
      # label_text can be true (use human attribute name) or string
      final_label_text = if label_text == true
        label_text(method)
      else
        label_text
      end

      field_wrapper(method, wrapper_class: "form-control", label_text: false) do
        label_class = options.delete(:label_class) || "label cursor-pointer justify-start gap-2"
        @template.content_tag(:label, class: label_class) do
          super(method, merge_checkbox_classes(options), checked_value, unchecked_value) +
            @template.content_tag(:span, final_label_text, class: "label-text")
        end
      end
    else
      # Preserve Rails default behavior - just apply default classes
      super(method, merge_checkbox_classes(options), checked_value, unchecked_value)
    end
  end

  # Render a collection of radio buttons with consistent styling
  def collection_radio_buttons(method, collection, value_method, text_method, options = {}, html_options = {})
    field_wrapper(method) do
      @template.content_tag(:div, class: "flex flex-col gap-2") do
        collection.map do |item|
          value = item.send(value_method)
          text = item.send(text_method)
          radio_id = "#{object_name}_#{method}_#{value}"
          @template.content_tag(:label, class: "label cursor-pointer justify-start gap-2") do
            radio_button(method, value, merge_radio_classes(html_options).merge(id: radio_id)) +
              @template.content_tag(:span, text, class: "label-text")
          end
        end.join.html_safe
      end
    end
  end

  # Render a submit button with consistent styling
  def submit(value = nil, options = {})
    default_class = "btn btn-primary"
    size = options.delete(:size)
    size_class = size ? "btn-#{size}" : ""
    full_width = options.delete(:full_width) ? "w-full" : ""
    classes = [ default_class, size_class, full_width, options.delete(:class) ].compact.reject(&:blank?).join(" ")

    @template.content_tag(:div, class: "form-control mt-6") do
      super(value, options.merge(class: classes))
    end
  end

  # Render form actions (submit and cancel buttons)
  def actions(options = {})
    submit_text = options.delete(:submit_text) || "保存"
    cancel_text = options.delete(:cancel_text) || "取消"
    cancel_url = options.delete(:cancel_url)
    submit_options = options.delete(:submit_options) || {}

    @template.content_tag(:div, class: "form-control mt-6") do
      submit(submit_text, submit_options) +
        if cancel_url
          @template.link_to(cancel_text, cancel_url, class: "btn btn-ghost ml-2")
        else
          ""
        end
    end
  end

  # Alternative: Use card-actions for button layout
  def card_actions(options = {})
    submit_text = options.delete(:submit_text) || "保存"
    cancel_text = options.delete(:cancel_text) || "取消"
    cancel_url = options.delete(:cancel_url)
    submit_options = options.delete(:submit_options) || {}
    cancel_options = options.delete(:cancel_options) || {}

    @template.content_tag(:div, class: "card-actions justify-end mt-6") do
      if cancel_url
        @template.link_to(cancel_text, cancel_url, class: "btn btn-ghost", **cancel_options)
      else
        ""
      end +
        @template.button_tag(submit_text, type: "submit", class: "btn btn-primary", **submit_options)
    end
  end

  private

    # Wrap a field with label and error handling
    # Only called when label_text is explicitly provided
    def field_wrapper(method, options = {})
      wrapper_class = options[:wrapper_class] || "form-control"
      label_text = options[:label_text]

      # label_text can be:
      # - false: don't render label
      # - true: use human attribute name
      # - string: use the string as label text
      final_label_text = if label_text == true
        label_text(method)
      elsif label_text.is_a?(String)
        label_text
      else
        nil
      end

      show_label = label_text != false && final_label_text.present?

      @template.content_tag(:div, class: wrapper_class) do
        label_html = if show_label
          label(method, class: "label") do
            @template.content_tag(:span, final_label_text, class: "label-text font-medium")
          end
        else
          ""
        end

        field_html = yield

        error_html = if object&.errors&.[](method)&.any?
          @template.content_tag(:label, class: "label") do
            @template.content_tag(:span, object.errors[method].first, class: "label-text-alt text-error")
          end
        else
          ""
        end

        label_html + field_html + error_html
      end
    end

    # Get label text for a field
    def label_text(method)
      if object.class.respond_to?(:human_attribute_name)
        object.class.human_attribute_name(method)
      else
        method.to_s.humanize
      end
    end

    # Check if a field is required
    def field_required?(method)
      return false unless object.class.respond_to?(:validators_on)

      validators = object.class.validators_on(method)
      validators.any? { |v| v.is_a?(ActiveRecord::Validations::PresenceValidator) }
    end

    # Merge input classes with defaults
    def merge_input_classes(options)
      default_classes = options.delete(:no_default_classes) ? "" : DEFAULT_INPUT_CLASSES
      existing_classes = options[:class] || ""
      options.merge(class: [ default_classes, existing_classes ].reject(&:blank?).join(" "))
    end

    # Merge textarea classes with defaults
    def merge_textarea_classes(options)
      default_classes = options.delete(:no_default_classes) ? "" : DEFAULT_TEXTAREA_CLASSES
      existing_classes = options[:class] || ""
      options.merge(class: [ default_classes, existing_classes ].reject(&:blank?).join(" "))
    end

    # Merge select classes with defaults
    def merge_select_classes(options)
      default_classes = options.delete(:no_default_classes) ? "" : DEFAULT_SELECT_CLASSES
      existing_classes = options[:class] || ""
      options.merge(class: [ default_classes, existing_classes ].reject(&:blank?).join(" "))
    end

    # Merge checkbox classes with defaults
    def merge_checkbox_classes(options)
      default_classes = options.delete(:no_default_classes) ? "" : DEFAULT_CHECKBOX_CLASSES
      existing_classes = options[:class] || ""
      options.merge(class: [ default_classes, existing_classes ].reject(&:blank?).join(" "))
    end

    # Merge radio classes with defaults
    def merge_radio_classes(options)
      default_classes = options.delete(:no_default_classes) ? "" : DEFAULT_RADIO_CLASSES
      existing_classes = options[:class] || ""
      options.merge(class: [ default_classes, existing_classes ].reject(&:blank?).join(" "))
    end
end
