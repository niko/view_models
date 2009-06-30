# Base Module for ViewModels.
#
module ViewModels
  
  # Base class from which all view_models inherit.
  #
  class Base
    attr_reader :model, :controller
    
    #make helper and helper_method available
    include ActionController::Helpers
      
    class << self

      # Define a reader for a model attribute. Acts as a filtered delegation to the model. 
      #
      # You may specify a :filter_through option that is either a symbol or an array of symbols. The return value
      # from the model will be filtered through the functions (arity 1) and then passed back to the receiver. 
      #
      # Example: 
      #
      #   model_reader :foobar                                        # same as delegate :foobar, :to => :model
      #   model_reader :foobar, :filter_through => :h                 # html escape foobar 
      #   model_reader :foobar, :filter_through => [:textilize, :h]   # first textilize, then html escape
      #
      def model_reader(*args)
        args = args.dup
        opts = args.pop if args.last.kind_of?(Hash)
      
        fields = args.flatten
        filters = opts.nil? ? [] : [*(opts[:filter_through])].reverse
      
        fields.each do |field|
          reader = "def #{field}; 
                    #{filters.join('(').strip}(model.#{field})#{')' * (filters.size - 1) unless filters.empty?}; 
                    end"
          class_eval(reader)
        end
      end
      
      # Wrapper for add_template_helper in ActionController::Helpers, also
      # includes given helper in the view_model
      #
      alias old_add_template_helper add_template_helper
      def add_template_helper(helper_module)
        include helper_module
        old_add_template_helper helper_module
      end      
    
      # Delegates method calls to the controller.
      #
      # Example: 
      #   controller_method :current_user
      #
      # In the view_model:
      #   self.current_user
      # will call
      #   controller.current_user
      #
      def controller_method(*methods)
        methods.each do |method|
          delegate method, :to => :controller
        end
      end
    
      # Returns the path from the view_model_view_paths to the actual templates.
      # e.g. "view_models/models/book"
      #
      # If the class is named
      #   ViewModels::Models::Book
      # this method will yield
      #   view_models/models/book
      #
      def view_model_path
        name.underscore
      end
    end # class << self
    
    # Create a view_model. To create a view_model, you need to have a model (to present) and a context.
    # The context is usually a view or a controller.
    # Note: But doesn't need to be one :)
    # 
    def initialize(model, context)
      @model = model
      @controller = extract_controller_from context
    end
    
    # Delegate controller methods.
    #
    controller_method :logger
    controller_method :form_authenticity_token
    controller_method :protect_against_forgery?
    controller_method :request_forgery_protection_token
    
    # Make all the dynamically generated routes (restful routes etc.)
    # available in the view_model
    #
    ActionController::Routing::Routes.install_helpers(self)
    
    # Renders the given view in the view_model's view root in the format given.
    #
    # Example:
    #   app/views/view_models/this/view_model/template.html.haml
    #   app/views/view_models/this/view_model/template.text.erb
    #
    # Calling view_model.render_as('template', :html) will render the haml
    # template, calling view_model.render_as('template', :text) will render
    # the erb.
    #
    def render_as(view_name, format = nil)
      # Get a view instance from the view class.
      view = view_instance
    
      # Set the format to render in, e.g. :text, :html
      view.template_format = format if format
    
      # Finally, render and pass the view_model as a local variable.
      view.render :partial => template_path(view_name), :locals => { :view_model => self }
    end

    protected

      # Creates a view instance from the given view class.
      #
      def view_instance
        view = ActionView::Base.new controller.class.view_paths, {}, controller
        view.extend master_helper_module
      end
    
    private
        
      # Returns the root of this view_models views with the template name appended.
      # e.g. 'view_models/some/specific/path/to/template'
      #
      def template_path(name)
        name = name.to_s
        if name.include?('/')    # Specific path like 'view_models/somethingorother/foo.haml' given.
          name
        else
          File.join(self.class.view_model_path, name)
        end
      end
      
      # Extracts a controller from the context.
      #
      def extract_controller_from(context)
        if context.respond_to?(:controller)
          context.controller
        else
          context
        end
      end
      
  end
end