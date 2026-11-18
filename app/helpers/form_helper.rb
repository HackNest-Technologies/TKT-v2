# Accessible form fields: label, hint, inline error linked with aria-describedby.
module FormHelper
  def field_error_id(object_name, attribute) = "#{object_name}_#{attribute}_error"

  def field_error(record, object_name, attribute)
    messages = record.errors.full_messages_for(attribute)
    return if messages.empty?
    tag.p(messages.to_sentence, id: field_error_id(object_name, attribute), class: "field__error")
  end

  def field_aria(record, object_name, attribute, hint_id: nil)
    invalid = record.errors.include?(attribute)
    described = [ hint_id, (field_error_id(object_name, attribute) if invalid) ].compact.join(" ").presence
    { invalid: (invalid || nil), describedby: described }
  end

  def error_summary(record)
    return if record.errors.empty?
    tag.div(class: "error-summary", role: "alert", tabindex: "-1", data: { controller: "focus" }) do
      tag.h2("Please fix #{pluralize(record.errors.count, 'problem')}", class: "error-summary__title") +
        tag.ul { safe_join(record.errors.full_messages.uniq.map { |m| tag.li(m) }) }
    end
  end

  def google_sign_in_enabled? = Devise.omniauth_providers.include?(:google_oauth2) && ENV["GOOGLE_CLIENT_ID"].present?
end
