#
# Cookbook:: fb_letsencrypt
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

package 'certbot packages' do
  only_if { node['fb_letsencrypt']['manage_packages'] }
  package_name lazy {
    (
      %w{certbot} + node['fb_letsencrypt']['certbot_plugins'].map do |plugin|
        "python3-certbot-#{plugin}"
      end
    ).uniq
  }
  action :upgrade
end

service 'conditionally enable certbot.timer' do
  only_if { node['fb_letsencrypt']['enable_package_timer'] }
  service_name 'certbot.timer'
  action :enable
end

service 'conditionally disable certbot.timer' do
  not_if { node['fb_letsencrypt']['enable_package_timer'] }
  service_name 'certbot.timer'
  action :disable
end
