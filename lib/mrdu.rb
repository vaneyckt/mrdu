require 'trollop'
require 'systemu'

def unmount_ramdisk_mount(ramdisk_dir)
  check_cmd = <<-CMD
    sudo stat -f -c '%T' #{ramdisk_dir}
  CMD

  unmount_cmd = <<-CMD
    sudo umount #{ramdisk_dir}
  CMD

  status, stdout, stderr = systemu(check_cmd)
  while stdout.include?('tmpfs')
    status, stdout, stderr = systemu(unmount_cmd)
    puts "Unmount ramdisk mount - status: #{status} - stdout: #{stdout} - stderr: #{stderr}"
    status, stdout, stderr = systemu(check_cmd)
  end
end

def create_ramdisk_mount(ramdisk_dir, ramdisk_size)
  cmd = <<-CMD
    sudo mkdir -p #{ramdisk_dir} &&
    sudo mount -t tmpfs -o size=#{ramdisk_size}M tmpfs #{ramdisk_dir}
  CMD
  status, stdout, stderr = systemu(cmd)
  puts "Create ramdisk mount - status: #{status} - stdout: #{stdout} - stderr: #{stderr}"
end

def create_data_location(ramdisk_dir, mysql_data_dir)
  cmd = <<-CMD
    sudo mkdir -p #{ramdisk_dir}#{mysql_data_dir}
    sudo chown -R mysql.mysql #{ramdisk_dir}#{mysql_data_dir}
  CMD
  status, stdout, stderr = systemu(cmd)
  puts "Create mysql data location on ramdisk - status: #{status} - stdout: #{stdout} - stderr: #{stderr}"
end

def create_log_location(ramdisk_dir, mysql_log_dir)
  cmd = <<-CMD
    sudo mkdir -p #{ramdisk_dir}#{mysql_log_dir}
    sudo chown -R mysql.mysql #{ramdisk_dir}#{mysql_log_dir}
  CMD
  status, stdout, stderr = systemu(cmd)
  puts "Create mysql log location on ramdisk - status: #{status} - stdout: #{stdout} - stderr: #{stderr}"
end

def create_socket_location(ramdisk_dir, mysql_socket_dir)
  cmd = <<-CMD
    sudo mkdir -p #{ramdisk_dir}#{mysql_socket_dir}
    sudo chown -R mysql.mysql #{ramdisk_dir}#{mysql_socket_dir}
  CMD
  status, stdout, stderr = systemu(cmd)
  puts "Create mysql socket location on ramdisk - status: #{status} - stdout: #{stdout} - stderr: #{stderr}"
end

def create_tmp_location(ramdisk_dir, mysql_tmp_dir)
  cmd = <<-CMD
    sudo mkdir -p #{ramdisk_dir}#{mysql_tmp_dir}
    sudo chown -R mysql.mysql #{ramdisk_dir}#{mysql_tmp_dir}
  CMD
  status, stdout, stderr = systemu(cmd)
  puts "Create mysql temp location on ramdisk - status: #{status} - stdout: #{stdout} - stderr: #{stderr}"
end

def create_config_file(ramdisk_dir, ramdisk_mysql_port, mysql_data_dir, mysql_log_dir, mysql_socket_dir, mysql_config_dir, mysql_tmp_dir, mysql_port)
  cmd = <<-CMD
    sudo mkdir -p #{ramdisk_dir}#{mysql_config_dir}
    sudo cp -R #{mysql_config_dir}/* #{ramdisk_dir}#{mysql_config_dir}
  CMD
  status, stdout, stderr = systemu(cmd)
  puts "Create mysql config file on ramdisk - status: #{status} - stdout: #{stdout} - stderr: #{stderr}"

  cmd = <<-CMD
    sudo sed -i 's|#{mysql_port}|#{ramdisk_mysql_port}|g'                   #{ramdisk_dir}#{mysql_config_dir}/my.cnf
    sudo sed -i 's|#{mysql_data_dir}|#{ramdisk_dir}#{mysql_data_dir}|g'     #{ramdisk_dir}#{mysql_config_dir}/my.cnf
    sudo sed -i 's|#{mysql_log_dir}|#{ramdisk_dir}#{mysql_log_dir}|g'       #{ramdisk_dir}#{mysql_config_dir}/my.cnf
    sudo sed -i 's|#{mysql_socket_dir}|#{ramdisk_dir}#{mysql_socket_dir}|g' #{ramdisk_dir}#{mysql_config_dir}/my.cnf
    sudo sed -i 's|#{mysql_config_dir}|#{ramdisk_dir}#{mysql_config_dir}|g' #{ramdisk_dir}#{mysql_config_dir}/my.cnf
    sudo sed -i 's|#{mysql_tmp_dir}$|#{ramdisk_dir}#{mysql_tmp_dir}|g'      #{ramdisk_dir}#{mysql_config_dir}/my.cnf
  CMD
  status, stdout, stderr = systemu(cmd)
  puts "Setup mysql config file on ramdisk - status: #{status} - stdout: #{stdout} - stderr: #{stderr}"
