#!/bin/bash
          create_user(){
          #. $1 => username
          #. $2 => ssh public key
          echo "creating { $1 } system user..."
          useradd -m $1 && mkdir /home/$1/.ssh
          usermod -s /bin/bash -aG sudo $1
          echo "$1:1234567890" | chpasswd
          echo "$2" > /home/$1/.ssh/authorized_keys
          }
          create_ssh_2fa(){
          echo "enabling the ssh password authentication..."
          sed -i 's/PasswordAuthentication\ no/PasswordAuthentication\ yes/g' /etc/ssh/sshd_config
          sed -i 's/ChallengeResponseAuthentication\ no/ChallengeResponseAuthentication\ yes\nAuthenticationMethods publickey,password/g' /etc/ssh/sshd_config
          systemctl reload sshd
          }
          create_motd(){
          echo "creating { message of the day } ..."
          cat << "EOF" > /etc/motd
                                     )        (       )     )
           (      *   )  *   )    ( /(   *   ))\ ) ( /(  ( /(
           )\   ` )  /(` )  /((   )\())` )  /(()/( )\()) )\())
          ((((_)(  ( )(_))( )(_))\ ((_)\  ( )(_))(_)|(_)\ ((_)\
           )\ _ )\(_(_())(_(_()|(_) _((_)(_(_()|_))   ((_) _((_)
           (_)_\(_)_   _||_   _| __| \| ||_   _|_ _| / _ \| \| |
            / _ \   | |    | | | _|| .` |  | |  | | | (_) | .` |
           /_/ \_\  |_|    |_| |___|_|\_|  |_| |___| \___/|_|\_|

          #######################################################################
          This system is for the use of authorized users only. This system is a
          property of Mobisy Technologies. Individuals using this computer system
          are subject to having all their activities on this system monitored and
          recorded by system personnel. Any misuse will be liable for prosecution
          or other disciplinary actions.

          ** DISCONNECT IMMIDIATELY IF YOU ARE NOT AUTHORIZED PERSON !!!

          #######################################################################
          EOF
          }
          create_user nikhil "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyiM7EagNkeh0FCMLMVsj5GDk4yydcpi5tNg3pNqyc5dEvuNhzl/wPdFLStByXE1l0cm3axB6gnpvk3Bp+DcRzER3X6Ym+Gf9Gt6h0vWKdLBhVYS3tpK29G0VK8kn/BQ1hkXZ6cLGwbWFc8pIVTwqsC/u2j4ojlDGNwfhiyd2XJdDi+eR2qbgbxPA/rQ7ls0EZq6tAPhwlQGC6a3xVG8xMT04gVbue5Jub/WryBBT7YnYAOscGPdyxkygFDtQa2eeCNRPI9d0ZmVrpOc3L3f+O3JSo1Q0fGnDd1gwOYQlla0oqqQwTP9dJjHyAgwI8vPJlywgmsRP8+X4e4xFWrlUgw== nikhil@nikhil-laptop"
          create_user bhupendra "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDhrY3Ma206sEDoU+FvwcusZVfXvhk8TjZeiUZ4H5xyK5dVaiftrrnt+VJfw+FpS2N5JUmkP32bMZc6yKWHlJmOj1VaUco2aP9Cv/qxGfhIbofM/H4Cs69+gmWQGsN5vi0jIZtKPMGlophpUb6foesZkus8fONzzW/YKNrQpX/Ij6JhIK5sZPjdTMLnr3Qpsj0MPLL6ePJk2M4jsUtXGZ4KfBE6hZtUEH8m9+znDkhqSqvyGkiVbD5GP6dIIBbMn3gGHNT7juislBUoBiosvXyioGPxO1n/1x4LQOynfpIv5G7act18mNRXvRl+kIlFYX2FHRmU+wK/KbwnT2DwPeM7SiJh7YvOKka0rfvwpe28qGdZwD3fJbiZkNph/pQGwHtFavw5qO+QYn9RsZKcQ0Mi1xqF8tHBVd/pjB1IfeguF75a9KvvywKyyFuuvGyo/IhntUESVmstZs3831g4izJe9hcG3PZaht03wuxxJ6S7neFiUOErPVXdfrNHNG6Kh+8= bhupendra@MTPL-LT-DE-222"
          create_user sateesh "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDc1aWf9aCOea+Exe7zQ2WwcGWPKO4FYUhnpdplJX2DqCu3ryNwkFXw8PWAdF8pbfTH99bZBEN6Pk07SWPhsXlupwObaintJ+Zsr/zxA4oAV7ym8feESuon78xM9lOvXlbgx2t9M6FgPp9ZLyw+sChtmt1RbkNYGgAo9XZ1LCH9hASf79CxRSKgVGQ/UgOjW+QRzf2KGfaD7PYtov1nz0AT8W0mmtIXsl4qVwaVyEWUlcQionI2923SOau5mCJwNDc/O37mZ8A5GAaejMOPwB3ycxv1Q3tCYsbtslpLzvlfnyIRh/mMiQlJ7DisVWk1IcFLKwQ5stfTCTbt2jn328RELL/2TQw7FUI4m/A+sBDOc4KRw8Ntitpi23oqTTaHRzlOELCnU1/tLMmN5gwKoXsuZ4Crm0oNOew/Gpy/c9blH56Qj+hB/YWnFWARhKbuK1hFQJY4BINDYLUVaFYbduVoiyjeN9HuNzoG4vU/s3DEIrDQiHabiNfLfNz+9/Cot30= sateeshp@MTPL-LT-DE-241"
          create_motd
          create_ssh_2fa
          sudo apt update
          sudo apt upgrade -y 
          sudo apt install nginx -y
          sudo apt install zip -y
          sudo apt install -y xvfb libfontconfig wkhtmltopdf
          sudo apt install software-properties-common
          sudo add-apt-repository ppa:ondrej/php -y
          sudo apt update
          sudo apt install -y php7.2-{cli,common,gd,intl,zip,ssh2,fpm,curl,mysql,mbstring,pgsql}
          sudo apt install composer -Y
          sudo apt install php7.2-redis -y
          #/etc/nginx/sites-enabled/default the following lines will be added to default file
          sudo cat <<EOF > default_new
          server {
          listen                  80;
          listen                  443 ssl;
          server_name             \$host;
          ssl_session_cache       shared:SSL:20m;
          ssl_session_timeout     180m;
          ssl_certificate         /etc/nginx/ssl/bizom.in.crt;
          ssl_certificate_key     /etc/nginx/ssl/bizom.in.key;
          ssl_protocols           TLSv1 TLSv1.1 TLSv1.2;
          ssl_prefer_server_ciphers       on;
          ssl_dhparam             /etc/nginx/ssl/dhparam.pem;
          root                    /var/sites/\$host/app/webroot;
          index                   index.php index.html;
          if (!-e \$request_filename) {
          rewrite ^/(.+)\$ /index.php?url=\$1 last;
          break;
          }
          location ~ ^/(.+\.php)\$ {
          fastcgi_pass 127.0.0.1:9000;
          fastcgi_index           index.php;
          fastcgi_param           SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
          include                 fastcgi_params;
          }
          }
          EOF
          sudo cp default_new /etc/nginx/sites-enabled/default
          rm -rf default_new
          #/etc/nginx/fastcgi_params remove 19th line in the fastcgi_params files
          sed -i '20d' /etc/nginx/fastcgi_params 
          #/etc/nginx/nginx.conf change the following lines in the nginx.conf file           
          sed -i '4d' /etc/nginx/nginx.conf        
          sudo sed -i "4 i #include /etc/nginx/modules-enabled/*.conf;" /etc/nginx/nginx.conf
          sudo sed -i "5 i worker_rlimit_nofile 300000;" /etc/nginx/nginx.conf
          sudo sed -i "s/worker_connections 768;/worker_connections 3028;/" /etc/nginx/nginx.conf
          sudo sed -i "14 i real_ip_header X-Forwarded-For;" /etc/nginx/nginx.conf
          sudo sed -i "15 i set_real_ip_from 0.0.0.0/0;" /etc/nginx/nginx.conf
          sudo sed -i "16 i #include blockedips.conf;" /etc/nginx/nginx.conf
          sudo sed -i "17 i send_timeout 10m;" /etc/nginx/nginx.conf
          sudo sed -i "18 i fastcgi_connect_timeout 1800s;" /etc/nginx/nginx.conf
          sudo sed -i "19 i fastcgi_send_timeout 1800s;" /etc/nginx/nginx.conf
          sudo sed -i "20 i fastcgi_read_timeout 1800s;" /etc/nginx/nginx.conf
          sudo sed -i "21 i fastcgi_buffer_size 128k;" /etc/nginx/nginx.conf
          sudo sed -i "22 i fastcgi_buffers 8 128k;" /etc/nginx/nginx.conf
          sudo sed -i "23 i client_header_buffer_size 64k;" /etc/nginx/nginx.conf
          sudo sed -i "24 i client_max_body_size 2000M;" /etc/nginx/nginx.conf
          sudo sed -i "25 i large_client_header_buffers 16 2048m;" /etc/nginx/nginx.conf
          sudo sed -i "26 i log_format fullurl '\$remote_addr - \$remote_user [\$time_local]  '" /etc/nginx/nginx.conf
          sudo sed -i "27 i '\"\$host\" - \"\$request\" \$status \$body_bytes_sent '" /etc/nginx/nginx.conf
          sudo sed -i "28 i '\"\$http_referer\" \"\$http_user_agent\"';" /etc/nginx/nginx.conf
          sudo sed -i "34 i tcp_nodelay on;" /etc/nginx/nginx.conf
          sudo sed -i "35 i keepalive_timeout 65;" /etc/nginx/nginx.conf
          sudo sed -i "65 i gzip_disable "msie6";" /etc/nginx/nginx.conf
          sudo sed -i "66 i gzip_vary on;" /etc/nginx/nginx.conf
          sudo sed -i "67 i gzip_proxied any;" /etc/nginx/nginx.conf
          sudo sed -i "68 i gzip_comp_level 6;" /etc/nginx/nginx.conf
          sudo sed -i "69 i gzip_buffers 16 8k;" /etc/nginx/nginx.conf
          sudo sed -i "70 i gzip_http_version 1.1;" /etc/nginx/nginx.conf
          sudo sed -i "71 i gzip_types text\/plain text\/css application\/json application\/javascript text\/xml application\/xml application\/xml+rss text\/javascript;" /etc/nginx/nginx.conf
          #/etc/php/7.2/fpm/php-fpm.conf change the followinglines
          sudo sed -i "s/;emergency_restart_threshold = 0/emergency_restart_threshold = 10/" /etc/php/7.2/fpm/php-fpm.conf
          sudo sed -i "s/;emergency_restart_interval = 0/emergency_restart_interval = 1m/" /etc/php/7.2/fpm/php-fpm.conf
          sudo sed -i "s/;process_control_timeout = 0/process_control_timeout = 10s/" /etc/php/7.2/fpm/php-fpm.conf
          sudo sed -i "s/;rlimit_files = 1024/rlimit_files = 300000/" /etc/php/7.2/fpm/php-fpm.conf
          #/etc/php/7.2/fpm/php.ini change the following lines
          sudo sed -i "s/implicit_flush = Off/implicit_flush = On/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/serialize_precision = -1/serialize_precision = 17/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/max_execution_time = 30/max_execution_time = 1800/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/; max_input_vars = 1000/max_input_vars = 30000/" /etc/php/7.2/fpm/php.ini  
          sudo sed -i "s/memory_limit = 128M/memory_limit = 4096M/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/;track_errors = Off/track_errors = Off/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/post_max_size = 8M/post_max_size = 100M/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 100M/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/mail.add_x_header = Off/mail.add_x_header = On/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/session.save_handler = files/; session.save_handler = files/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "1351 i session.save_handler = redis" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/session.cookie_lifetime = 0/session.cookie_lifetime = 2628000/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/session.cookie_httponly =/session.cookie_httponly = 1/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 86400/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/session.cache_expire = 180/session.cache_expire = 180000/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "s/;opcache.memory_consumption=128/opcache.memory_consumption=128/" /etc/php/7.2/fpm/php.ini
          sudo sed -i "1074 i [SQL]" /etc/php/7.2/fpm/php.ini
          sudo sed -i "1075 i ; http://php.net/sql.safe-mode" /etc/php/7.2/fpm/php.ini 
          sudo sed -i "1076 i sql.safe_mode = Off" /etc/php/7.2/fpm/php.ini 
          sudo sed -i "1350 i session.save_path = "staging-bizom-cache.nzjbxa.0001.aps1.cache.amazonaws.com:6379"" /etc/php/7.2/fpm/php.ini 
          #/etc/php/7.2/fpm/pool.d/www.conf change the following lines
          sudo sed -i "s/listen = \/run\/php\/php7.2-fpm.sock/listen = 127.0.0.1:9000/" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "s/;listen.backlog = 511/listen.backlog = -1/" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "s/;listen.mode = 0660/listen.mode = 0666/" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "s/;listen.allowed_clients = 127.0.0.1/listen.allowed_clients = 127.0.0.1/" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "s/pm.max_children = 5/pm.max_children = 300/" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "s/pm.start_servers = 2/pm.start_servers = 130/" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "s/pm.min_spare_servers = 1/pm.min_spare_servers = 60/" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "s/pm.max_spare_servers = 3/pm.max_spare_servers = 300/" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "s/;pm.max_requests = 500/pm.max_requests = 1000/" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "s/;request_terminate_timeout = 0/request_terminate_timeout = 1800s/" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "s/;rlimit_files = 1024/rlimit_files = 300000/" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "s/;rlimit_core = 0/rlimit_core = unlimited/" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "367 i chdir = /" /etc/php/7.2/fpm/pool.d/www.conf
          sudo sed -i "s/;catch_workers_output = yes/catch_workers_output = yes/" /etc/php/7.2/fpm/pool.d/www.conf
