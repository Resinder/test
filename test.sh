#!/data/data/com.termux/files/usr/bin/bash

#Colour section
red='\033[1;31m'
rset='\033[0m'
grn='\033[1;32m'
ylo='\033[1;33m'

## Checking internet status
clear
wget -q --spider https://www.google.com
if [ "$?" -eq 0 ]; then
echo -e "$ylo" "          INSTALLING METASPLOIT...."
else
echo -e "$red" "     PLEASE TURN ON YOUR INTERNET..."
exit
fi

echo '
           ╭━╮╭━╮╱╱╭╮╱╱╱╱╱╱╱╱╱╭╮╱╱╱╱╭╮
           ┃┃╰╯┃┃╱╭╯╰╮╱╱╱╱╱╱╱╱┃┃╱╱╱╭╯╰╮
           ┃╭╮╭╮┣━┻╮╭╋━━┳━━┳━━┫┃╭━━╋╮╭╯
           ┃┃┃┃┃┃┃━┫┃┃╭╮┃━━┫╭╮┃┃┃╭╮┣┫┃
           ┃┃┃┃┃┃┃━┫╰┫╭╮┣━━┃╰╯┃╰┫╰╯┃┃╰╮
           ╰╯╰╯╰┻━━┻━┻╯╰┻━━┫╭━┻━┻━━┻┻━╯
           ╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱┃┃Resinder
           ╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╰╯version 2.1
'

sleep 6.0
rm -rf metasploit.sh

# TermuxBlack theme installation (Optional)
#wget https://github.com/Hax4us/TermuxBlack/raw/master/install.sh
#bash install.sh -i

# Remove old folder if exist 
find $HOME -name "metasploit-*" -type d -exec rm -rf {} \;
cwd=$(pwd)
msfvar=6.1.24
msfpath='/data/data/com.termux/files/home'
apt update && apt upgrade

# Temporary apps
apt remove ruby -y
apt install -y libiconv zlib autoconf bison clang coreutils curl findutils git apr apr-util libffi libgmp libpcap postgresql readline libsqlite openssl libtool libxml2 libxslt ncurses pkg-config wget make ruby2 libgrpc termux-tools ncurses-utils ncurses unzip zip tar termux-elf-cleaner

# Many phones are claiming libxml2 not found error
ln -sf $PREFIX/include/libxml2/libxml $PREFIX/include/

# Download and extract metasploit-framework 
cd $msfpath
curl -LO https://github.com/rapid7/metasploit-framework/archive/$msfvar.tar.gz
tar -xf $msfpath/$msfvar.tar.gz
mv $msfpath/metasploit-framework-$msfvar $msfpath/metasploit-framework
cd $msfpath/metasploit-framework

# Update rubygems-update
if [ "$(gem list -i rubygems-update 2>/dev/null)" = "false" ]; then
	gem install --no-document --verbose rubygems-update
fi

# Update rubygems
update_rubygems

# Install bundler
gem install --no-document --verbose bundler:1.17.3

# Installing all gems 
bundle config build.nokogiri --use-system-libraries
bundle install -j3
echo "Gems installed"

# Some fixes
sed -i "s@/etc/resolv.conf@$PREFIX/etc/resolv.conf@g" $msfpath/metasploit-framework/lib/net/dns/resolver.rb
find "$msfpath"/metasploit-framework -type f -executable -print0 | xargs -0 -r termux-fix-shebang
find "$PREFIX"/lib/ruby/gems -type f -iname \*.so -print0 | xargs -0 -r termux-elf-cleaner

# Creating DB for metasploit-framework 
echo "Creating database"
mkdir -p $msfpath/metasploit-framework/config && cd $msfpath/metasploit-framework/config
curl -LO https://raw.githubusercontent.com/resinder/test/master/database.yml
mkdir -p $PREFIX/var/lib/postgresql
pg_ctl -D "$PREFIX"/var/lib/postgresql stop > /dev/null 2>&1 || true

if ! pg_ctl -D "$PREFIX"/var/lib/postgresql start --silent; then
    initdb "$PREFIX"/var/lib/postgresql
    pg_ctl -D "$PREFIX"/var/lib/postgresql start --silent
fi
if [ -z "$(psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='msf'")" ]; then
    createuser msf
fi
if [ -z "$(psql -l | grep msf_database)" ]; then
    createdb msf_database
fi

rm $msfpath/$msfvar.tar.gz
cd ${PREFIX}/bin && curl -LO  https://raw.githubusercontent.com/resinder/test/master/msfconsole && chmod +x msfconsole
ln -sf $(which msfconsole) $PREFIX/bin/msfvenom

echo "You can directly use msfvenom or msfconsole rather than ./msfvenom or ./msfconsole."
