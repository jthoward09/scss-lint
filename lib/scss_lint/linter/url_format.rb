require 'uri'

module SCSSLint
  # Checks the format of URLs for unnecessary protocols or domains.
  class Linter::UrlFormat < Linter
    include LinterRegistry

    def visit_script_funcall(node)
      return unless node.name == 'url'

      if url_string?(node.args[0])
        url = node.args[0].value.value.to_s
        check_url(url, node)
      end

      yield
    end

    def visit_prop(node)
      if url_literal?(node.value)
        url = node.value.to_sass.gsub(/^url\((.*)\)$/, '\\1')
        check_url(url, node)
      end

      yield
    end

  private

    def url_literal?(prop_value)
      return unless prop_value.is_a?(Sass::Script::Tree::Literal)
      return unless prop_value.value.is_a?(Sass::Script::Value::String)
      return unless prop_value.value.type == :identifier

      prop_value.to_sass.match(/^url\(/)
    end

    def url_string?(arg)
      return unless arg.is_a?(Sass::Script::Tree::Literal)
      return unless arg.value.is_a?(Sass::Script::Value::String)

      arg.value.type == :string
    end

    def check_url(url, node)
      uri = URI(url)

      if uri.scheme || uri.host
        add_lint(node, "URL `#{url}` should not contain protocol or domain")
      end
    rescue URI::Error => ex
      add_lint(node, "Invalid URL `#{url}`: #{ex}")
    end
  end
end
