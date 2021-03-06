module Pakyow
  module Presenter
    class BinderSet
      attr_reader :scopes

      def initialize
        @scopes = {}
        @options = {}
      end

      def scope(name, &block)
        scope_eval = ScopeEval.new
        bindings, options = scope_eval.eval(&block)

        @scopes[name.to_sym] = bindings
        @options[name.to_sym] = options
      end

      def match_for_prop(prop, scope, bindable, bindings = {})
        return bindings_for_scope(scope, bindings)[prop]
      end

      def options_for_prop(prop, scope, bindable, context)
        if block = (@options[scope] || {})[prop]
          binding_eval = BindingEval.new(bindable, prop, context)
          binding_eval.instance_exec(&block)
        end
      end

      def has_prop?(prop, scope, bindings)
        bindings_for_scope(scope, bindings).key? prop
      end

      def bindings_for_scope(scope, bindings)
        # merge passed bindings with bindings
        (@scopes[scope] || {}).merge(bindings)
      end
    end

    class ScopeEval
      include Helpers

      def initialize
        @bindings = {}
        @options = {}
      end

      def eval(&block)
        self.instance_eval(&block)
        return @bindings, @options
      end

      def binding(name, &block)
        @bindings[name.to_sym] = block
      end

      def options(name, &block)
        @options[name] = block
      end

      def restful(route_group)
        binding(:action) {
          routes = router.group(route_group)
          return_data = {}

          if id = bindable[:id]
            return_data[:view] = lambda { |view|
              view.prepend(View.from_doc(Nokogiri::HTML.fragment('<input type="hidden" name="_method" value="put">')))
            }

            action = routes.path(:update, :"#{route_group}_id" => id)
          else
            action = routes.path(:create)
          end

          return_data[:action] = action
          return_data[:method] = 'post'
          return_data
        }
      end

      #TODO options
    end

    class BindingEval
      include Helpers

      attr_accessor :context
      attr_reader :bindable

      def initialize(prop, bindable, context)
        @prop = prop
        @bindable = bindable
        @context = context
      end

      def value
        bindable[@prop]
      end
    end
  end
end
