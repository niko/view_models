require File.join(File.dirname(__FILE__), '../spec_helper')

require File.join(File.dirname(__FILE__), 'models/subclass')
require File.join(File.dirname(__FILE__), 'models/sub_subclass')

require 'helpers/rails'
ActionView::Base.send :include, ViewModels::Helper::Rails

require 'view_models/base'
require File.join(File.dirname(__FILE__), 'view_models/subclass')
require File.join(File.dirname(__FILE__), 'view_models/sub_subclass')


describe 'Integration' do
  
  before(:each) do
    @logger           = stub :logger
    @controller_class = stub :klass, :view_paths => 'spec/integration/views', :controller_path => 'app/controllers/test'
    @context          = stub :controller, :class => @controller_class, :logger => @logger
    @view_paths       = stub :view_paths
    @view             = stub :view, :controller => @context, :view_paths => @view_paths
    @model            = SubSubclass.new
    @view_model       = ViewModels::SubSubclass.new @model, @view
  end
  
  describe 'view_model_for inclusion in view' do
    it 'should be included' do
      view = ViewModels::View.new @context, Module.new
      
      lambda {
        view.view_model_for @model
      }.should_not raise_error
    end
  end
  
  # describe 'collection rendering' do
  #   it 'should description' do
  #     @view_model.render_as(:list_example).should == 'html exists' # The default
  #   end
  # end
  
  describe 'model attributes' do
    it 'should pass through unfiltered attributes' do
      @view_model.some_untouched_attribute.should == :some_value
    end
    it 'should filter some attributes' do
      @view_model.some_filtered_attribute.should == '%3Cscript%3Efilter+me%3C%2Fscript%3E'
    end
    it 'should filter some attributes multiple times' do
      @view_model.some_doubly_doubled_attribute.should == 'blahblahblahblah'
    end
    it 'should filter some attributes multiple times correctly' do
      @view_model.some_mangled_attribute.should == 'DCBDCB'
    end
  end
  
  describe 'controller_method' do
    it 'should delegate to the context' do
      @view_model.logger.should == @logger
    end
  end
  
  describe 'render_as' do
    describe 'template inheritance' do
      it "should use its template" do
        @view_model.render_as(:exists).should == 'html exists' # The default
      end
      it "should use the subclass' template" do
        @view_model.render_as(:no_sub_subclass).should == 'no sub subclass'
      end
      it "should fail" do
        @view_model.render_as(:none).should == nil
      end
    end
    describe 'format' do
      it 'should render html' do
        @view_model.render_as(:exists, :format => nil).should == 'html exists' # the default
      end
      it 'should render erb' do
        @view_model.render_as(:exists, :format => '').should == 'exists'
      end
      it 'should render text' do
        @view_model.render_as(:exists, :format => :text).should == 'text exists'
      end
      it 'should render html' do
        @view_model.render_as(:exists, :format => :html).should == 'html exists'
      end
    end
    describe 'locals' do
      it 'should render html' do
        @view_model.render_as(:exists, :locals => { :local_name => :some_local }).should == 'html exists with some_local'
      end
      it 'should render html' do
        @view_model.render_as(:exists, :format => nil, :locals => { :local_name => :some_local }).should == 'html exists with some_local'
      end
      it 'should render text' do
        @view_model.render_as(:exists, :format => '', :locals => { :local_name => :some_local }).should == 'exists with some_local'
      end
      it 'should render text' do
        @view_model.render_as(:exists, :format => :text, :locals => { :local_name => :some_local }).should == 'text exists with some_local'
      end
      it 'should render html' do
        @view_model.render_as(:exists, :format => :html, :locals => { :local_name => :some_local }).should == 'html exists with some_local'
      end
    end
    describe 'memoizing' do
      it 'should memoize' do
        @view_model.class.should_receive(:template_path).once.with(:not_found_in_sub_subclass).and_return 'view_models/sub_subclass/not_found_in_sub_subclass'
        @view_model.class.superclass.should_receive(:template_path).once.with(:not_found_in_sub_subclass).and_return 'view_models/subclass/not_found_in_sub_subclass'
        
        @view_model.render_as :not_found_in_sub_subclass
        @view_model.render_as :not_found_in_sub_subclass
        @view_model.render_as :not_found_in_sub_subclass
        @view_model.render_as :not_found_in_sub_subclass
        @view_model.render_as :not_found_in_sub_subclass
        
        @view_model.render_as(:not_found_in_sub_subclass).should == 'not found'
      end
      it 'should render the right one' do
        @view_model.render_as :exists_in_both
        @view_model.render_as(:exists_in_both).should == 'in sub subclass'
        
        other_view_model = ViewModels::Subclass.new Subclass.new, @view
        other_view_model.render_as :exists_in_both
        other_view_model.render_as(:exists_in_both).should == 'in subclass'
        
        @view_model.render_as :exists_in_both
        @view_model.render_as(:exists_in_both).should == 'in sub subclass'
      end
      it 'should memoize nil if nothing is found' do
        @view_model.render_as(:blargl)
        @view_model.render_as(:blargl)
        @view_model.render_as(:blargl)
        @view_model.render_as(:blargl).should == nil
      end
    end
  end
  
end