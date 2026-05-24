# refer to render_component_vho gem
module RenderComponent
  module HelperMethods
    def render_component(options)
      controller.render_component_into_view(options)
    end

    def render_component_into_view(options)
      controller.render_component_into_view(options)
    end
  end

  module InstanceMethods
    def render_component(options)
      response = component_response(options)[2]
      if response.redirect_url
        redirect_to response.redirect_url
      else
        render plain: response.body, status: response.status
        response
      end
    end

    def render_component_into_view(options)
      response = component_response(options)[2]
      response.body.html_safe
    end

    private

    def component_response(options)
      controller = "#{options[:controller].to_s.camelize}Controller".constantize.new
      component_request = request_for_component(controller.controller_path, options)
      # Rails 8: dispatch takes (action, request, response) — 3 args
      component_response = ActionDispatch::Response.new
      controller.dispatch(options[:action], component_request, component_response)
      [component_response.status, component_response.headers, controller.response]
    end

    def request_for_component(_controller_path, options)
      component_params = options.delete(:params)
      if component_params
        component_params = component_params.to_unsafe_h if component_params.respond_to?(:to_unsafe_h)
        options.merge!(component_params)
      end

      request_params = options.symbolize_keys
      request_env = request.env.dup
      request_env['action_dispatch.request.symbolized_path_parameters'] = request_params
      request_env['action_dispatch.request.parameters'] = request_params.with_indifferent_access
      request_env['action_dispatch.request.path_parameters'] = request_params.slice(:controller, :action)
      ActionDispatch::Request.new(request_env)
    end
  end
end

ActionController::Base.include RenderComponent::InstanceMethods
ActionController::Base.helper RenderComponent::HelperMethods
