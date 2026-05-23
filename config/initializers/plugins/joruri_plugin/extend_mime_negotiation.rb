module ActionDispatch
  module Http
    module MimeNegotiation
      def formats
        accept = @env['HTTP_ACCEPT']

        if accept && accept !~ BROWSER_LIKE_ACCEPTS
          accept += ", */*"
        end

        @env["action_dispatch.request.formats"] ||=
          if parameters[:format]
            Array(Mime[parameters[:format]])
          elsif use_accept_header && valid_accept_header
            accepts
          elsif xhr?
            # Mime::JS removed in Rails 5; use Mime[:js] instead
            [Mime[:js]]
          else
            # Mime::HTML removed in Rails 5; use Mime[:html] instead
            [Mime[:html]]
          end
      end
    end
  end
end
