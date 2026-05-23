module FormHelper

  def form_for(record, options = {}, &block)
    options[:builder] ||= ::FormBuilder
    super(record, options, &block)
  end

  def use_drag_and_drop
    return Joruri.config.application['sys.fileupload_with_drag_and_drop']
  end

  def radio_button_tags(name, collections, checked_value = nil, options = {})
    collections.inject(''.html_safe) do |html, (label, value)|
      options.merge!(id: "#{sanitize_to_id(name)}_#{value}")
      html += radio_button_tag(name, value, value == checked_value, options)
      html += label_tag("#{name}_#{value}", label)
    end
  end

  def check_box_tags(name, collections, checked_values = [], options = {})
    collections.inject(''.html_safe) do |html, (label, value)|
      options.merge!(id: "#{sanitize_to_id(name)}_#{value}")
      html += check_box_tag("#{name}[]", value, value.in?(checked_values), options)
      html += label_tag("#{name}_#{value}", label)
    end
  end

  def unique_error_messages_for(items)
    return nil if items.blank?
    tmp = items.first.class.new
    items.each do |item|
      item.errors.each {|attr, msg| tmp.errors.add(attr, msg) unless tmp.errors.added?(attr, msg) }
    end
    error_messages_for(tmp)
  end

  def set_focus_to_id(id)
    javascript_tag("$('#{id}').focus()");
  end

  ## tinyMCE
  def init_tiny_mce(options = {})
    settings = []
    options.each do |k, v|
      v = %Q("#{v}") if v.class == String
      settings << "#{k}:#{v}"
    end
    [
      javascript_include_tag("/_common/js/tiny_mce/tiny_mce.js"),
      javascript_include_tag("/_common/js/tiny_mce/init.js"),
      javascript_tag("initTinyMCE({#{settings.join(',')}});")
    ].join("\n")
  end

  def submission_label(name)
    {
      :add       => '追加する',
      :create    => '作成する',
      :register  => '登録する',
      :edit      => '編集する',
      :update    => '更新する',
      :change    => '変更する',
      :delete    => '削除する'
    }[name]
  end

  def submit(*args)
    make_tag = Proc.new do |_name, _label|
      _label ||= submission_label(_name) || _name.to_s.humanize
      submit_tag(_label, :name => "commit_#{_name}", :class => _name)
    end

    h = '<div class="submitters">'
    if args[0].class == String || args[0].class == Symbol
      h += make_tag.call(args[0], args[1])
    elsif args[0].class == Hash
      args[0].each {|k, v| h += make_tag.call(k, v) }
    elsif args[0].class == Array
      args[0].each {|v, k| h += make_tag.call(k, v) }
    end
    h += '</div>'
  end

  def submit_for(form, options = {})
    js_submitter = options[:js_submitter] || nil
    caption = options[:caption] || 'Submit'
    no_out_div = options[:no_out_div]
    [:js_submitter, :caption, :no_out_div].each {|x| options.delete x unless options[x].nil?}
    if js_submitter.nil?
      ret = form.submit(caption, options)
    else
      options[:id] = options[:id] || 'item_submit'
      options[:name] = options[:name] || 'commit'
      options[:onclick] = js_submitter
      ret = button_to(caption,'javascript:void(0)', options)
    end
    return no_out_div ? ret.html_safe : ('<div class="submitters">' + ret + '</div>').html_safe
  end

  def submit_for_create(form, options = {})
    options[:caption] = '登録する' if options[:caption].nil?
    submit_for(form, options)
  end

  def submit_for_update(form, options = {})
    options[:caption] = '編集する' if options[:caption].nil?
    submit_for(form, options)
  end

  def tool_tiny_mce(base_url = "/", options = {})
    render 'system/tool/tiny_mce/init', base_url: base_url, options: options
  end

  def radio(form, name, list, options = {})
    k,v,br,html = '','','',''
    html_a = []
    force_tag = options[:force_tag]
    options.delete :force_tag
    opt_return_array = options[:return_array]
    options.delete :return_array
#
    radio_1line = proc {|v,k|
      _v = v
      _text = ''
      unless options[:text_field].nil?
        md = _v.match(/^t:(.+?):(.+)$/)
        _v = md[2] if !md.nil?
        _text = form.text_field(md[1], :style => 'width:10em;') if !md.nil?
      end
      selected = params.blank? ? false : params[form.object_name].blank? ? false : "#{params[form.object_name][name]}"=="#{k}"
      selected = options[:selected].blank? ? false : "#{options[:selected]}"=="#{k}"
      radio_w = force_tag.blank? ? form.radio_button(name, k, options) :
        radio_button_tag("#{form.object_name}[#{name}]", k, selected, options)
      html_a.push "#{radio_w}" +
        "<label for=\"#{form.object_name}_#{name}_#{k.to_s}\">#{_v}</label>#{_text}#{br}\n"
    }
