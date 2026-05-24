class Script
  def self.run?
    rs = (Thread.current[:joruri_script_runner] == true)
    Thread.current[:joruri_script_runner] = nil
    rs
  end
  
  def self.run(path)
    Thread.current[:joruri_script_runner] = true
    begin
      app = ActionController::Integration::Session.new
      #app.get "/_script#{path}"
      app.get "/_script/sys/run/#{path}"
    end
    Thread.current[:joruri_script_runner] = nil
  end
  
end
