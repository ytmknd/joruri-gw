## simple logger
class Sys::Lib::Debugger::Dump
  def self.dump_log(data)
    begin
      dump_logger.debug to_str(data)
    rescue Exception
    end
  end

  def self.dump_logger
    @dump_logger ||= Logger.new("#{Rails.root}/log/dump.log")
  end
  
  def self.sp(num)
    '  ' * num.to_i
  end
  
  def self.to_str(data, dep = 1)
    buf = ''
    if (data.class == Array)
      buf += 'Array ('
      data.each_with_index {|v,k| buf += "\n#{sp(dep)}#{k} => #{to_str(v, dep + 1)}" }
      buf += "\n#{sp(dep - 1)})"
    elsif data.is_a?(Hash)
      buf += 'Hash ('
      data.each {|k,v| buf += "\n#{sp(dep)}#{k} => #{to_str(v, dep + 1)}" }
      buf += "\n#{sp(dep - 1)})"
    else
      buf += "#{data} <#{data.class}>"
    end
    return buf
  end
end
