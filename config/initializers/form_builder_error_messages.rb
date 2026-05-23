# Restore f.error_messages helper removed in Rails 5+ (was from dynamic_form gem)
ActionView::Helpers::FormBuilder.class_eval do
  def error_messages
    return '' unless object&.errors&.any?

    errors = object.errors
    count  = errors.count
    noun   = count == 1 ? 'error' : 'errors'
    header = "#{count} #{noun} prohibited this #{object.class.model_name.human.downcase} from being saved:"

    messages = errors.full_messages.map { |msg| "<li>#{ERB::Util.html_escape(msg)}</li>" }.join
    html = <<~HTML
      <div id="errorExplanation" class="errorExplanation">
        <h2>#{ERB::Util.html_escape(header)}</h2>
        <ul>#{messages}</ul>
      </div>
    HTML
    html.html_safe
  end
end
