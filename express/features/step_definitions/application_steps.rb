require 'fileutils'

include RHCHelper

Given /^an existing (.+) application with an embedded (.*) cartridge$/ do |type, embed|
  App.find_on_fs.each do |app|
    if app.type == type and app.embed.include?(embed)
      @app = app
      break
    end
  end

  @app.should_not be_nil
end

Given /^an existing (.+) application( without an embedded cartridge)?$/ do |type, ignore|
  App.find_on_fs.each do |app|
    if app.type == type and app.embed.empty?
      @app = app
      break
    end
  end

  @app.should_not be_nil
end

When /^(\d+) (.+) applications are created$/ do |app_count, type|
  # Create our domain and apps
  @apps = app_count.to_i.times.collect do
    app = App.create_unique(type)

    # Don't create the domain if a global namespace is set
    app.rhc_domain_create unless $namespace
    app.rhc_app_create
    app
  end
end

When /^the application is stopped$/ do
  @app.rhc_app_stop
end

When /^the application is started$/ do
  @app.rhc_app_start
end

When /^the application is restarted$/ do
  @app.rhc_app_restart
end

When /^the application is destroyed$/ do
  @app.rhc_app_destroy
end

When /^the application is snapshot$/ do
  @snapshot = File.join($temp, "snapshot.tar.gz")
  @app.snapshot = @snapshot
  @app.rhc_app_snapshot_save
end

When /^the application is tidied$/ do
  @app.rhc_app_tidy
end

Then /^the snapshot should be found$/ do
  File.exist?(@snapshot).should be_true
  (File.size(@snapshot) > 0).should be_true
end

Then /^the applications should be accessible?$/ do
  @apps.each do |app|
    app.is_accessible?.should be_true
    app.is_accessible?(true).should be_true
  end
end

Then /^the application should be accessible$/ do
  @app.is_accessible?.should be_true
  @app.is_accessible?(true).should be_true
end

Then /^the application should not be accessible$/ do
  @app.is_inaccessible?.should be_true
end

Then /^it should succeed$/ do
end