#
    br = options[:br].nil? ? '' : '<br />'
    if list.class == Array
#      list.each {|v, k| radio_1line.call}
      list.each do |v, k|
        radio_1line.call(v,k)
      end
    else
#      list.each {|k, v| radio_1line.call}
      list.each do |k, v|
        radio_1line.call(v,k)
      end
    end
    return !opt_return_array.blank? ? html_a : "#{options[:prefix]}#{Gw.join(html_a, options[:delim])}#{options[:suffix]}".html_safe
  end

  def check_boxes(form, name, list, _options = {})
    options = HashWithIndifferentAccess.new(_options)
    mode = nz(options[:form_type])
    options.delete :form_type
    delim = nz(options[:delim], ':')
    selected = nz(options[:selected_str], '').split(delim)
    options.delete :selected_str
    options.delete :check_with_to_s
    a_cbs = []
    form_name = mode.blank? ? form.object_name : form
    list.each_with_index do |item,idx|
      id = "#{form_name}[#{name}][#{idx}]"
      check_ind = !selected.index(item[1]).nil? || !selected.index(item[1].to_s).nil?
      a_cbs.push check_box_tag(id, "#{item[1]}", check_ind, options) +
        label_tag(id, "#{item[0]}", options)
    end
    a_cbs = a_cbs.join '&nbsp;'
    return a_cbs.html_safe
  end

  # date_picker3: flatpickr ベースの日付入力フィールド（calendar_date_select を置き換え）
  def date_picker3(f, name, value = nil, options = {})
    object_name = f.is_a?(ActionView::Helpers::FormBuilder) ? f.object_name : f.to_s
    tag_name = "#{object_name}[#{name}]" rescue name
    err_flg  = options.delete(:errors)&.dig(name)&.first
    mode     = options.delete(:time) == false ? 'date' : 'datetime'

    display_value = format_flatpickr_value(value, mode)
    field = text_field_tag(tag_name, display_value,
      id:           Gw.name_to_id(tag_name),
      style:        options[:style] || 'width:10em;',
      data:         { flatpickr: mode },
      autocomplete: 'off')
    field = %Q(<span class="field_with_errors">#{field}</span>) if err_flg
    field.html_safe
  end

  # date_picker_prop: flatpickr ベース（calendar_date_select を置き換え）
  def date_picker_prop(f, name, _options = {})
    options = HashWithIndifferentAccess.new(_options)
    value   = nz(options[:value], Time.now)
    value   = Gw.to_time(value) if value.is_a?(String)
    mode    = nz(options[:mode], :datetime).to_s
    minute_interval = nz(options[:minute_interval], 15).to_i rescue 15
    minute_interval = 15 if minute_interval <= 0

    err_flg = options[:errors].nil? ? nil : options[:errors][name].first

    object_name = f.is_a?(ActionView::Helpers::FormBuilder) ? f.object_name : f.to_s
    tag_name = "#{object_name}[#{name}]" rescue name

    display_value = format_flatpickr_value(value, mode)

    field = f.text_field(name.to_sym,
      value:        display_value,
      data:         { flatpickr: mode, 'minute-interval': minute_interval.to_s },
      autocomplete: 'off')
    field = %Q(<span class="field_with_errors">#{field}</span>) if err_flg
    field.html_safe
  end

  private

  def format_flatpickr_value(value, mode)
    return '' if value.blank?
    v = value.is_a?(String) ? Gw.to_time(value) : value
    return '' unless v
    case mode.to_s
    when 'date'     then v.strftime('%Y-%m-%d')
    when 'time'     then v.strftime('%H:%M')
    else                 v.strftime('%Y-%m-%d %H:%M')
    end
  rescue
    value.to_s
  end

  public

  def form_text_area(form, name, options = {})
    opt = options.dup
    opt[:style] = 'width: 30em; ime-mode: active;' if opt[:style].blank?
    opt[:cols] = 60 if opt[:cols].blank?
    opt[:rows] = 5 if opt[:rows].blank?
    form.text_area name, opt
  end
end
