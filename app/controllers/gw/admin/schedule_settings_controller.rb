class Gw::Admin::ScheduleSettingsController  < Gw::Controller::Admin::Base
  include System::Controller::Scaffold
  layout "admin/template/schedule"

  def pre_dispatch
    Page.title = "スケジュール個人設定画面"
  end

  def init_admin_deletes
    @css = %w(/_common/themes/gw/css/schedule.css)
    Page.title = "削除設定 - #{Page.title}"
  end

  def admin_deletes
    init_admin_deletes
    return error_auth unless Core.user.has_role?('_admin/admin')

    @item = Gw::Property::ScheduleAdminDelete.first_or_new
  end

  def edit_admin_deletes
    init_admin_deletes
    return error_auth unless Core.user.has_role?('_admin/admin')

    @item = Gw::Property::ScheduleAdminDelete.first_or_new
    @item.options_value = params[:item]

    if @item.save
      flash_notice('スケジュール削除設定処理', true)
      redirect_to "/gw/config_settings?c1=1&c2=7"
    else
      render :admin_deletes
    end
  end

  def export
    uid = Core.user.id
    gid = Core.user.user_groups[0].id
    d1 = Date.today - 365 * 3
    d2 = Date.today + 365 * 3
    sche = Gw::Schedule.new
    cond_date = "!('#{d1.strftime('%Y-%m-%d 0:0:0')}' > gw_schedule_users.ed_at" +
          " or '#{d2.strftime('%Y-%m-%d 23:59:59')}' < gw_schedule_users.st_at)"
    cond = "((gw_schedule_users.class_id = 1 and gw_schedule_users.uid = #{uid}) or (gw_schedule_users.class_id = 2 and gw_schedule_users.uid = #{gid}))" +
        " and #{cond_date}"
    @items = sche.find(:all, :order => 'gw_schedules.allday DESC, gw_schedule_users.st_at, gw_schedule_users.ed_at, gw_schedules.id',
      :joins => :schedule_users, :conditions => cond
    )
    parent_items = []
    schedule_parent_ids = []
    @items.each { |item|
      if item.is_public_auth?(@is_gw_admin)
        if item.schedule_parent_id.blank?
          parent_items << item
        else
          if schedule_parent_ids.blank? || schedule_parent_ids.index(item.schedule_parent_id).blank?
            schedule_parent_ids << item.schedule_parent_id
            parent_items << item
          end
        end
      end
    }
    @items = parent_items
    ical = Gw::Controller::Schedule.convert_ical( @items )
    filename = "schedules.ics"
    send_data( ical,:filename => filename,:status => 200)
  end

  def import
    Page.title = "インポート - #{Page.title}"
    @css = %w(/_common/themes/gw/css/schedule.css)
  end

  def import_file
    Page.title = "インポート - #{Page.title}"
    @css = %w(/_common/themes/gw/css/schedule.css)
    par_item = params[:item]

    if par_item.nil? || par_item[:file].nil?
      flash[:notice] = 'ファイル名を入力してください<br />'
      respond_to do |format|
        format.html { render :action => "import" }
      end
      return
    end

    filename =  par_item[:file].original_filename
    extname = File.extname(filename)

    tempfile = par_item[:file].open

    success = 0
    error = 0
    error_msg = ''

    if par_item[:file_type] == 'ical'

      if extname != '.ics'
        flash[:notice] = '拡張子がical形式のものと異なります。拡張子が「ics」のファイルを指定してください。<br />'
        respond_to do |format|
          format.html { render :action => "import" }
        end
        return
      end

      case par_item[:nkf]
        when 'sjis'
          file_data =  NKF::nkf('-w -S',tempfile.read)
        else
          file_data =  NKF::nkf('-w',tempfile.read)
      end
      require 'icalendar'
      categories = I18n.t('enum.gw/schedule.title_category_id').invert
      begin
        cals = Icalendar::Calendar.parse(file_data)
      rescue Exception => e
        flash.now[:notice] = "iCal形式の解析に失敗しました。（#{e.message}）"
        return render :action => "import"
      end
      cal = cals.first
      unless cal
        flash.now[:notice] = "カレンダーデータが見つかりませんでした。"
        return render :action => "import"
      end
      wary = ['SU','MO','TU','WE','TH','FR','SA']
      cal.events.map do |event|
        if !event.dtstart || !event.dtend
          error += 1
          next
        end
        all_day_event = icalendar_date_value?(event.dtstart)
        dtstart = icalendar_value_to_jst(event.dtstart)
        dtend = icalendar_value_to_jst(event.dtend)
        _params = Hash::new
        _params[:item] = Hash::new
        _params[:init] = Hash::new
        _params[:item][:title] = ( event.summary.blank? ? '件名なし' : "#{event.summary}" )
        _params[:item][:memo]  = "#{event.description}"
        _params[:item][:place] = "#{event.location}"
        _params[:item][:schedule_props_json] = "[]"
        _params[:item][:schedule_users_json] = "[[\"1\", \"#{Core.user.id}\", \"#{Core.user.name}\"]]"
        _params[:item][:public_groups_json] = '["", "", ""]'
        _params[:item][:owner_uid] = "#{Core.user.id}"
        _params[:item][:creator_uid] = "#{Core.user.id}"
        _params[:item][:creator_gid] = "#{Core.user_group.id}"
        _params[:item][:is_public] = "3"
        _params[:item][:st_at] = "#{dtstart.strftime('%Y-%m-%d %H:%M')}"
        Array(event.categories).map{|category|
          _params[:item][:title_category_id] = categories[category.to_s.gsub(':','')]
        }
        if all_day_event || full_day_icalendar_event?(dtstart, dtend)
          _params[:item][:allday_radio_id] = '2'
          _params[:item][:repeat_allday_radio_id] = '2'
          _params[:item][:st_at] = DateTime.new(dtstart.year, dtstart.month, dtstart.day, 0, 0).strftime('%Y-%m-%d %H:%M')
          _dtend = icalendar_value_minus_one_day(dtend)
          _params[:item][:ed_at] = DateTime.new(_dtend.year, _dtend.month, _dtend.day, 23, 59).strftime('%Y-%m-%d %H:%M')
        else
          _params[:item][:ed_at] = "#{dtend.strftime('%Y-%m-%d %H:%M')}"
        end
        if !event.rrule.blank?
          _params[:init][:repeat_mode] = "2"
          continue_flag = 0
          Array(event.rrule).map{|rule|
            if rule.until.blank?
              continue_flag = 1
              error_msg += '終了日指定のない繰り返し予定は登録できません。<br />'
              next
            end
            until_dt = parse_icalendar_until(rule.until)
            _params[:item][:repeat_st_date_at] = "#{dtstart.strftime('%Y-%m-%d')}"
            _params[:item][:repeat_ed_date_at] = "#{until_dt.strftime('%Y-%m-%d')}"
            if all_day_event || full_day_icalendar_event?(dtstart, dtend)
              _params[:item][:repeat_st_time_at] = "00:00"
              _params[:item][:repeat_ed_time_at] = "23:59"
            else
              _params[:item][:repeat_st_time_at] = "#{dtstart.strftime('%H:%M')}"
              _params[:item][:repeat_ed_time_at] = "#{dtend.strftime('%H:%M')}"
            end
           if !rule.interval.blank? && rule.interval.to_i > 1
              continue_flag = 1
              error_msg += '間隔ありの繰り返し予定は登録できません。<br />'
           end
           case rule.frequency
             when 'DAILY'
              _params[:item][:repeat_class_id] = '1'
             when 'WEEKLY'
              _params[:item][:repeat_class_id] = '3'
              _params[:item][:repeat_weekday_ids] = {}
              weekday_ids = ''
              Array(rule.by_day).each{|w|
                w = w.to_s
                weekday_ids += ( weekday_ids.blank? ? wary.index(w).to_s : ':'+wary.index(w).to_s ) #:でつなぐ
              }
              _params[:item][:repeat_weekday_ids] = weekday_ids
            else
              error_msg += '毎日、毎週以外の繰り返し予定は登録できません。<br />'
              continue_flag = 1
           end
          }
          item = Gw::Schedule.new()
          if continue_flag == 0 && Gw::ScheduleRepeat.save_with_rels_concerning_repeat(item, _params, :create)
            success += 1
          else
            error_msg += item.errors.full_messages.join("<br />\n")
            error += 1
          end
        elsif !event.recurrence_id.blank?

        else
          _params[:init][:repeat_mode] = "1"
          item = Gw::Schedule.new()
          if Gw::ScheduleRepeat.save_with_rels_concerning_repeat(item, _params, :create)
            success += 1
          else
            error_msg += item.errors.full_messages.join("<br />\n")
            error += 1
          end
        end
      end
    elsif par_item[:file_type] == 'csv'

      if extname != '.csv'
        flash[:notice] = '拡張子がCSV形式のものと異なります。拡張子が「csv」のファイルを指定してください。<br />'
        respond_to do |format|
          format.html { render :action => "import" }
        end
        return
      end

      require 'csv'
      return if params[:item].nil?
      par_item = params[:item]

      file_data =  NKF::nkf('-w -Lu',tempfile.read)
      if file_data.blank?
      else
        csv = CSV.parse(file_data)

        csv_result = Array.new
        csv.each_with_index do |row, i|
          _csv = row.dup
          _params = Hash::new
          _params[:item] = Hash::new
          _params[:init] = Hash::new
          if i == 0
            _csv << 'error'
            csv_result << _csv
          elsif row.empty?
          else
            if row.length == 11
              _params[:item][:title] = "#{row[0]}"
              _params[:item][:st_at] = "#{row[1]} #{row[2]}"
              _params[:item][:ed_at] = "#{row[3]} #{row[4]}"
              _params[:item][:memo]  = "#{row[6]}"
              _params[:item][:place] = "#{row[7]}"
              _params[:item][:schedule_props_json] = "[]"
              _params[:item][:schedule_users_json] = "[[\"1\", \"#{Core.user.id}\", \"#{Core.user.name}\"]]"
              _params[:item][:public_groups_json] = '["", "", ""]'
              _params[:item][:owner_uid] = "#{Core.user.id}"
              _params[:item][:creator_uid] = "#{Core.user.id}"
              _params[:item][:creator_gid] = "#{Core.user_group.id}"
              _params[:item][:is_public] = "3"
              _params[:init][:repeat_mode] = "1"

              if !row[5].blank? && row[5].upcase == 'TRUE' # 終日
                _params[:item][:ed_at] = "#{row[1]} #{row[4]}"
                _params[:item][:allday] = '1'
                _params[:item][:allday_radio_id] = '2'
              end

              item = Gw::Schedule.new()

              if Gw::ScheduleRepeat.save_with_rels_concerning_repeat(item, _params, :create)
                success += 1
              else
                error_msg += "#{i}行目の予定は登録できませんでした。<br />\n"
                error_msg += item.errors.full_messages.join("<br />\n")
                error += 1
                _csv << item.errors.full_messages.join("")
                csv_result << _csv
              end
            else
              if i == 1
                error_msg += "このCSVファイルは、インポートするには不適正です。"
              end
              _csv << 'このCSVファイルは、インポートするには不適正です。'
              csv_result << _csv
              error += 1
            end
          end
        end
      end

    end

    _error_msg = 'インポート処理が完了しました。<br />'+
      '------結果-----<br />' +
      '有効' + success.to_s + '件を登録し、無効' + error.to_s + '件は無視しました。<br />' +
      ( error_msg.blank? ? '' : '------無効内容-----<br />' ) +
      error_msg

    if par_item[:file_type] == 'ical'
      if success > 0
        flash[:notice] = _error_msg
        redirect_to "/gw/schedules/setting_ind"
      else
        flash[:notice] = _error_msg
        respond_to do |format|
          format.html { render :action => "import" }
        end
      end
    elsif par_item[:file_type] == 'csv'
      if error > 0
        csv_result << ['有効' + success.to_s + '件を登録し、無効' + error.to_s + '件は無視しました。']
        file = Gw::Script::Tool.ary_to_csv(csv_result)
        send_data NKF::nkf('-s', file), :filename => "result.csv"
      else
        if success > 0
          flash[:notice] = _error_msg
          redirect_to "/gw/schedules/setting_ind"
        else
          flash[:notice] = _error_msg
          respond_to do |format|
            format.html { render :action => "import" }
          end
        end
      end
    end
  end

  def portal_display
    @item = Gw::Property::ScheduleSetting.where(uid: Core.user.id).first_or_new

    if @item.view_portal_schedule_display == '1'
      @item.view_portal_schedule_display = '0'
    else
      @item.view_portal_schedule_display = '1'
    end

    @item.save

    redirect_to params[:url].to_s
  end

