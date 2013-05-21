#
# Cookbook Name:: nginx
# Recipe:: ngx_pagespeed_module
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

zip_location = "#{Chef::Config['file_cache_path']}/ngx_pagespeed.zip"
module_location = "#{Chef::Config['file_cache_path']}/ngx_pagespeed"

psol_tar_location = "#{Chef::Config['file_cache_path']}/psol.tar.gz"

package "unzip" do
  action :install
end

# Download ngx_pagespeed
remote_file zip_location do
  source node['nginx']['ngx_pagespeed']['source_url']
  checksum node['nginx']['ngx_pagespeed']['source_checksum']
  owner 'root'
  group 'root'
  mode 0644
end

directory module_location do
  owner "root"
  group "root"
  mode 0755
  recursive true
  action :create
end

# Download psol
remote_file psol_tar_location do
  source node['nginx']['psol']['source_url']
  checksum node['nginx']['psol']['source_checksum']
  owner 'root'
  group 'root'
  mode 0644
end

# Create FileCachePath
directory node['nginx']['ngx_pagespeed']['pagespeed']['FileCachePath'] do
  owner "root"
  group "root"
  mode 00755
  recursive true
  action :create
end

bash "extract_ngx_pagespeed" do
  cwd ::File.dirname(zip_location)
  user 'root'
  code <<-EOH
    unzip #{zip_location} -d #{module_location}
    mv -f #{module_location}/ngx_pagespeed*/* #{module_location}
    rm -rf #{module_location}/ngx_pagespeed*
    tar -xzvf #{psol_tar_location} -C #{module_location}
  EOH

  not_if { ::File.exists?("#{module_location}/config") }

end

node.run_state['nginx_configure_flags'] =
    node.run_state['nginx_configure_flags'] | ["--add-module=#{module_location}"]
