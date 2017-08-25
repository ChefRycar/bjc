#
# Cookbook Name:: bjc-ecommerce
# Recipe:: cart
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

ruby_block "fix_encoding" do
  block do
    Encoding.default_internal = nil
  end
end

remote_file "#{Chef::Config['file_cache_path']}/softslate-3.3.6.war" do
  action :create
  source 'https://s3-us-west-2.amazonaws.com/bjcpublic/softslate-commerce/softslate-3.3.6.war'
  mode 644
end

execute "Install Shopping Cart" do
  command "cp -a #{Chef::Config['file_cache_path']}/softslate-3.3.6.war /var/lib/tomcat7/webapps/cart.war"
  action :run
  not_if { File.exist?("/var/lib/tomcat7/webapps/cart.war") }
  notifies :run, 'ruby_block[Sleep my pretty...]', :immediate
end

ruby_block "Sleep my pretty..." do
  block do
    sleep(60)
  end
  action :nothing
end

basedir = '/var/lib/tomcat7/webapps/cart/WEB-INF'

directory "#{basedir}/src" do
  action :create
end

directory "#{basedir}/classes" do
  action :create
end

%w(appSettings hibernate log4j).each do |f|
  template "#{basedir}/src/#{f}.properties" do
    source "src/#{f}.properties.erb"
    action :create
  end
end

%w(appSettings hibernate log4j).each do |f|
  template "#{basedir}/classes/#{f}.properties" do
    source "classes/#{f}.properties.erb"
    action :create
  end
end

template "#{Chef::Config['file_cache_path']}/backup.sql" do
  action :create
  source 'backup.sql.erb'
  notifies :run, 'execute[restore_database_backup]', :immediately
end

execute "restore_database_backup" do
  command "mysql -u root softslate < #{Chef::Config['file_cache_path']}/backup.sql"
  action :nothing
  notifies :restart, 'service[tomcat7]', :delayed
end

%w(f73e89fd.0 sdk-seller.p12 twoWay.key).each do |f|
  cookbook_file "/var/lib/tomcat7/webapps/cart/WEB-INF/conf/keys/#{f}" do
    action :create
    source f
  end
end

service 'tomcat7' do
  action :restart
end