private
  def icalendar_date_value?(value)
    value.is_a?(Icalendar::Values::Date) && !value.is_a?(Icalendar::Values::DateTime)
  end

  def icalendar_value_to_jst(value)
    if icalendar_date_value?(value)
      value.to_date
    else
      value.to_time.in_time_zone('Tokyo')
    end
  end

  def full_day_icalendar_event?(dtstart, dtend)
    return false unless dtstart.respond_to?(:hour) && dtend.respond_to?(:hour)
    dtstart == icalendar_value_minus_one_day(dtend) && dtstart.hour == 0 && dtstart.min == 0
  end

  def icalendar_value_minus_one_day(value)
    value.respond_to?(:advance) ? value.advance(days: -1) : value - 1
  end

  def parse_icalendar_until(value)
    value = value.to_s
    case value
    when /\A\d{8}T\d{6}Z\z/
      DateTime.strptime(value, '%Y%m%dT%H%M%SZ').in_time_zone('UTC').in_time_zone('Tokyo')
    when /\A\d{8}T\d{6}\z/
      Time.zone.strptime(value, '%Y%m%dT%H%M%S').in_time_zone('Tokyo')
    when /\A\d{8}\z/
      Date.strptime(value, '%Y%m%d')
    else
      Time.zone.parse(value).in_time_zone('Tokyo')
    end
  end
end
