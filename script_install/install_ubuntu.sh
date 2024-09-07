# 1. Pré-Requisitos

##################################################################

# 1.1. Certifique-se de que o servidor Ubuntu 22.04 LTS esteja instalado.
# 1.2. É necessário ter acesso à internet para baixar e instalar os pacotes necessários.
# 1.3. Verifique se você tem privilégios de root ou sudo no servidor.

##################################################################

# 2. Instalação

##################################################################
# 2.1. Atualize o sistema e todos os pacotes instalados para a versão mais recente.
sudo apt update && sudo apt dist-upgrade -y

# 2.2. Configure o fuso horário do servidor. Isso garante que o horário correto será usado em logs e outras funções.
sudo dpkg-reconfigure tzdata

# 2.3. Reinicie o servidor para garantir que todas as atualizações e configurações sejam aplicadas corretamente.
sudo reboot

# 2.4. Instale o servidor web Apache, o banco de dados MariaDB, e todas as extensões PHP necessárias para o GLPI.
sudo apt install -y \
	apache2 \
	mariadb-server \
	mariadb-client \
	libapache2-mod-php \
	php-dom \
	php-fileinfo   \
	php-json \
	php-simplexml \
	php-xmlreader \
	php-xmlwriter \
	php-curl \
	php-gd \
	php-intl \
	php-mysqli   \
	php-bz2  \
	php-zip \
	php-exif \
	php-ldap  \
	php-opcache \
	php-mbstring

# 2.5. Crie o banco de dados necessário para o GLPI e configure as permissões de usuário.
sudo mysql -e "CREATE DATABASE glpi"
sudo mysql -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost' IDENTIFIED BY 'P4ssw0rd'"
sudo mysql -e "GRANT SELECT ON mysql.time_zone_name TO 'glpi'@'localhost'"
sudo mysql -e "FLUSH PRIVILEGES"

# 2.6. Carregue informações de timezones no MySQL para assegurar que os fusos horários estão corretamente configurados.
mysql_tzinfo_to_sql /usr/share/zoneinfo | sudo mysql -u root mysql

# 2.7. Desabilite o site padrão do Apache, liberando a configuração para o GLPI.
sudo a2dissite 000-default.conf

# 2.8. Configure o PHP para garantir que os cookies sejam acessíveis apenas via HTTP e defina o timezone correto no arquivo php.ini.
sudo sed -i 's/^session.cookie_httponly =/session.cookie_httponly = on/' /etc/php/8.1/apache2/php.ini && \
	sudo sed -i 's/^;date.timezone =/date.timezone = America\/Sao_Paulo/' /etc/php/8.1/apache2/php.ini

# NOTA: Se houver um erro, verifique a versão do PHP. Para localizar o arquivo php.ini, execute o comando abaixo:
sudo find /etc/php -type f -name "php.ini"

# 2.9. Crie um arquivo de configuração VirtualHost para o GLPI, especificando o nome do servidor e o diretório raiz do GLPI.
cat << EOF | sudo tee /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
	ServerName glpi.ninjapfsense.com.br
	DocumentRoot /var/www/glpi/public
	<Directory /var/www/glpi/public>
		Require all granted
		RewriteEngine On
		# Redirecione todas as requisições ao roteador GLPI, exceto se o arquivo solicitado existir.
		RewriteCond %{REQUEST_FILENAME} !-f
		RewriteRule ^(.*)$ index.php [QSA,L]
	</Directory>
</VirtualHost>
EOF

# 2.10. Habilite o novo VirtualHost que acabamos de criar para o GLPI.
sudo a2ensite glpi.conf

# 2.11. Ative o módulo de reescrita do Apache, necessário para o GLPI funcionar corretamente.
sudo a2enmod rewrite

# 2.12. Reinicie o serviço Apache para aplicar todas as alterações de configuração.
sudo systemctl restart apache2

# 2.13. Baixe a versão mais recente do GLPI diretamente do repositório oficial.
wget -q https://github.com/glpi-project/glpi/releases/download/10.0.7/glpi-10.0.7.tgz

# 2.14. Descompacte o arquivo baixado do GLPI.
tar -zxf glpi-*

# 2.15. Mova o diretório do GLPI para o diretório raiz do servidor web (htdocs).
sudo mv glpi /var/www/glpi

# 2.16. Ajuste as permissões do diretório GLPI para garantir que o servidor Apache possa ler e gravar os arquivos.
sudo chown -R www-data:www-data /var/www/glpi/

# 2.17. Finalize a instalação do GLPI via linha de comando, configurando o banco de dados e outras definições.
sudo php /var/www/glpi/bin/console db:install \
	--default-language=pt_BR \
	--db-host=localhost \
	--db-port=3306 \
	--db-name=glpi \
	--db-user=glpi \
	--db-password=P4ssw0rd

##################################################################

# 3. Ajustes de Segurança

##################################################################
# 3.1. Após a instalação, remova o arquivo de instalação para evitar que o GLPI seja reinstalado acidentalmente.
sudo rm /var/www/glpi/install/install.php

# 3.2. Movimente os diretórios sensíveis do GLPI para locais mais seguros e ajuste as permissões adequadas.
sudo mv /var/www/glpi/files /var/lib/glpi
sudo mv /var/www/glpi/config /etc/glpi
sudo mkdir /var/log/glpi && sudo chown -R www-data:www-data /var/log/glpi

# 3.3. Configure o GLPI para usar o novo caminho do diretório de configuração movido anteriormente.
cat << EOF | sudo tee /var/www/glpi/inc/downstream.php
<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
   require_once GLPI_CONFIG_DIR . '/local_define.php';
}
EOF

# 3.4. Configure o GLPI para usar o novo diretório de dados e de logs de forma segura.
cat << EOF | sudo tee /etc/glpi/local_define.php
<?php
define('GLPI_VAR_DIR', '/var/lib/glpi');
define('GLPI_LOG_DIR', '/var/log/glpi');
EOF

##################################################################

# 4. Primeiros Passos

##################################################################
# 4.1. Acesse a interface web do GLPI para finalizar a configuração através do navegador.
# 4.2. Crie um novo usuário com perfil de super-administrador.
# 4.3. Exclua os usuários padrão (glpi, normal, post-only, tech) por questões de segurança.
# 4.3.1. Envie os usuários excluídos para a lixeira.
# 4.3.2. Remova os usuários permanentemente da lixeira.
# 4.3.4. Defina a URL de acesso ao sistema na interface administrativa em: Configurar -> Geral -> Configuração Geral -> URL da aplicação.
##################################################################
