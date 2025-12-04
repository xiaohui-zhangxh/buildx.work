import { Controller } from "@hotwired/stimulus"
// Highlight.js syntax highlighting
import hljs from "highlight.js/lib/core"
import ruby from "highlight.js/lib/languages/ruby"
import javascript from "highlight.js/lib/languages/javascript"
import bash from "highlight.js/lib/languages/bash"
import yaml from "highlight.js/lib/languages/yaml"
import json from "highlight.js/lib/languages/json"
import xml from "highlight.js/lib/languages/xml"
import css from "highlight.js/lib/languages/css"
import sql from "highlight.js/lib/languages/sql"
import erb from "highlight.js/lib/languages/erb"
import markdown from "highlight.js/lib/languages/markdown"
// Register languages
hljs.registerLanguage("ruby", ruby)
hljs.registerLanguage("javascript", javascript)
hljs.registerLanguage("bash", bash)
hljs.registerLanguage("yaml", yaml)
hljs.registerLanguage("json", json)
hljs.registerLanguage("xml", xml)
hljs.registerLanguage("css", css)
hljs.registerLanguage("sql", sql)
hljs.registerLanguage("erb", erb)
hljs.registerLanguage("html", xml)
hljs.registerLanguage("markdown", markdown)
// Connects to data-controller="highlight"
export default class extends Controller {
  static values = {
    selector: {
      type: String,
      default: "pre code",
    }
  }

  connect() {
    const selector = this.selectorValue;
    const elements = this.element.querySelectorAll(selector);
    elements.forEach((element) => hljs.highlightElement(element));
  }
}
