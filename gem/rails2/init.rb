# require 'experimental/modules_in_render_hierarchy'

this = File.dirname __FILE__

require File.join(this, '/lib/view_models')
require File.join(this, '/../shared/init')
require File.join(this, '/lib/view_models/base')
require File.join(this, '/lib/view_models/view')

require File.join(this, '/lib/helpers/view')
require File.join(this, '/lib/helpers/collection')

ActionController::Base.send :include, ViewModels::Helpers::Mapping
ActionView::Base.send       :include, ViewModels::Helpers::Mapping