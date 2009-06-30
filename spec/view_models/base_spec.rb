require File.join(File.dirname(__FILE__), '../spec_helper')

require 'view_models/base'

describe ViewModels::Base do
  
  describe "readers" do
    describe "model" do
      before(:each) do
        @model      = stub :model
        @view_model = ViewModels::Base.new @model, nil
      end
      it "should have a reader" do
        @view_model.model.should == @model
      end
    end
    describe "controller" do
      before(:each) do
        @context    = stub :controller
        @view_model = ViewModels::Base.new nil, @context
      end
      it "should have a reader" do
        @view_model.controller.should == @context
      end
    end
  end
  
  describe "context recognition" do
    describe "context is a view" do
      before(:each) do
        @view = stub :view, :controller => 'controller'
        @view_model = ViewModels::Base.new nil, @view
      end
      it "should get the controller from the view" do
        @view_model.controller.should == 'controller'
      end
    end
    describe "context is a controller" do
      before(:each) do
        @controller = stub :controller
        @view_model = ViewModels::Base.new nil, @controller
      end
      it "should just use it for the controller" do
        @view_model.controller.should == @controller
      end
    end
  end
  
  class ModelReaderModel < Struct.new(:some_model_value); end
  describe ".model_reader" do
    before(:each) do
      @model = ModelReaderModel.new
      @view_model = ViewModels::Base.new(@model, nil)
      class << @view_model
        def a(s); s << 'a' end
        def b(s); s << 'b' end
      end
    end
    it "should call filters in a given pattern" do
      @model.some_model_value = 's'
      @view_model.class.model_reader :some_model_value, :filter_through => [:a, :b, :a, :a]
    
      @view_model.some_model_value.should == 'sabaa'
    end
    it "should pass through the model value if no filters are installed" do
      @model.some_model_value = :some_model_value
      @view_model.class.model_reader :some_model_value
      
      @view_model.some_model_value.should == :some_model_value
    end
  end
  
  describe ".master_helper_module" do
    before(:each) do
      class ViewModels::SpecificMasterHelperModule < ViewModels::Base; end
    end
    it "should be a class specific inheritable accessor" do
      ViewModels::SpecificMasterHelperModule.master_helper_module = :some_value
      ViewModels::SpecificMasterHelperModule.master_helper_module.should == :some_value
    end
    it "should be an instance of Module on Base" do
      ViewModels::Base.master_helper_module.should be_instance_of(Module)
    end
  end
  
  describe ".controller_method" do
    it "should set up delegate calls to the controller" do
      ViewModels::Base.should_receive(:delegate).once.with(:method1, :to => :controller)
      ViewModels::Base.should_receive(:delegate).once.with(:method2, :to => :controller)
      
      ViewModels::Base.controller_method :method1, :method2
    end
  end
  
  describe ".helper" do
    it "should include the helper" do
      helper_module = Module.new
      
      ViewModels::Base.should_receive(:include).once.with helper_module
      
      ViewModels::Base.helper helper_module
    end
    it "should include the helper in the master helper module" do
      master_helper_module = Module.new
      ViewModels::Base.should_receive(:master_helper_module).and_return master_helper_module
      
      helper_module = Module.new
      master_helper_module.should_receive(:include).once.with helper_module
      
      ViewModels::Base.helper helper_module
    end
  end
    
  describe ".presenter_path" do
    it "should call underscore on its name" do
      name = stub :name
      ViewModels::Base.should_receive(:name).once.and_return name
      name.should_receive(:underscore).once.and_return :underscored_name
      
      ViewModels::Base.view_model_path.should == :underscored_name
    end
  end
  
  describe "#logger" do
    it "should delegate to the controller" do
      controller = stub :controller
      view_model = ViewModels::Base.new nil, controller
      
      controller.should_receive(:logger).once
      
      in_the view_model do
        logger
      end
    end
  end
  
  describe "with mocked Presenter" do
    before(:each) do
      @model = stub :model
      @context = stub :context
      @view_model = ViewModels::Base.new model, context
    end
    describe "#render_as" do
      before(:each) do
        @view_name = stub :view_name
        @view_instance_mock = stub :view_instance
        
        view_model.should_receive(:view_instance).once.and_return @view_instance_mock
        
        path_mock = flexmock(:path)
        flexmock(view_model).should_receive(:template_path).once.with(@view_name).and_return path_mock
        
        @view_instance_mock.should_receive(:render).once.with(
          :partial => path_mock, :locals => { :view_model => view_model }
        )
      end
      it "should not call template_format=" do
        @view_instance_mock.should_receive(:template_format=).never

        view_model.render_as(@view_name)
      end
      it "should call template_format=" do
        @view_instance_mock.should_receive(:template_format=).once.with(:some_format)

        view_model.render_as(@view_name, :some_format)
      end
    end
    
    describe "#presenter_template_path" do
      describe "absolute path given" do
        it "should use it as given" do
          in_the view_model do
            template_path('some/path/to/template').should == 'some/path/to/template'
          end
        end
      end
      describe "with just the template name" do
        it "should prepend the view_model path" do
          flexmock(ViewModels::Base).should_receive(:view_model_path).and_return('some/view_model/path/to')
          
          in_the view_model do
            template_path('template').should == 'some/view_model/path/to/template'
          end
        end
      end
    end
    
    describe "#view_instance" do
      it "should create a new view instance from ActionView::Base" do
        view_paths_mock = flexmock(:view_paths)
        context_mock.should_receive('class.view_paths').once.and_return(view_paths_mock)
        
        flexmock(ActionView::Base).should_receive(:new).once.with(view_paths_mock, {}, @context_mock)
        in_the view_model do
          view_instance
        end
      end
      it "should extend the view instance with the master helper module" do
        master_helper_module_mock = flexmock(:master_helper_module)
        flexmock(view_model).should_receive(:master_helper_module).and_return(master_helper_module_mock)
        
        view_instance_mock = flexmock(:view_instance)
        view_instance_mock.should_receive(:extend).with(master_helper_module_mock)
        
        context_mock.should_receive('class.view_paths').once
        flexmock(ActionView::Base).should_receive(:new).once.and_return view_instance_mock
        
        in_the view_model do
          view_instance
        end
      end
    end
  end
  
end