end

def initialize_data_location(ramdisk_dir, mysql_data_dir)
  cmd = <<-CMD
    sudo mysql_install_db --user=mysql --datadir=#{ramdisk_dir}#{mysql_data_dir}
  CMD
  status, stdout, stderr = systemu(cmd)
  puts "Initialize mysql data location on ramdisk - status: #{status} - stdout: #{stdout} - stderr: #{stderr}"
end

def start_mysql_server(ramdisk_dir, mysql_config_dir)
  cmd = <<-CMD
    sudo mysqld_safe --defaults-file=#{ramdisk_dir}#{mysql_config_dir}/my.cnf &
  CMD
  status, stdout, stderr = systemu(cmd)
  puts "Start mysql server on ramdisk - status: #{status} - stdout: #{stdout} - stderr: #{stderr}"
end

def stop_mysql_server(ramdisk_dir, mysql_socket_dir)
  cmd = <<-CMD
    sudo cat #{ramdisk_dir}#{mysql_socket_dir}/mysqld.pid
  CMD
  status, stdout, stderr = systemu(cmd)
  pid = stdout

  cmd = <<-CMD
    sudo kill #{pid}
  CMD
  status, stdout, stderr = systemu(cmd)
  puts "Killing mysql server on ramdisk - status: #{status} - stdout: #{stdout} - stderr: #{stderr}"
end


opts = Trollop::options do
  opt :ramdisk_mysql_port, 'Set the desired port of the mysql server running on ramdisk',                  :type => :integer, :default => 3307
  opt :ramdisk_size,       'Set the desired size (in MB) of your ramdisk',                                 :type => :integer, :default => 512
  opt :ramdisk_dir,        'Set the desired directory to be used as the ramdisk mount',                    :type => :string,  :default => '/tmp/ramdisk'
  opt :mysql_port,         'Specify the port used by the mysql server currently on your machine',          :type => :integer, :default => 3306
  opt :mysql_data_dir,     'Specify the location of the mysql data directory currently on your machine',   :type => :string,  :default => '/var/lib/mysql'
  opt :mysql_log_dir,      'Specify the location of the mysql log directory currently on your machine',    :type => :string,  :default => '/var/log/mysql'
  opt :mysql_socket_dir,   'Specify the location of the mysql socket directory currently on your machine', :type => :string,  :default => '/var/run/mysqld'
  opt :mysql_config_dir,   'Specify the location of the mysql config directory currently on your machine', :type => :string,  :default => '/etc/mysql'
  opt :mysql_tmp_dir,      'Specify the location of the mysql tmp directory currently on your machine',    :type => :string,  :default => '/tmp'
end

unmount_ramdisk_mount     opts[:ramdisk_dir]
create_ramdisk_mount      opts[:ramdisk_dir], opts[:ramdisk_size]
create_data_location      opts[:ramdisk_dir], opts[:mysql_data_dir]
create_log_location       opts[:ramdisk_dir], opts[:mysql_log_dir]
create_socket_location    opts[:ramdisk_dir], opts[:mysql_socket_dir]
create_tmp_location       opts[:ramdisk_dir], opts[:mysql_tmp_dir]
create_config_file        opts[:ramdisk_dir], opts[:ramdisk_mysql_port], opts[:mysql_data_dir], opts[:mysql_log_dir], opts[:mysql_socket_dir], opts[:mysql_config_dir], opts[:mysql_tmp_dir], opts[:mysql_port]
initialize_data_location  opts[:ramdisk_dir], opts[:mysql_data_dir]
start_mysql_server        opts[:ramdisk_dir], opts[:mysql_config_dir]

puts "\n\n"
puts "MySQL is now running."
puts "Configure your client to use the root user, no password, host 127.0.0.1, and port #{opts[:ramdisk_mysql_port]}."
puts "To force a TCP/IP connection, do not use localhost, but use 127.0.0.1 instead. See http://dev.mysql.com/doc/refman/5.1/en/connecting.html for more info."
puts "Just press ^C when you no longer need it."

Signal.trap('SIGHUP')  { stop_mysql_server(opts[:ramdisk_dir], opts[:mysql_socket_dir]); exit }
Signal.trap('SIGINT')  { stop_mysql_server(opts[:ramdisk_dir], opts[:mysql_socket_dir]); exit }
Signal.trap('SIGQUIT') { stop_mysql_server(opts[:ramdisk_dir], opts[:mysql_socket_dir]); exit }
Signal.trap('SIGKILL') { stop_mysql_server(opts[:ramdisk_dir], opts[:mysql_socket_dir]); exit }
Signal.trap('SIGTERM') { stop_mysql_server(opts[:ramdisk_dir], opts[:mysql_socket_dir]); exit }

while true
  sleep 1000000
end
