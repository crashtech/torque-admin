extend Torque::Admin::LazyConstants

lazy_constant(:Resource) { Class.new(Torque::Admin::Resource) }

## Primary gem Controllers

lazy_constant(:BaseController) do |mod|
  klass = Class.new(mod.admin_application.config.base_controller!.constantize)
  klass.include(Torque::Admin::BaseController)
  klass.abstract!
  klass
end

lazy_constant(:ResourceController) do |mod|
  klass = Class.new(mod::BaseController)
  klass.include(Torque::Admin::ResourceController)
  klass.abstract!
  klass
end

lazy_constant(:DashboardController) do |mod|
  klass = Class.new(mod::BaseController)
  klass.include(Torque::Admin::DashboardController)
  klass.abstract!
  klass
end

lazy_constant(:SimpleController) do |mod|
  klass = Class.new(mod::ResourceController)
  klass.include(Torque::Admin::SimpleController)
  klass
end

## Devise Intergration

lazy_constant(:Devise) do
  Module.new do
    extend Torque::Admin::LazyConstants


  end
end
